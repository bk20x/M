import std/[strformat, tables, streams, strutils]
import lispobject, reader

import builtins
import Strings



type
  ReturnException* = ref object of CatchableError
    retVal*: LispObject
    
proc newScope*(parent: ref Env): owned ref Env =
  new result
  result.interned = parent.interned
  return result

proc lookupRef*(env: Env, symName: string): ptr LispObject =
  if env.interned.hasKey(symName):
    return addr env.interned[symName]
  else:
    raise newException(ValueError, fmt"Unbound reference {symName}")
    
proc intern*(env: var ref Env, sym: string, val: LispObject) =
  if sym in env.interned:
    echo fmt"WARNING: Redefining {sym} in the current scope"
  env.interned[sym] = val


  
  
var
  lookupPlace: proc(env: var ref Env, form: LispObject): ptr LispObject
  ifImpl:      proc(env: var ref Env, form: LispObject): LispObject
  doTimes:     proc(env: var ref Env, form: LispObject): LispObject
  doList:      proc(env: var ref Env, form: LispObject): LispObject
  evalLambda:  proc(env: var ref Env, form: LispObject, evaluated: seq[LispObject]): LispObject {.inline.}
  load:        proc(env: var ref Env, form: LispObject): LispObject


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

proc eval*(env: var ref Env, form: LispObject): LispObject {.discardable.} =
  if form.isNil or form.kind in {Int, Float, String}:
    return form
  elif form.kind == Symbol:
    if env.interned.hasKey(form.sym.name):
      return env.interned[form.sym.name]
    else:
      raise newException(ValueError, "Unbound symbol: " & form.sym.name)
  elif form.kind == Cons:
    if form.isNil:
      return NIL()

      
    if form.car.kind == Symbol:
      case form.car.sym.name: # special forms
      of "fn":
        # (fn name (params) (body))
        let
          name   = form.cdr.car
          params = form.cdr.cdr.car
          body   = form.cdr.cdr.cdr.car
          lambda = env.newLambda(params, body)
        env.intern(name.sym.name, lambda)
        return name
      of "load":
        let
          file = form.second
        return env.load file
      of "return":
         let
           valForm = form.cdr.car
           val = env.eval: valForm
         raise ReturnException(retVal: val)
      of "if":
        # (if (cond) (expr) (elt))
        return env.ifImpl(form.cdr)
      of "defvar":
        # (defvar name val)
        let
          name = form.cdr.car
          val  = env.eval: form.cdr.cdr.car
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
    ##if op.kind == Symbol and env.interned.hasKey(op.sym.name):
      ##return env.evalLambda(env.interned[op.sym.name], evaluated)
      
    # Built-in functions
    if op.kind == Builtin:
      var
        reversedArgs: seq[LispObject] = @[]
        consArgs = NIL()
        
      for i in countdown(evaluated.len - 1, 0):
        reversedArgs.add: evaluated[i]

      for arg in reversedArgs:
        consArgs = cons(arg, consArgs)
      
      return op.fun(consArgs)      
    # User defined funs
    elif op.kind == Lambda:
      return env.evalLambda(op, evaluated)
    else:
      raise newException(ValueError, fmt"Can't apply non-function object: {op} OF {$op.kind}")
  else:
    raise newException(ValueError,   fmt"Can't eval object: {form} OF {$form.kind}")



lookupPlace = proc(env: var ref Env, form: LispObject): ptr LispObject =
  if form.kind == Symbol:
    if not env.interned.hasKey(form.sym.name):
      raise newException(ValueError, fmt"Unbound symbol {form.sym.name}")
    return addr env.interned[form.sym.name]
  elif form.kind == Cons:
    let op = form.car
    if op.kind == Symbol:
      let
        listForm = form.cdr.car
        listVal = env.eval: listForm
      if listVal.kind == Cons:
        return addr listVal.car
    raise newException(ValueError, "Invalid setf place: " & $form.kind)
  else:
    raise newException(ValueError, "Invalid setf place: " & $form.kind)

evalLambda =
    proc(env: var ref Env, form: LispObject, evaluated: seq[LispObject]): LispObject {.inline.} =
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
    proc(env: var ref Env, form: LispObject): LispObject =
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
    proc(env: var ref Env, form: LispObject): LispObject =
      let
        times = form.first.intVal
        body  = form.second
      var i = 0
      while not (i == times - 1): # bc we return the last eval
        env.eval: body
        i += 1
      return env.eval: body 
        

doList =
    proc(env: var ref Env, form: LispObject): LispObject =
      let
        varAndList = form.first # (var list)
        body = form.second # (body)
        varSym = varAndList.car # 
        listForm = varAndList.cdr.car 
      
     
      let evaluatedList = env.eval: listForm
      if evaluatedList.kind != Cons and not evaluatedList.isNil:
        raise newException(ValueError, fmt"expected list for `doList` but got {$evaluatedList.kind}")
        

      var listToIter = evaluatedList
      

      while not listToIter.isNil:
        var newEnv = env.newScope()
        
        newEnv.interned[varSym.sym.name] = listToIter.car
        
        result = newEnv.eval: body
        listToIter = listToIter.cdr
      return result

  
load =
  proc(env: var ref Env, form: LispObject): LispObject =
    let sexprs = readAllSexprs form.str
    for sexp in sexprs:
      env.eval sexp
    return T()


proc newEnv*(): owned ref Env =
  new result
  var env = result
  let
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

    function: BuiltinFn =
      proc(args: LispObject): LispObject =
        let fn = args.car.name
        if fn in env.interned and env.interned[fn].kind == Builtin:
          return env.interned[fn]

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
        assert x.kind == y.kind
        case x.kind:
        of Int:
          if x.intVal == y.intVal:
            return T()
          else:
            return NIL()
        of Float:
          if x.floatVal == y.floatVal:
            return T()
          else:
            return NIL()
        of String:
          if x.str == y.str:
            return T()
          else:
            return NIL()
        of Symbol:
          if x.sym.name == y.sym.name:
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

   # setf: Builtin =
   #   proc(args: LispObject): LispObject =
   #     echo args
   #     let
   #       sym = args.first
   #       val = args.second
   #     env.interned[sym.sym.name] = val
   #     return val
  result.interned = toTable {
    "t"            : T(),
    "+"            : newBuiltin(lispadd,             "+"),
    "*"            : newBuiltin(lispMultiply,        "*"),
    ">"            : newBuiltin(lispGreaterThan,     ">"),
    "eq"           : newBuiltin(eq,                  "eq"),
    "list"         : newBuiltin(list,                "list"),
    "car"          : newBuiltin(car,                 "car"),
    "cdr"          : newBuiltin(cdr,                 "cdr"),
    "putLn"        : newBuiltin(putLn,               "putLn"),
    "function"     : newBuiltin(function,            "function"),
    "body"         : newBuiltin(body,                "body"),
    "typeOf"       : newBuiltin(typeOf,              "typeOf"),
    "strConcat"    : newBuiltin(strConcat,           "strConcat"),
    "strLen"       : newBuiltin(strLen,              "strLen"),
    "strDowncase"  : newBuiltin(strDowncase,         "strDowncase"),
    "strUpcase"    : newBuiltin(strUpcase,           "strUpcase"),
    "strReplace"   : newBuiltin(strReplace,          "strReplace")
   }
   
  return result

