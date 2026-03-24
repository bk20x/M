import std/[strformat, tables, sugar]
import lispobject, reader

import builtins
import Stdlib/Std



type
  ReturnException = ref object of CatchableError
    retVal: LispObject
    
  LispException* = ref object of CatchableError
    errMsgOrObject*: LispObject
    
  Thunk = object
    form: LispObject
    closure: Env

  
    
const SelfEvaluatingTypes = {Int, Float, String, Char, BigInt, AlienObj, Nil} # HashTable is technichally self evaluating too, see in eval under check for SelfEvaluatingTypes
                            
var interactive*: bool = false # if in the REPL
proc intern*(env: var Env, sym: string, val: LispObject) =
  if interactive and sym in env.interned:
    echo fmt"WARNING: Redefining {sym} in the current scope"
  env.interned[sym] = val


proc wrapModule*(module: Table[string, BuiltinFn]): Table[string, LispObject] =
  result = initTable[string, LispObject]()
  for k, v in module:
    result[k] = newBuiltin(v, k)

func lookupValue(env: var Env, symbolName: string): LispObject =
  var currentEnv = env
  while currentEnv != nil:
    if currentEnv.interned.hasKey(symbolName):
      return currentEnv.interned[symbolName]
    currentEnv = currentEnv.parent
  raise newException(ValueError, fmt"Unbound symbol: {symbolName}")

func safeCdr(obj: LispObject): LispObject =
  if obj.kind == Cons:
    return obj.cdr
  else:
    return NIL()


func getTop(env: Env): Env =
  var e = env
  while e.parent != nil:
    e = e.parent
  return e
  
var ## All used in `eval`, these are forward declared because they call `eval`;; see implementations below `eval`
  lookupPlace: (var Env, LispObject) -> ptr LispObject
  ifImpl:      (var Env, LispObject) -> LispObject
  doTimes:     (var Env, LispObject) -> LispObject
  eachImpl:    (var Env, LispObject) -> LispObject
  load:        (var Env, LispObject) -> LispObject
  qqExpand:    (var Env, LispObject) -> LispObject
  whileImpl:   (var Env, LispObject) -> LispObject 
  macroExpand: (var Env, LispObject,  LispObject) -> LispObject
  evalLambda:  (var Env, LispObject, seq[LispObject]) -> Thunk 



proc checkIndexIsInt(obj: LispObject) {.inline.} = 
  if obj.kind != Int:
    raise newException(ValueError, fmt"Attempt to use non Integer object as index {obj}")    


template image(obj: LispObject): string =
  if obj.kind == String:
    obj.str
  else:
    $(obj)

    
proc eval*(env: var Env; initialForm: LispObject): LispObject {.discardable.} =
  var
    currentForm = initialForm
    currentEnv  = env
    currentThunk: Thunk
  while true:
    # Self evaluating Objects
    if currentForm.kind in SelfEvaluatingTypes:
      return currentForm        
    elif currentForm.kind == Symbol:
      return currentEnv.lookupValue(currentForm.sym.name)
    elif currentForm.kind == HashTable:
      if currentForm.literal:
        var table = currentForm.table
        for k, v in table:
          table[k] = currentEnv.eval(v)
        result = lispobject.newTable()
        result.table = table
        return result
      return currentForm
    elif currentForm.kind == Seq:
      if currentForm.literalSeq:
        result = lispobject.newSeq()
        for idx, x in currentForm.sequence:
          result.sequence.add(currentEnv.eval(x))
        return result
      return currentForm
    elif currentForm.kind == FieldAccess:
      let targetTable = currentEnv.eval(currentForm.tableSym) 
      if targetTable.kind != HashTable:
        raise newException(ValueError, fmt"Property access on non-table object: {targetTable} of {targetTable.kind}")
      let fieldSym = currentForm.field 
      if targetTable.table.hasKey(fieldSym):
        return targetTable.table[fieldSym]
      let fieldAsString = newStr(fieldSym.sym.name)
      if targetTable.table.hasKey(fieldAsString):
        return targetTable.table[fieldAsString]
      return NIL()
    elif currentForm.kind == Index:
      try:
        let
          obj      = currentEnv.eval(currentForm.obj)
          startIdx = if currentForm.startIdx.kind == Int: currentForm.startIdx 
                       else: currentEnv.eval(currentForm.startIdx)
          endIdx   = if currentForm.endIdx.kind == Int: currentForm.endIdx 
                       else: currentEnv.eval(currentForm.endIdx)        
        checkIndexIsInt(startIdx)
        checkIndexIsInt(endIdx)
        case obj.kind
        of String:
          return newStr(obj.str[startIdx.intVal..endIdx.intVal])
        of Seq:
          if startIdx.intVal != endIdx.intVal:
            result = lispobject.newSeq()
            result.sequence = obj.sequence[startIdx.intVal..endIdx.intVal]
          else:
            result = obj.sequence[startIdx.intVal]
          return result
        else:
          raise newException(ValueError, fmt"Invalid object for index! {obj} of type {obj.kind}")
      except IndexDefect:
        raise newException(ValueError, fmt"Out of bounds index! {currentForm}")
    elif currentForm.kind == Cons:
      if currentForm.car.kind == Symbol:
        case currentForm.car.sym.name: # Check if the op is a special form
        of "die":
          if currentForm.len >= 2:
            quit(currentForm.second.image)
          else:
            quit()
        of "interned-symbols":
          result = lispobject.newTable()
          for k, v in currentEnv.interned:
            let key = newSym(k)
            result.table[key] = v
          return result
        of "failwith":
          result = NIL()
          if currentForm.len != 2:
            raise newException(ValueError, fmt"`failwith` requires 1 argument as error object but got {currentForm}")
          raise LispException(errMsgOrObject: currentEnv.eval(currentForm.second))
        of "safe":
          result = lispobject.newTable()
          try:
            let callResult = currentEnv.eval(currentForm.second)
            result.table[newSym("success")] = T()
            result.table[newSym("value")]   = callResult
            return result
          except LispException as e:
            result.table[newSym("success")] = NIL()
            result.table[newSym("value")]   = e.errMsgOrObject
            return result
          except CatchableError as e:
            result.table[newSym("success")] = NIL()
            result.table[newSym("value")]   = newStr(e.msg)
            return result   
        of "who":
          let
            obj = currentForm.second
            place = currentEnv.lookupPlace(obj)
          return newStr(fmt"{cast[int](place):#x}")
        of "->":
          if not (currentForm.len == 3):
            raise newException(ValueError, fmt"Malformed lambda literal: {currentForm}")
          let
            params = currentForm.second
            body   = currentForm.third
          let lambda = currentEnv.newLambda(params, body)          
          return lambda
        of "quote":
          let quoted = currentForm.second
          return quoted
        of "backquote":
          return env.qqExpand(currentForm.second)
        of "eval":
          let form = currentEnv.eval(currentForm.second)
          currentForm = form
          continue
        # (let (bindings) ...forms)
        of "let":
          if not (currentForm.len >= 3):
            raise newException(ValueError, fmt"Malformed let binding: {currentForm}")
          result = NIL()
          let
            bindings    = currentForm.second
            body        = currentForm.cdr.cdr # The rest since let has implicit progn
          var scope     = currentEnv.newScope()
          for binding in bindings.toSeq:
            let name    = binding.car.sym.name
            scope.interned[name] = currentEnv.eval(binding.second)
          for progn in body.toSeq:
            result      = scope.eval(progn)
          return result
        of "let*":
          if not (currentForm.len >= 3):
            raise newException(ValueError, fmt"Malformed let binding: {currentForm}")
          result = NIL()
          let
            bindings    = currentForm.second
            body        = currentForm.cdr.cdr        
          var scope = currentEnv.newScope()
          for binding in bindings.toSeq:
            let
              name  = binding.car.sym.name
              value = scope.eval(binding.second) 
            scope.interned[name] = value
          for progn in body.toSeq:
            result = scope.eval(progn)
          return result
        of "load":
          if currentForm.cdr.isNil:
            raise newException(ValueError, "load expects a String for filename")
          var file = currentForm.second
          if file.kind != String:
            file = currentEnv.eval(file)
            if file.kind != String:
              raise newException(ValueError, fmt"load expects a String for filename but got {file}")
          return currentEnv.load file
        of "open":
          if currentForm.cdr.isNil:
            raise newException(ValueError, fmt"open expects a Module or Modules but got {currentForm}")
          for m in currentForm.cdr.toSeq:
            if m.kind == Symbol:
              let
                module  = m.sym.name
                modules = currentEnv.getTop().loadedModules
              if not modules.hasKey(module):
                raise newException(ValueError, fmt"Unbound Module {module}")
              block:
                let module = wrapModule(modules[module])
                for sym, val in module:
                  currentEnv.intern(sym, val)
          return T()
        of "return":
            try:
              let
                valForm = currentForm.cdr.car
                val     = currentEnv.eval(valForm)
              raise ReturnException(retVal: val)
            except ReturnException as r:
              return r.retVal
        of "if":
          # (if (cond) (then) (else))
          if not (currentForm.len in {3, 4}):
            raise newException(ValueError, fmt"Malformed if expression: {currentForm}")
          let cond = currentEnv.eval(currentForm.second)
          if not cond.isNil:
            currentForm = currentForm.third 
          else:
            let elseBranch = currentForm.cdr.cdr.cdr
            if not elseBranch.isNil:
              currentForm = elseBranch.car 
            else:
              return NIL() 
          continue 
        of "define":
          # (define name val)
          if (currentForm.len != 3) or (currentForm.second.kind != Symbol):
            raise newException(ValueError, fmt"Malformed define: {currentForm}")
          let
            name = currentForm.second
            val  = currentEnv.eval(currentForm.third)
          currentEnv.intern(name.sym.name, val)
          return name
        of "macro":     
          if (currentForm.len != 4) or (currentForm.third.kind notin {Cons, Nil}): # params
            raise newException(ValueError, fmt"Malformed macrodef: {currentForm}")
          let
            name      = currentForm.second
            params    = currentForm.third
            body      = currentForm.cdr.cdr.cdr.car
            macroForm = currentEnv.newMacro(params, body)
          currentEnv.intern(name.sym.name, macroForm)
          return name
        of "setf":
          if not (currentForm.len == 3):
            raise newException(ValueError, fmt"Malformed setf: {currentForm}")
          let
            placeForm = currentForm.cdr.car
            valForm   = currentForm.cdr.cdr.car
          # For setting table fields with dot access like (setf pos.x 56.0)
          if placeForm.kind == FieldAccess: 
            let
              table = currentEnv.eval(placeForm.tableSym)
              key   = placeForm.field
              val   = currentEnv.eval(valForm)
            table.table[key] = val
            return val
          elif placeForm.kind == Index:
            let
              obj      = currentEnv.eval(placeForm.obj)
              startIdx = currentEnv.eval(placeForm.startIdx)
              endIdx   = currentEnv.eval(placeForm.endIdx)
              valForm  = currentEnv.eval(valForm)
            checkIndexIsInt(startIdx)
            checkIndexIsInt(endIdx)
            try:
              case obj.kind
              of String:
                if valForm.kind != String:
                  raise newException(ValueError, fmt"Attempt to setf String index {placeForm} to non String object {valForm}")
                obj.str[startIdx.intVal..endIdx.intVal] = valForm.str
              of Seq:
                if startIdx.intVal == endIdx.intVal:
                  obj.sequence[startIdx.intVal] = valForm
                else:
                  if valForm.kind == Seq:
                    obj.sequence[startIdx.intVal..endIdx.intVal] = valForm.sequence
                  else:
                    raise newException(ValueError, fmt"Attempt to setf Seq range {placeForm} to non Seq object {valForm}")
              else:
                raise newException(ValueError, fmt"Invalid type for index {placeForm.kind} as {placeForm}")
              return valForm
            except IndexDefect:
              raise newException(ValueError, fmt"Attempt to setf out of bounds index! {placeForm}")
          else:
            let
              val       = currentEnv.eval(valForm)
              placeRef  = currentEnv.lookupPlace(placeForm)
            if placeRef.isNil:
              raise newException(ValueError, fmt"setf: place does not exist {placeForm}")
            placeRef[]  = val
            return val
        of "setq":
          if not (currentForm.len == 3):
            raise newException(ValueError, fmt"Malformed setq: {currentForm}")
          let
            placeForm = currentForm.cdr.car
            valForm   = currentForm.cdr.cdr.car        
          case placeForm.kind
          of Symbol:
            let place = currentEnv.lookupPlace(placeForm)
            if place.isNil:
              raise newException(ValueError, fmt"setq: place does not exist {placeForm}")
            place[] = valForm
            return valForm
          of Cons:
            var place    = currentEnv.lookupPlace(placeForm)
            if place.isNil:
              raise newException(ValueError, fmt"setq: place does not exist {placeForm}")
            place[]      = valForm
            return valForm
          of FieldAccess:
            var table = currentEnv.eval(placeForm.tableSym)
            let key   = placeForm.field
            table.table[key] = valForm
          of Index:
            let
              obj      = currentEnv.eval(placeForm.obj)
              startIdx = currentEnv.eval(placeForm.startIdx)
              endIdx   = currentEnv.eval(placeForm.endIdx)
            checkIndexIsInt(startIdx)
            checkIndexIsInt(endIdx)
            try:
              case obj.kind
              of String:
                if valForm.kind != String:
                  raise newException(ValueError, fmt"Attempt to setq String index {placeForm} to non String object {valForm}")
                obj.str[startIdx.intVal..endIdx.intVal] = valForm.str          
              of Seq:
                if startIdx.intVal == endIdx.intVal:
                  obj.sequence[startIdx.intVal] = valForm
                else:
                  if valForm.kind == Seq:
                    obj.sequence[startIdx.intVal..endIdx.intVal] = valForm.sequence
                  else:
                    raise newException(ValueError, fmt"Attempt to setq Seq range {placeForm} to non Seq object {valForm}")
              else:
                raise newException(ValueError, fmt"Invalid type for index {placeForm.kind} as {placeForm}")
              return valForm
            except IndexDefect:
              raise newException(ValueError, fmt"Attempt to setq out of bounds index! {placeForm}")
          else:
            raise newException(ValueError, fmt"setq: invalid place {placeForm}")
          return valForm
        of "macroexpand":
          if currentForm.len != 2 or not (currentForm.second.kind == Cons):
            raise newException(ValueError, fmt"Invalid argument for macroexpand; macroexpand expects a call like so (someMacro someArgs)")
          let
            call       = currentForm.second
            maybeMacro = currentEnv.eval(call.car)
          if maybeMacro.kind != Macro:
            raise newException(ValueError, fmt"macroexpand expects a call to a Macro but got {maybeMacro}!")
          return currentEnv.macroExpand(maybeMacro, call.cdr)
        of "doTimes":
          return currentEnv.doTimes(currentForm.cdr)
        of "each":
          return currentEnv.eachImpl(currentForm.cdr)
        of "while":
          return currentEnv.whileImpl(currentForm.cdr)
        else:
          discard
      # Non Special forms :: Lambdas | Builtins | Macros
      var op = currentEnv.eval(currentForm.car)
      if op.kind == Builtin:  
        var
          evaluatedArgs: seq[LispObject]
          args = currentForm.cdr
        while not args.isNil:
          evaluatedArgs.add: currentEnv.eval(args.car)
          args = args.cdr 
        let consArgs = evaluatedArgs.list
        return op.fun(consArgs)
      elif op.kind == Lambda:
        var
          evaluatedArgs: seq[LispObject]
          args = currentForm.cdr
        while not args.isNil:
          evaluatedArgs.add: currentEnv.eval(args.car)
          args = args.cdr      
        currentThunk = currentEnv.evalLambda(op, evaluatedArgs)
        currentForm  = currentThunk.form
        currentEnv   = currentThunk.closure
        continue 
      elif op.kind == Macro:
        let
          rawArgs     = currentForm.cdr # get the arguments unevaluated
          expanded    = currentEnv.macroExpand(op, rawArgs) # := the new AST
        currentForm   = expanded 
        continue 
      else:
        raise newException(ValueError, fmt"Can't apply non-function/macro object: {op} OF {$op.kind}")
    else:
      raise newException(ValueError,   fmt"Can't eval object: {currentForm} OF {$currentForm.kind}")

macroExpand = proc(env: var Env, macroObj: LispObject, rawArgsAst: LispObject): LispObject =
  var
    scope  = macroObj.closure.newScope() 
    params = macroObj.params
    args   = rawArgsAst    
  while not params.isNil and not args.isNil:
    let param = params.car
    case param.kind
    of Symbol:
      scope.intern(param.sym.name, args.first)
    of Seq:
      if param.len != 1 or not (param.sequence[0].kind == Symbol):
        raise newException(ValueError, fmt"As of now, there is only one binding for varargs... (macro (x [xs]) ...), got this: {param}")
      if not params.safeCdr.isNil:
        raise newException(ValueError, fmt"Vararg parameter must be the last in parameter list")
      scope.intern(param.sequence[0].sym.name, args)
      break
    else:
      raise newException(ValueError, fmt"Invalid type for parameter! {param} in {macroObj.params} from {macroObj}")     
    params = params.safeCdr
    args   = args.safeCdr
  result = scope.eval(macroObj.body)
  

    
proc apply*(env: var Env; fun: LispObject; args: seq[LispObject]): LispObject =
  ## Eagerly evaluate a lambda object and get the return value instead of a Thunk
  var 
    currentForm: LispObject
    currentEnv: Env
    th: Thunk
  th          = env.evalLambda(fun, args)
  currentForm = th.form
  currentEnv  = th.closure
  
  while true:
    if currentForm.kind in SelfEvaluatingTypes:
      return currentForm
    elif currentForm.isNil:
      return LispObject(kind: Nil)
    elif currentForm.kind == Symbol:
      return currentEnv.lookupValue(currentForm.sym.name)
    elif currentForm.kind == Cons:
      try:
        return currentEnv.eval(currentForm) 
      except ReturnException as ret:
        return ret.retVal
    else:
      return currentEnv.eval(currentForm)


qqExpand = proc(env: var Env, form: LispObject): LispObject =
  proc expandRec(env: var Env, currentForm: LispObject): LispObject =
    if currentForm.isNil or currentForm.kind != Cons:
      return currentForm
    
   
    if currentForm.car.kind == Symbol and currentForm.car.sym.name == "unquote":
      return env.eval(currentForm.second)
    
    var
      resultHead: LispObject = NIL()
      resultTail: LispObject = NIL()
      current    = currentForm

    while not current.isNil and current.kind == Cons:
      let item = current.car
      if item.kind == Cons and item.car.kind == Symbol and item.car.sym.name == "unquote-splicing":
        let splicedVal = env.eval(item.second)
        if not splicedVal.isNil:
          if splicedVal.kind != Cons:
            raise newException(ValueError, "unquote-splicing result must be a list.")
          var it = splicedVal
          while not it.isNil and it.kind == Cons:
            let newNode = cons(it.car, NIL())
            if resultHead.isNil: resultHead = newNode; resultTail = newNode
            else: resultTail.cdr = newNode; resultTail = newNode
            it = it.cdr            
      else:
        let expanded = expandRec(env, item)
        let newNode = cons(expanded, NIL())
        if resultHead.isNil:
          resultHead = newNode
          resultTail = newNode
        else:
          resultTail.cdr = newNode
          resultTail = newNode
      let next = current.cdr      
      if next.isNil:
        break 
      if next.kind != Cons:
        resultTail.cdr = next 
        break
      current = next 
    return resultHead
  return expandRec(env, form)






lookupPlace = proc(env: var Env, form: LispObject): ptr LispObject =
  if form.kind == Symbol:
    let symbolName = form.sym.name
    var currentEnv = env
    while currentEnv != nil:
      if currentEnv.interned.hasKey(symbolName):
          return addr currentEnv.interned[symbolName]
      currentEnv = currentEnv.parent
    raise newException(ValueError, fmt"Unbound symbol {symbolName} in lookupPlace")
  elif form.kind == Cons:
    let op = form.car
    if op.kind == Symbol:
      let opName = op.sym.name
      if form.cdr.isNil or form.cdr.kind != Cons:
        raise newException(ValueError, fmt"Malformed {opName} place")       
      let
        listForm = form.cdr.car
        target   = env.eval(listForm) 
      if target.isNil or target.kind != Cons:
        raise newException(ValueError, fmt"Cannot set {opName} of a non-cons object")
      if opName == "car":
        return addr target.car
      elif opName == "cdr":
        return addr target.cdr
      else:
        raise newException(ValueError, "Unsupported place accessor: " & opName)
    else:
      return addr form
  else:
    raise newException(ValueError, "Invalid place: " & $form & " " & $form.kind)

evalLambda =
    proc(env: var Env, form: LispObject, evaluated: seq[LispObject]): Thunk =
      var
        lambda = form.closure.newLambda(form.params, form.body)
        argIndex = 0
      while not lambda.params.isNil:
        if argIndex >= evaluated.len:
          raise newException(ValueError, "Wrong number of arguments for lambda")
        let param = lambda.params.car
        case param.kind
        of Symbol:
          lambda.closure.interned[param.sym.name] = evaluated[argIndex]
        of Seq:
          if param.len != 1 or not (param.sequence[0].kind == Symbol):
            raise newException(ValueError, fmt"As of now, there is only one binding for varargs... (-> (x [xs]) ...), got this: {param}")
          if not lambda.params.cdr.isNil:
            raise newException(ValueError, "Varargs parameter must be the last in parameter list")
          lambda.closure.interned[param.sequence[0].sym.name] = evaluated[argIndex..evaluated.high].list
          argIndex = evaluated.len # so it doesnt think some params are unbound
          break
        else:
          raise newException(ValueError, fmt"Invalid type for parameter! {param} in {form.params} from {form}")     
        lambda.params = lambda.params.cdr
        inc argIndex
      if argIndex != evaluated.len:
        raise newException(ValueError, "Wrong number of arguments for lambda")
      result = Thunk(form: lambda.body, closure: lambda.closure)
      
ifImpl =
    proc(env: var Env, form: LispObject): LispObject =
      let length = form.len
      if length notin {2,3}:
        raise newException(ValueError, fmt"Malformed arguments for if expression {form}")
      let
        cond   = env.eval(form.first)
        ifCond = form.second
      var elt: LispObject
      if not cond.isNil:
         return env.eval(ifCond)
      else:
         if length == 3:
           new elt
           elt = form.third
           if not elt.isNil:
             return env.eval(elt)
         else:
           return NIL()

doTimes =
    proc(env: var Env, form: LispObject): LispObject =
      if form.len != 2:
        raise newException(ValueError, fmt"`doTimes` expects 2 arguments, an Int and an expression but got {form}")
      let
        times = env.eval form.first
        body  = form.second
      if times.kind != Int:
        raise newException(ValueError, fmt"`doTimes` expected an Int for repetitions but got {times}")
      if times.intVal <= 0:
        return NIL()
      var i = 0
      while not (i == times.intVal): 
        result = env.eval: body
        i += 1
        
whileImpl =
    proc(env: var Env, form: LispObject): LispObject =
      result = NIL()
      if form.len != 2:
        raise newException(ValueError, fmt"`while` expects 2 arguments for its condition and a list of forms as its body but got {form}")
      var
        condForm = form.first
        cond     = env.eval condForm
        loopScope = env.newScope()
      let body      = form.second
      while not (cond.isNil):
        cond = loopScope.eval condForm
        if cond.isNil: break
        for form in body.toSeq: # Implicit progn
          result = loopScope.eval(form) # Now it returns the result when it finishes
          
            

eachImpl = proc(env: var Env, form: LispObject): LispObject =
    if form.len != 2 or not (form.first.kind == Cons and form.second.kind == Cons):
      raise newException(ValueError, fmt"malformed each: {form}")
    result = NIL()
    let
      binding    = form.first # (var list)
      body       = form.second # (body)
      bindingLen = binding.len
    if bindingLen notin {2, 3} or binding.first.kind != Symbol:
      raise newException(ValueError, fmt"malformed binding for each: {binding}")
    let useIdx = bindingLen == 3
    var
      varSym:   owned LispObject
      listForm: owned LispObject
      idxSym:   owned LispObject
    if useIdx:
      idxSym   = binding.first
      varSym   = binding.second
      listForm = binding.third
    else:
      varSym   = binding.first
      listForm = binding.second
      idxSym   = nil
    let evaluatedList = env.eval(listForm)
    if evaluatedList.kind notin {Cons, Seq} and not evaluatedList.isNil:
      raise newException(ValueError, fmt"expected Cons or Seq for `each` but got {evaluatedList}")
    var
      listToIter = evaluatedList
      loopScope  = env.newScope()
      idx: int
    case listToIter.kind
    of Cons:
      while not listToIter.isNil:
        if listToIter.kind == Cons:
          loopScope.interned[varSym.sym.name] = listToIter.car
          if useIdx:
            loopScope.interned[idxSym.sym.name] = newInt(idx)
          result = loopScope.eval(body)
          listToIter = listToIter.cdr
        else:  # for dotted pairs, this is when you hit the cdr of a dotted pair that is a non nil atom
          loopScope.interned[varSym.sym.name] = listToIter
          result = loopScope.eval(body)
          break # ^^
        inc idx
    of Seq:
      for x in listToIter.sequence:
        loopScope.interned[varSym.sym.name] = x
        if useIdx:
          loopScope.interned[idxSym.sym.name] = newInt(idx)
        result = loopScope.eval(body)
        inc idx
    else: # unreachable
      discard

load =
  proc(env: var Env, form: LispObject): LispObject =
    for form in forAllSexprs(form.str):
      env.eval form
    return T()
  

func registerModule*(env: var Env, name: string, module: Table[string, BuiltinFn]) =
  env.loadedModules[name] = module
      
proc newEnv*(): owned Env =
  new result
  var env = result
  let
    map: BuiltinFn =
      proc(args: LispObject): LispObject =
        if args.len != 2 or not (args.first.kind in {Cons, Seq} and args.second.kind in {Lambda, Builtin}):
          raise newException(ValueError, fmt"`map` is of type Cons | Seq -> Lambda | Builtin -> Cons | Seq but got {args}")
        if args.first.kind == Cons:
          let
            list = args.first.toSeq
            fun  = args.second
          result = NIL()
          if fun.kind == Builtin:
            for i in countdown(list.high, 0):
              let
                new = fun.fun(cons(list[i], NIL()))
              result = cons(new, result)
            return result
          else:
            for i in countdown(list.high, 0):
              let
                new = env.apply(fun, @[list[i]])
              result = cons(new, result)
            return result
        else:
          let
            list = args.first.sequence
            fun = args.second
          result = lispobject.newSeq()
          if fun.kind == Builtin:
            for x in list:
              result.sequence.add(fun.fun(cons(x, NIL())))
            return result
          else:
            for x in list:
              let new = env.apply(fun, @[x])
              result.sequence.add(new)
            return result
            
          
          
    filter: BuiltinFn =
      proc(args: LispObject): LispObject =
        if args.len != 2 or not (args.first.kind in {Cons, Seq} and args.second.kind in {Lambda, Builtin}):
          raise newException(ValueError, fmt"`filter` is of type Cons | Seq -> Lambda | Builtin -> Cons | Seq but got {args}")
        if args.first.kind == Cons:
          let
            list = args.first.toSeq
            fun  = args.second
          result = NIL()
          case fun.kind
          of Builtin:
            for i in countdown(list.high, 0):
              let
                new = fun.fun(cons(list[i], NIL()))
              if new.isT:
                result = cons(list[i], result)
            return result
          of Lambda:
            for i in countdown(list.high, 0):
              let
                new = env.apply(fun, @[list[i]])
              if new.isT:
                result = cons(list[i], result)
            return result
          else:
            discard
        else:
          let
            list = args.first.sequence
            fun  = args.second
          result = lispobject.newSeq()
          case fun.kind
          of Builtin:
            for x in list:
              let new = fun.fun(cons(x, NIL()))
              if new.isT:
                result.sequence.add(x)
            return result
          of Lambda:
            for x in list:
              let new = env.apply(fun, @[x])
              if new.isT:
                result.sequence.add(x)
            return result
          else: # unreachable
            discard
                
                
          
          
        
    cons: BuiltinFn =
      proc(args: LispObject): LispObject =
        if args.len != 2:
          raise newException(ValueError, fmt"`cons` is of type T | () -> T | () -> Cons but got {args}")
        return cons(args.first, args.second)
        
    car: BuiltinFn =
      proc(args: LispObject): LispObject =
        if args.len != 1:
          raise newException(ValueError, fmt"`car` is of type Cons -> T | () but got {args}")
        let cell = args.first
        return if cell.kind == Cons: cell.car else: NIL()
        
    cdr: BuiltinFn =
      proc(args: LispObject): LispObject =
        if args.len != 1:
          raise newException(ValueError, fmt"`cdr` is of type Cons -> T | () but got {args}")
        let cell = args.first
        return if cell.kind == Cons: cell.cdr else: NIL()
        
    listt: BuiltinFn =
      proc(args: LispObject): LispObject =
        return args


    lecho: BuiltinFn =
      proc(args: LispObject): LispObject =
        if args.len != 1:
          raise newException(ValueError, fmt"`echo` expects one argument of any type but got {args}")
        case args.car.kind:
        of String:
          echo args.car.str # because the printer prints string quoted
        else:
          echo args.car
        return NIL()
          
        
    typeOf: BuiltinFn =
      proc(args: LispObject): LispObject =
        if args.len != 1:
          raise newException(ValueError, fmt"`typeOf` is of type T -> Symbol but got {args}")
        if args.first.kind == AlienObj:
          return newSym(args.first.alien.tname)
        return newSym($args.first.kind)

          
    body: BuiltinFn =
      proc(args: LispObject): LispObject =
        if args.len != 1 or not (args.first.kind in {Lambda, Macro}):
          raise newException(ValueError, fmt"`body` is of type Lambda | Macro -> Cons but got {args}")
        result = NIL()
        let
          program = args.first
          body    = program.body
        return body

    setb: BuiltinFn =
      proc(args: LispObject): LispObject =
        if args.len != 2 or not (args.first.kind in {Lambda, Macro}):
          raise newException(ValueError, fmt"`setb` is of type Lambda | Macro -> T -> T but got {args}")
        let
          program = args.first
          new     = args.second
        result = new
        program.body = new
        
    setp: BuiltinFn =
      proc(args: LispObject): LispObject =
        if args.len != 2 or not (args.first.kind in {Lambda, Macro}):
          raise newException(ValueError, fmt"`setp` is of type Lambda | Macro -> T -> T but got {args}")
        let
          program = args.first
          new     = args.second
        result = new
        program.params = new
      
    clone: BuiltinFn =
      proc(args: LispObject): LispObject =
        if args.len != 1:
          raise newException(ValueError, fmt"`clone` is of type T -> T but got {args}")
        result = NIL()
        let obj = args.first
        case obj.kind:
        of HashTable:
          result = lispobject.newTable()
          result.table = obj.table
          return result
        of Int:
          result = newInt(obj.intVal)
          return result
        of Float:
          result = newFloat(obj.floatVal)
          return result
        of BigInt:
          result = newBigInt(0)
          result.bigNum = obj.bigNum
          return result
        of Lambda:
          let scope = Env(interned: obj.closure.interned)
          return newLambda(scope, obj.params, obj.body)
        of Macro:
          let scope = Env(interned: obj.closure.interned)
          return newMacro(scope, obj.params, obj.body)
        of String:
          return newStr(obj.str)
        of Char:
          return newChar(obj.charVal)
        of Symbol:
          return newSym(obj.sym.name)
        of Seq:
          result = lispobject.newSeq()
          result.sequence = obj.sequence
        of Cons:
          return lispobject.cons(obj.car, obj.cdr)
        else:
          return obj
          
    nd: BuiltinFn =
      proc(args: LispObject): LispObject =
        if args.len != 2:
          raise newException(ValueError, fmt"`and` takes 2 arguments of any type but got {args}")
        let
          a = args.first
          b = args.second
        return if a.isT and b.isT: T() else: NIL()
        
    lparams: BuiltinFn =
      proc(args: LispObject): LispObject =
        if args.len != 1 or not (args.first.kind == Lambda):
          raise newException(ValueError, fmt"`lparams` is of type Lambda -> Cons but got {args}")
        let lambda = args.first
        return lambda.params
        

    toString: BuiltinFn =
      proc(args: LispObject): LispObject =
        if args.len != 1:
          raise newException(ValueError, fmt"`image` is of type T -> String but got {args}")
        let obj = args.first
        return newStr(obj.image)
          
    unintern: BuiltinFn =
      proc(args: LispObject): LispObject =
        if args.len != 1 or not (args.first.kind == Symbol):
          raise newException(ValueError, fmt"`unintern` is of type Symbol -> T | Nil but got {args}")
        result = NIL()
        let sym  = args.first
        let name = sym.sym.name
        if env.interned.hasKey(name):
          env.interned.del(name)
          return T()

    read: BuiltinFn =
      proc(args: LispObject): LispObject =
        if args.len != 1 or not (args.first.kind == String):
          raise newException(ValueError, fmt"~read is of type String -> ? but got {args}")
        let form = args.first.str
        return parse form
          
    ftoi: BuiltinFn =
      proc(args: LispObject): LispObject =
        if args.len != 1 or args.first.kind != Float:
          raise newException(ValueError, fmt"ftoi is of type Float -> Int but got {args}")
        return newInt(args.first.floatVal.int)
          
    listToSeq: BuiltinFn =
      proc(args: LispObject): LispObject =
        if args.len != 1 or args.first.kind != Cons:
          raise newException(ValueError, fmt"`Cons->Seq` expects 1 argument of type Cons but got {args}")
        return lispobject.newSeq(args.first.toSeq)
    seqToList: BuiltinFn =
      proc(args: LispObject): LispObject =
        if args.len != 1 or args.first.kind != Seq:
          raise newException(ValueError, fmt"`Seq->Cons` expects 1 argument of type Seq but got {args}")
        return args.first.sequence.list()
        
  result.loadedModules = tables.newTable[string, Table[string, BuiltinFn]]()
  for k, v in Stdlib:
    result.loadedModules[k] = v
  let Core = toTable {
    "+"            : BuiltinFn lispadd,
    "-"            : BuiltinFn lispSub,
    "*"            : BuiltinFn lispMultiply,
    "/"            : BuiltinFn lispDiv,
    "mod"          : BuiltinFn lispMod,
    ">"            : BuiltinFn lispGreaterThan,
    ">="           : BuiltinFn lispGreaterThanEq,
    "="            : BuiltinFn lispEquals,
    "<"            : BuiltinFn lispLessThan,
    "<="           : BuiltinFn lispLessThanEq,
    "!="           : BuiltinFn lispUneql,
    "Float->Int"   : ftoi,
    "map"          : map,
    "filter"       : filter,
    "list"         : listt,
    "append"       : BuiltinFn append,
    "cons"         : cons,
    "car"          : car,
    "cdr"          : cdr,
    "unintern"     : unintern,
    "and"          : nd,
    "echo"         : lecho,
    "body"         : body,
    "lparams"      : lparams,
    "typeOf"       : typeOf,
    "clone"        : clone,
    "setb"         : setb,
    "setp"         : setp,
    "image"        : toString,
    "~read"        : read,
    "Cons->Seq"    : listToSeq,
    "Seq->Cons"    : seqToList,
    "chr"          : BuiltinFn chrr
   }
  result.loadedModules["Core"] = Core
  result.interned = wrapModule(Core)
  result.intern("t", T())
  return result

