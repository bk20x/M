import std/[strformat, tables, streams, strutils]
import lispobject, reader

import builtins
import Std



type
  ReturnException* = ref object of CatchableError
    retVal*: LispObject

  Thunk* = object
    form: LispObject
    closure: Env


const SelfEvaluatingTypes = {Int, Float, String, BigInt, AlienObj, HashTable}
                            

proc intern*(env: var Env, sym: string, val: LispObject) =
  if sym in env.interned:
    echo fmt"WARNING: Redefining {sym} in the current scope"
  env.interned[sym] = val


func wrapModule*(module: Table[string, BuiltinFn]): Table[string, LispObject] =
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
    
var ## All used in `eval`, these are forward declared;; see implementations below `eval`
  lookupPlace: proc(env: var Env, form: LispObject): ptr LispObject
  ifImpl:      proc(env: var Env, form: LispObject): LispObject
  doTimes:     proc(env: var Env, form: LispObject): LispObject
  eachImpl:    proc(env: var Env, form: LispObject): LispObject
  evalLambda:  proc(env: var Env, form: LispObject, evaluated: seq[LispObject]): Thunk {.inline.}
  load:        proc(env: var Env, form: LispObject): LispObject
  qqExpand:    proc(env: var Env, form: LispObject): LispObject
  macroExpand: proc(env: var Env, form: LispObject, rawArgsList: LispObject): LispObject
  whileImpl:   proc(env: var Env, form: LispObject): LispObject

proc readAllSexprs(filename: string): seq[LispObject] =
  result = @[]
  var s = newFileStream(filename, fmRead)
  defer: close s
  if s == nil:
    raise newException(ValueError, "Could not open file: " & filename)
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
        result.add: parse buffer.strip()
        buffer = ""
    of ' ', '\n', '\t':
      if parenCount > 0:
        buffer.add(c)
    else:
      buffer.add(c)


proc eval*(env: var Env, initialForm: LispObject): LispObject {.discardable.} =
  var
    currentForm = initialForm
    currentEnv  = env
    tailcall: Thunk
  while true:
    # Self evaluating Objects
    if currentForm.kind in SelfEvaluatingTypes:
      return currentForm
    elif currentForm.isNil:
      return LispObject(kind: Nil)
    elif currentForm.kind == Symbol:
      return currentEnv.lookupValue(currentForm.sym.name)
    elif currentForm.kind == Cons:
      if currentForm.isNil:
        return LispObject(kind: Nil)
      # Special Forms
      if currentForm.car.kind == Symbol:
        case currentForm.car.sym.name:
        of "interned-symbols":
          result = lispobject.newTable()
          for k, v in currentEnv.interned:
            let key = newSym(k)
            result.table[key] = v
          return result
        of "->":
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
          let
            form   = currentForm.second
          if form.kind == Symbol:
            let
              form = currentEnv.eval(form)
            currentForm = form
            continue # eval result
          currentForm = form
          continue # eval form
        of "let":
          result = NIL()
          let
            bindings    = currentForm.second
            body        = currentForm.cdr.cdr
          var scope     = currentEnv.newScope()
          for binding in bindings.toSeq:
            let name    = binding.car.sym.name
            scope.interned[name] = currentEnv.eval(binding.second)
          for progn in body.toSeq:
            result      = scope.eval(progn)
          return result
        of "let*": 
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
          let
            file = currentForm.second
          return currentEnv.load file
        of "open":
          for m in currentForm.cdr.toSeq:
            let module = m.sym.name
            if currentEnv.loadedModules.hasKey module:
              let
                opened = wrapModule(currentEnv.loadedModules[module])
              for name, val in opened:
                currentEnv.intern(name, val)
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
          let
            name = currentForm.second
            val  = currentEnv.eval(currentForm.third)
          currentEnv.intern(name.sym.name, val)
          return name
        of "macro":
          let
            name      = currentForm.second
            params    = currentForm.third
            body      = currentForm.cdr.cdr.cdr.car
            macroForm = currentEnv.newMacro(params, body)
          currentEnv.intern(name.sym.name, macroForm)
          return name
        of "setf":
          let
            placeForm = currentForm.cdr.car
            valForm   = currentForm.cdr.cdr.car
          let
            val = currentEnv.eval(valForm)
            placeRef = currentEnv.lookupPlace(placeForm)
          if placeRef.isNil:
            raise newException(ValueError, "setf: place does not exist")
          placeRef[] = val
          return val
        of "setq":
          let
            placeForm = currentForm.cdr.car
            valForm   = currentForm.cdr.cdr.car        
          if placeForm.kind == Symbol:
            if not currentEnv.interned.hasKey(placeForm.sym.name):
              raise newException(ValueError, fmt"setq: unbound symbol {placeForm.sym.name}")
            currentEnv.interned[placeForm.sym.name] = valForm
          elif placeForm.kind == Cons:
            let
              formToAssign = placeForm.cdr.car
              place        = currentEnv.eval(formToAssign)
            if place.kind == Lambda:
              place.body   = valForm   
            else:
              var place    = currentEnv.lookupPlace(placeForm)
              place[]      = valForm
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
      let op = currentEnv.eval(currentForm.car)      
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
        tailcall    = currentEnv.evalLambda(op, evaluatedArgs)
        currentForm = tailcall.form
        currentEnv  = tailcall.closure
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
  


proc apply*(env: var Env, fun: LispObject, args: seq[LispObject]): LispObject =
  ## Eagerly evaluate a lambda object and get the return value instead of a Tc
  var 
    currentForm: LispObject
    currentEnv: Env
    tailcall: Thunk
  tailcall    = env.evalLambda(fun, args)
  currentForm = tailcall.form
  currentEnv  = tailcall.closure
  
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
      raise newException(ValueError, fmt"Can't eval object in `apply`;; scrutinee: {currentForm}")


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
    proc(env: var Env, form: LispObject, evaluated: seq[LispObject]): Thunk {.inline.} =
      var
        lambda = form
        params = lambda.params
        argIndex = 0
      while not params.isNil:
        if argIndex >= evaluated.len:
          raise newException(ValueError, "Wrong number of arguments for lambda")
        lambda.closure.interned[params.car.sym.name] = evaluated[argIndex]
        params = params.cdr
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
      let body = form.second
      while not (cond.isNil):
        cond = env.eval condForm
        if cond.isNil: break
        env.eval body
            

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
    let sexprs = readAllSexprs form.str
    for sexp in sexprs:
      env.eval sexp
    return T()

func registerModule*(env: var Env, name: string, module: Table[string, BuiltinFn]) =
  for k, v in module:
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
        let
          a = args.first
          b = args.second
        return if a.isT and b.isT: T() else: NIL()
        
    lparams: BuiltinFn =
      proc(args: LispObject): LispObject =
        if args.len != 1 or not (args.first.kind == Lambda):
          raise newException(ValueError, fmt"`lparams` is of type Lambda -> Cons but got {args}")
        let
          lambda = args.first
        return lambda.params
        

    toString: BuiltinFn =
      proc(args: LispObject): LispObject =
        if args.len != 1:
          raise newException(ValueError, fmt"`toString` is of type T -> String but got {args}")
        let obj = args.first
        return newStr($obj)
          
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
      
  result.loadedModules = Stdlib
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
    "strRepr"      : newBuiltin(toString,            "strRepr")
   }
  return result

