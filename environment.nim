import std/[strformat, tables, streams, strutils]
import lispobject, reader

import builtins
import Std



type
  ReturnException* = ref object of CatchableError
    retVal*: LispObject
    

proc lookupRef*(env: Env, symName: string): ptr LispObject =
  if env.interned.hasKey(symName):
    return addr env.interned[symName]
  else:
    raise newException(ValueError, fmt"Unbound reference {symName}")
    
proc intern*(env: var Env, sym: string, val: LispObject) =
  if sym in env.interned:
    echo fmt"WARNING: Redefining {sym} in the current scope"
  env.interned[sym] = val


func wrapModule*(module: Table[string, BuiltinFn]): Table[string, LispObject] =
  result = initTable[string, LispObject]()
  for k, v in module:
    result[k] = newBuiltin(v, k)

  

proc lookupValue(env: var Env, symbolName: string): LispObject =
  var currentEnv = env
  while currentEnv != nil:
    if currentEnv.interned.hasKey(symbolName):
      return currentEnv.interned[symbolName]
    currentEnv = currentEnv.parent
  raise newException(ValueError, fmt"Unbound symbol: {symbolName}")


var ## All used in `eval`
  lookupPlace: proc(env: var Env, form: LispObject): ptr LispObject
  ifImpl:      proc(env: var Env, form: LispObject): LispObject
  letImpl:     proc(env: var Env, form: LispObject): LispObject
  doTimes:     proc(env: var Env, form: LispObject): LispObject
  doList:      proc(env: var Env, form: LispObject): LispObject
  evalLambda:  proc(env: var Env, form: LispObject, evaluated: seq[LispObject]): LispObject {.inline.}
  load:        proc(env: var Env, form: LispObject): LispObject


proc readAllSexprs(filename: string): seq[LispObject] =
  result = @[]
  var s = newFileStream(filename, fmRead)
  if s == nil:
    quit("Could not open file: " & filename)

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

  s.close()

proc eval*(env: var Env, form: LispObject): LispObject {.discardable.} =
  if form.isNil or form.kind in {Int, Float, String}:
    return form
  elif form.kind == Symbol:
    return env.lookupValue(form.sym.name)
  elif form.kind == Cons:
    if form.isNil:
      return NIL()

      
    if form.car.kind == Symbol:
      case form.car.sym.name: # special forms
      of "->":
        let
          params = form.second
          body   = form.third
          lambda = env.newLambda(params, body)
        return lambda
      of "quote":
        let quoted = form.cdr
        return quoted
      of "eval":
        let
          form   = form.second
        if form.kind == Symbol:
          let
            form = env.eval(form)
          return env.eval(form)
        return env.eval(form)
      of "let":
        let
          bindings    = form.second
          body        = form.cdr.cdr
        var scope     = env.newLambda(NIL(),body)
        scope.closure = env.newScope()
        
        for binding in bindings.toSeq:
          let name    = binding.car.sym.name
          scope.closure.interned[name] = env.eval binding.second
        for progn in body.toSeq:
          result      = scope.closure.eval progn
        return result
      of "load":
        let
          file = form.second
        return env.load file
      of "open":
        for m in form.cdr.toSeq:
          let module = m.sym.name
          if env.loadedModules.hasKey module:
            let
              opened = wrapModule(env.loadedModules[module])
            for name, val in opened:
              env.intern(name, val)
        return T()
      of "return":
         let
           valForm = form.cdr.car
           val     = env.eval: valForm
         raise ReturnException(retVal: val)
      of "if":
        # (if (cond) (expr) (elt))
        return env.ifImpl(form.cdr)
      of "define":
        # (defvar name val)
        let
          name = form.second
          val  = env.eval: form.third
        env.intern(name.sym.name, val)
        return name
      of "setf":
        let
          placeForm = form.cdr.car
          valForm   = form.cdr.cdr.car
        let
          val = env.eval: valForm
          placeRef = env.lookupPlace(placeForm)
        if placeRef.isNil:
          raise newException(ValueError, "setf: place does not exist")
        placeRef[] = val
        return val
      of "setq":
        let
          placeForm = form.cdr.car
          valForm   = form.cdr.cdr.car        
        if placeForm.kind == Symbol:
          if not env.interned.hasKey(placeForm.sym.name):
            raise newException(ValueError, fmt"setq: unbound symbol {placeForm.sym.name}")
          env.interned[placeForm.sym.name] = valForm
        elif placeForm.kind == Cons:
          let
            formToAssign = placeForm.cdr.car
            place        = env.eval(formToAssign)
          if place.kind == Lambda:
            place.body   = valForm   
          else:
            var place    = env.lookupPlace(placeForm)
            place[]      = valForm
        else:
          raise newException(ValueError, fmt"setq: invalid place form {placeForm}")
        return valForm
      of "doTimes":
        # (doTimes times (body))
        return env.doTimes(form.cdr)
      of "doList":
        # (doList (var list) (body))
        return env.doList(form.cdr)
      else:
        discard
        
    
    
    # eval all args first
    var
      evaluated: seq[LispObject] = @[]
      args = form.cdr
    while not args.isNil:
      evaluated.add: env.eval: args.car
      args = args.cdr # goto next Cons cell

            
    # eval the operator (functions might return another function)
    let op = env.eval: form.car
      
    # Built-in functions
    if op.kind == Builtin:  

      let consArgs = evaluated.list
      
      return op.fun(consArgs)      
    # User defined funs
    elif op.kind == Lambda:
      return env.evalLambda(op, evaluated)
    else:
      raise newException(ValueError, fmt"Can't apply non-function object: {op} OF {$op.kind}")
  else:
    raise newException(ValueError,   fmt"Can't eval object: {form} OF {$form.kind}")



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
    
    
    raise newException(ValueError, "Invalid  place: " & $form.kind)

  else:
    raise newException(ValueError, "Invalid place: " & $form.kind)


evalLambda =
    proc(env: var Env, form: LispObject, evaluated: seq[LispObject]): LispObject {.inline.} =
      var
        lambda = form
        params = lambda.params
        argIndex = 0
      lambda.closure = env.newScope()
      while not params.isNil:
        if argIndex >= evaluated.len:
          raise newException(ValueError, "Wrong number of arguments for lambda")
        lambda.closure.interned[params.car.sym.name] = evaluated[argIndex]
        params = params.cdr
        inc argIndex
      if argIndex != evaluated.len:
        raise newException(ValueError, "Wrong number of arguments for lambda")
      try:
        return lambda.closure.eval: lambda.body
      except ReturnException as ret:
        return ret.retVal
    
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
        times = form.first.intVal
        body  = form.second
      var i = 0
      while not (i == times - 1): # bc we return the last eval
        env.eval: body
        i += 1
      return env.eval: body 


doList = proc(env: var Env, form: LispObject): LispObject =
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

proc registerModule*(env: var Env, name: string, module: Table[string, BuiltinFn]) =
  for k, v in module:
    env.loadedModules[name] = module
  
    
proc newEnv*(): owned Env =
  new result
  var
    env = result
  let
    map: BuiltinFn =
      proc(args: LispObject): LispObject =
        let
          list = args.first.toSeq
          fun  = args.second
        result = NIL()
        for i in countdown(list.high, 0):
          let
            new = env.evalLambda(fun, @[list[i]])
          result = cons(new, result)
          
    filter: BuiltinFn =
      proc(args: LispObject): LispObject =
        let
          list = args.first.toSeq
          fun  = args.second
        result = NIL()
        for i in countdown(list.high, 0):
          let
            new = env.evalLambda(fun, @[list[i]])
          if new.isT:
            result = cons(list[i], result)
            
    cons: BuiltinFn =
      proc(args: LispObject): LispObject =
        return cons(args.first, args.second)
        
    car: BuiltinFn =
      proc(args: LispObject): LispObject =
        let cell = args.first
        return if cell.kind == Cons: cell.car else: NIL()
        
    cdr: BuiltinFn =
      proc(args: LispObject): LispObject =
        let cell = args.first
        return if cell.kind == Cons: cell.cdr else: NIL()
        
    list: BuiltinFn =
      proc(args: LispObject): LispObject =
        return args


    putLn: BuiltinFn =
      proc(args: LispObject): LispObject =
        case args.car.kind:
        of String:
          echo args.car.str # because the printer prints string quoted
        else:
          echo args.car
        return NIL()
          
        
    typeOf: BuiltinFn =
      proc(args: LispObject): LispObject =
        return newSym($args.first.kind)

    eq: BuiltinFn =
      proc(args: LispObject): LispObject =
        let
          x = args.first
          y = args.second
        case x.kind:
        of Int:
          if y.kind == Int    and x.intVal == y.intVal:
            return T()
          else:
            return NIL()
        of Float:
          if y.kind == Float  and x.floatVal == y.floatVal:
            return T()
          else:
            return NIL()
        of String:
          if y.kind == String and x.str == y.str:
            return T()
          else:
            return NIL()
        of Symbol:
          if y.kind == Symbol and x.sym.name == y.sym.name:
            return T()
          else:
            return NIL()
        else:
          discard
          
    body: BuiltinFn =
      proc(args: LispObject): LispObject =
        let
          lambda = args.first
          body   = lambda.body
        return body
    append: BuiltinFn =
      proc(args: LispObject): LispObject =
        var
          list = args.first.toSeq
          elem = args.second
        if elem.kind == Cons:
          for e in elem.toSeq:
            list.add e
          return list.list
        list.add elem
        return list.list
      
   # setf: Builtin =
   #   proc(args: LispObject): LispObject =
   #     echo args
   #     let
   #       sym = args.first
   #       val = args.second
   #     env.interned[sym.sym.name] = val
   #     return val
  result.loadedModules = Stdlib
  result.interned = toTable {
    "t"            : T(),
    "+"            : newBuiltin(lispadd,             "+"),
    "*"            : newBuiltin(lispMultiply,        "*"),
    "mod"          : newBuiltin(lispMod,             "mod"),
    ">"            : newBuiltin(lispGreaterThan,     ">"),
    "="            : newBuiltin(eq,                  "="),
    "append"       : newBuiltin(append,              "append"),
    "map"          : newBuiltin(map,                 "map"),
    "filter"       : newBuiltin(filter,              "filter"),
    "list"         : newBuiltin(list,                "list"),
    "cons"         : newBuiltin(cons,                "cons"),
    "car"          : newBuiltin(car,                 "car"),
    "cdr"          : newBuiltin(cdr,                 "cdr"),
    "putLn"        : newBuiltin(putLn,               "putLn"),
    "body"         : newBuiltin(body,                "body"),
    "typeOf"       : newBuiltin(typeOf,              "typeOf")
   }
   
  return result

