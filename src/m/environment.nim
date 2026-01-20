import std/[strformat, tables, streams, strutils, sugar]
import lispobject, reader

import builtins
import Stdlib/Std



type
  ReturnException* = ref object of CatchableError
    retVal*: LispObject

  Thunk* = object
    form: LispObject
    closure: Env


const SelfEvaluatingTypes = {Int, Float, String, BigInt, AlienObj, Nil} # HashTable is technichally self evaluating too, see in eval under check for SelfEvaluatingTypes
                            

proc intern*(env: var Env, sym: string, val: LispObject) =
  if sym in env.interned:
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

proc findForms(mass: string): seq[string] =
  result = @[]
  var s = newStringStream(mass)
  defer: close s
  var
    buffer = ""
    parenCount = 0
  while not s.atEnd:
    let c = s.readChar()
    case c:
    of '(':
      parenCount += 1
      buffer.add(c)
    of ')':
      parenCount -= 1
      buffer.add(c)
      if parenCount == 0:
        result.add: buffer.strip()
        buffer = ""
    of ' ', '\n', '\t':
      if parenCount > 0:
        buffer.add(c)
    else:
      buffer.add(c)


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
    elif currentForm.kind == FieldAccess:
      let targetTable = currentEnv.eval(currentForm.tableSym)
      if targetTable.kind != HashTable:
        raise newException(ValueError, fmt"Property access on non-table object: {targetTable.kind}")
      if not targetTable.table.hasKey(currentForm.field):
        return NIL()
      return targetTable.table[currentForm.field]
    elif currentForm.kind == StringIndex:
      let
        strObj   = if currentForm.strObj.kind   == String: currentForm.strObj   else: currentEnv.eval(currentForm.strObj)
        startIdx = if currentForm.startIdx.kind == Int:    currentForm.startIdx else: currentEnv.eval(currentForm.startIdx)
        endIdx   = if currentForm.endIdx.kind   == Int:    currentForm.endIdx   else: currentEnv.eval(currentForm.endIdx)
      if strObj.kind != String:
        raise newException(ValueError, fmt"Attempt to index non String object: {currentForm}")
      checkIndexIsInt(startIdx)
      checkIndexIsInt(endIdx)
      try:
        let str = strObj.str
        return newStr(str[startIdx.intVal..endIdx.intVal])
      except IndexDefect:
        raise newException(ValueError, fmt"Out of bounds string index! {currentForm}")
    elif currentForm.kind == Cons:
      if currentForm.car.kind == Symbol:
        case currentForm.car.sym.name:
        of "interned-symbols":
          result = lispobject.newTable()
          for k, v in currentEnv.interned:
            let key = newSym(k)
            result.table[key] = v
          return result
        of "safe":
          result = lispobject.newTable()
          if not currentForm.len == 2:
            raise newException(ValueError, fmt"`safe` expects 1 argument as the call but got {currentForm}")
          try:
            let callResult = currentEnv.eval(currentForm.second)
            result.table[newSym("success")] = T()
            result.table[newSym("value")]   = callResult
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
          let file = currentForm.second
          return currentEnv.load file
        of "open":
          if currentForm.cdr.isNil:
            raise newException(ValueError, fmt"open expects a Module or Modules but got {currentForm}")
          
          for m in currentForm.cdr.toSeq:
            let module = m.sym.name
            var e = currentEnv
            var found = false 
            
            while e != nil:
              if e.loadedModules.hasKey(module):
                let opened = wrapModule(e.loadedModules[module])
                for name, val in opened:
                  currentEnv.intern(name, val)
                found = true
                break 
              else:
                e = e.parent
            if not found:
              raise newException(ValueError, fmt"Module not found: {module}")
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
          elif placeForm.kind == StringIndex:
            let
              strObj   = currentEnv.eval(placeForm.strObj)
              startIdx = currentEnv.eval(placeForm.startIdx)
              endIdx   = currentEnv.eval(placeForm.endIdx)
            checkIndexIsInt(startIdx)
            checkIndexIsInt(endIdx)
            if strObj.kind != String:
              raise newException(ValueError, fmt"invalid String index {placeForm}")
            try:
              strObj.str[startIdx.intVal..endIdx.intVal] = valForm.image
              return strObj
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
            raise newException(ValueError, fmt"Malformed setf: {currentForm}")
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
          of StringIndex:
            let
              strObj   = currentEnv.eval(placeForm.strObj)
              startIdx = currentEnv.eval(placeForm.startIdx)
              endIdx   = currentEnv.eval(placeForm.endIdx)
            checkIndexIsInt(startIdx)
            checkIndexIsInt(endIdx)
            if strObj.kind != String:
              raise newException(ValueError, fmt"Invalid String index {placeForm}")
            try:
              strObj.str[startIdx.intVal..endIdx.intVal] = valForm.image
              return strObj
            except IndexDefect:
              raise newException(ValueError, fmt"Attempt to set out of bounds index! {placeForm}")
          else:
            raise newException(ValueError, fmt"setq: invalid place form {placeForm}")
          return valForm
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
      if currentForm.car.kind == FieldAccess:
        op = currentEnv.eval(currentForm.car)
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
    let name = params.first.sym.name
    scope.intern(name, args.first) 
    params = params.safeCdr
    args   = args.safeCdr
  result = scope.eval(macroObj.body)
  


proc compileFile(filename: string): seq[LispObject] =
  ## Helper for `load`
  result = @[]
  let code = readFile(filename)
  for form in findForms(code):
    result.add parse form
    
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
    if currentForm.isAtom:
      return currentForm
    var
      resultHead = NIL()
      resultTail = NIL()
      current    = currentForm
    let head = currentForm.first
    if head.isSymbol and head.sym.name == "unquote":
      return env.eval(current.second) 

    while not current.isNil:
      let item = current.first
      
      if not item.isAtom and item.first.isSymbol and item.first.sym.name == "unquote-splicing":
        let splicedList = env.eval(item.second)  
        if splicedList.isAtom and not splicedList.isNil:
           raise newException(ValueError, "Unquote-splicing result must be a list.")
        if resultHead.isNil:
          resultHead = splicedList
          resultTail = splicedList
        else:
          resultTail.cdr = splicedList
          
        while not resultTail.isNil and resultTail.kind == Cons and not resultTail.safeCdr.isNil:
          resultTail = resultTail.safeCdr
        current = current.safeCdr.safeCdr
      else:
        let
          expanded = env.expandRec(item)
          newForm  = cons(expanded, NIL()) 

        if resultHead.isNil:
          resultHead = newForm
          resultTail = newForm
        else:
          resultTail.cdr = newForm
          resultTail     = newForm
        current = current.safeCdr
        
    return resultHead
  return env.expandRec(form)






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
      let
        listForm = form.cdr.car
        listVal = env.eval: listForm
      if listVal.kind == Cons:
        return addr listVal.car
    else:
      return addr form
  else:
    raise newException(ValueError, "Invalid place: " & $form.kind)


evalLambda =
    proc(env: var Env, form: LispObject, evaluated: seq[LispObject]): Thunk =
      var
        lambda = form.closure.newLambda(form.params, form.body)
        argIndex = 0
      while not lambda.params.isNil:
        if argIndex >= evaluated.len:
          raise newException(ValueError, "Wrong number of arguments for lambda")
        lambda.closure.interned[lambda.params.car.sym.name] = evaluated[argIndex]
        lambda.params = lambda.params.cdr
        inc argIndex
      if argIndex != evaluated.len:
        raise newException(ValueError, "Wrong number of arguments for lambda")
      result = Thunk(form: lambda.body, closure: lambda.closure)
      
ifImpl =
    proc(env: var Env, form: LispObject): LispObject =
      let
        cond   = env.eval(form.first)
        ifCond = form.second
      var elt: LispObject
      if not cond.isNil:
         return env.eval(ifCond)
      else:
         if form.len == 3:
           new elt
           elt = form.third
           if not elt.isNil:
             return env.eval(elt)
         else:
           return NIL()

doTimes =
    proc(env: var Env, form: LispObject): LispObject =
      let
        times = env.eval form.first
        body  = form.second
      var i = 0
      while not (i == times.intVal - 1): # bc we return the last eval
        env.eval: body
        i += 1
      return env.eval: body
        
whileImpl =
    proc(env: var Env, form: LispObject): LispObject =
      result = NIL()
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
    let
      varAndList = form.first # (var list)
      body       = form.second # (body)
      varSym     = varAndList.car
      listForm   = varAndList.cdr.car

    let evaluatedList = env.eval(listForm)
    if evaluatedList.kind != Cons and not evaluatedList.isNil:
      raise newException(ValueError, fmt"expected list for `doList` but got {$evaluatedList.kind}")

    var listToIter = evaluatedList

    while not listToIter.isNil:
      var newEnv = env.newScope()
      newEnv.interned[varSym.sym.name] = listToIter.car
      discard newEnv.eval(body)
      listToIter = listToIter.cdr

    return NIL()


load =
  proc(env: var Env, form: LispObject): LispObject =
    let forms = compileFile(form.str)
    for form in forms:
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
        if args.len != 2 or not (args.first.kind == Cons and args.second.kind in {Lambda, Builtin}):
          raise newException(ValueError, fmt"`map` is of type Cons -> Lambda | Builtin -> Cons but got {args}")
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
        for i in countdown(list.high, 0):
          let
            new = env.apply(fun, @[list[i]])
          result = cons(new, result)
        return result
          
    filter: BuiltinFn =
      proc(args: LispObject): LispObject =
        if args.len != 2 or not (args.first.kind == Cons and args.second.kind in {Lambda, Builtin}):
          raise newException(ValueError, fmt"`filter` is of type Cons -> Lambda | Builtin -> Cons but got {args}")
        let
          list = args.first.toSeq
          fun  = args.second
        result = NIL()
        if fun.kind == Builtin:
          for i in countdown(list.high, 0):
            let
              new = fun.fun(cons(list[i], NIL()))
            if new.isT:
              result = cons(list[i], result)
          return result
        for i in countdown(list.high, 0):
          let
            new = env.apply(fun, @[list[i]])
          if new.isT:
            result = cons(list[i], result)
        return result
        
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
        result = NIL()
        let
          lambda = args.first
          body   = lambda.body
        return body

    setb: BuiltinFn =
      proc(args: LispObject): LispObject =
        result = NIL()
        let
          lambda = args.first
          new    = args.second
        lambda.body = new
        
    setp: BuiltinFn =
      proc(args: LispObject): LispObject =
        result = NIL()
        let
          lambda = args.first
          new    = args.second
        lambda.params = new
      
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
        of Symbol:
          return newSym(obj.sym.name)
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
        result = NIL()
        let sym  = args.first
        if not (sym.kind == Symbol):
          raise newException(ValueError, fmt"`unintern` is of type Symbol -> T | () but got {args}")
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

    findFormz: BuiltinFn =
      proc(args: LispObject): LispObject =
        result = NIL()
        if args.len != 1 or not (args.first.kind == String):
          raise newException(ValueError, fmt"~findForms is of type String -> String list but got {args}")
        let forms = findForms(args.first.str)
        for i in countdown(forms.high, 0):
          result = lispobject.cons(newStr(forms[i]), result)
          
    ftoi: BuiltinFn =
      proc(args: LispObject): LispObject =
        if args.first.kind != Float or args.len != 1:
          raise newException(ValueError, fmt"ftoi is of type Float -> Int but got {args}")
        return newInt(args.first.floatVal.int)
          
        
  result.loadedModules = tables.newTable[string, Table[string, BuiltinFn]]()        
  for k, v in Stdlib:
    result.loadedModules[k] = v
  result.interned = toTable {
    "t"            : T(),
    "+"            : newBuiltin(lispadd,             "+"),
    "-"            : newBuiltin(lispSub,             "-"),
    "*"            : newBuiltin(lispMultiply,        "*"),
    "/"            : newBuiltin(lispDiv,             "/"),
    "mod"          : newBuiltin(lispMod,             "mod"),
    ">"            : newBuiltin(lispGreaterThan,     ">"),
    ">="           : newBuiltin(lispGreaterThanEq,   ">="),
    "="            : newBuiltin(lispEquals,          "="),
    "<"            : newBuiltin(lispLessThan,        "<"),
    "<="           : newBuiltin(lispLessThanEq,      "<="),
    "!="           : newBuiltin(lispUneql,           "!="),
    "Float->Int"   : newBuiltin(ftoi,                "Float->Int"),
    "append"       : newBuiltin(append,              "append"),
    "map"          : newBuiltin(map,                 "map"),
    "filter"       : newBuiltin(filter,              "filter"),
    "list"         : newBuiltin(listt,                "list"),
    "cons"         : newBuiltin(cons,                "cons"),
    "car"          : newBuiltin(car,                 "car"),
    "cdr"          : newBuiltin(cdr,                 "cdr"),
    "first"        : newBuiltin(first,               "first"),
    "second"       : newBuiltin(second,              "second"),
    "unintern"     : newBuiltin(unintern,            "unintern"),
    "and"          : newBuiltin(nd,                  "and"),
    "echo"         : newBuiltin(lecho,               "echo"),
    "body"         : newBuiltin(body,                "body"),
    "lparams"      : newBuiltin(lparams,             "lparams"),
    "typeOf"       : newBuiltin(typeOf,              "typeOf"),
    "clone"        : newBuiltin(clone,               "clone"),
    "setb"         : newBuiltin(setb,                "setb"),
    "setp"         : newBuiltin(setp,                "setp"),
    "image"        : newBuiltin(toString,            "image"),
    "~read"        : newBuiltin(read,                "~read"),
    "~findForms"   : newBuiltin(findFormz,           "~findForms")

   }
  return result

