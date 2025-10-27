import std/[strformat, tables]
import lispobject

import Strings



type
  ReturnException* = ref object of CatchableError
    retVal*: LispObject
    
proc newScope*(parent: ref Env): owned ref Env =
  new result
  result.interned = parent.interned
  return result


proc intern*(env: var ref Env, sym: string, val: LispObject) =
  if sym in env.interned:
    echo fmt"WARNING: Redefining {sym} in the current scope"
  env.interned[sym] = val

var
  ifImpl:  proc(env: var ref Env, form: LispObject): LispObject
  doTimes: proc(env: var ref Env, form: LispObject): LispObject
  doList:  proc(env: var ref Env, form: LispObject): LispObject
  evalLambda: proc(env: var ref Env, form: LispObject, evaluated: seq[LispObject]): LispObject {.inline.}
  
proc eval*(env: var ref Env, form: LispObject): LispObject {.discardable.} =
  if form.isNil or form.kind in {Number, String}:
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
      of "return":
         let valForm = form.cdr.car
         let val = eval(env, valForm)
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
        # (setf name val)
        let
          name = form.cdr.car
          val = env.eval: form.cdr.cdr.car
        env.interned[name.sym.name] = val
        return val
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
    if op.kind == Function:
      var reversedArgs: seq[LispObject] = @[]
      for i in countdown(evaluated.len - 1, 0):
        reversedArgs.add: evaluated[i]

      var consArgs = NIL()
      for arg in reversedArgs:
        consArgs = cons(arg, consArgs)
      
      return op.fun(consArgs)      
    # User defined funs
    elif op.kind == Lambda:
      return env.evalLambda(op, evaluated)
    else:
      raise newException(ValueError, "Can't apply non-function object: " & $op.kind)
  else:
    raise newException(ValueError, "Can't eval object of kind: " & $form.kind)

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
        times = form.first.num
        body  = form.second
      var i = 0.0
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

        
proc newEnv*(): owned ref Env =
  new result
  var env = result
  let
    car: Fun =
      proc(args: LispObject): LispObject =
        return args.car.car
        
    cdr: Fun =
      proc(args: LispObject): LispObject =
        return args.car.cdr
        
    list: Fun =
      proc(args: LispObject): LispObject =
        return args
        
    lispgthan: Fun =
      proc(args: LispObject): LispObject =
        let
          x = args.first
          y = args.second
        if not (x.kind == Number) and (y.kind == Number):
          raise newException(ValueError, fmt"Attempt to call > on {x.kind} and {y.kind}")
        elif x.num > y.num:
           return newSym "t"
        else:
           return NIL()
               
    lispadd: Fun =
      proc(args: LispObject): LispObject =
        let nums = args.toSeq
        var n = 0.0
        for num in nums:
          n += num.num
        return LispObject(kind: Number, num: n)
        
    lispmul: Fun =
      proc(args: LispObject): LispObject =
        let
          x = args.first.num
          y = args.second.num
        return LispObject(kind: Number, num: x * y)
        
    function: Fun =
      proc(args: LispObject): LispObject =
        let fn = args.car.name
        if fn in env.interned and env.interned[fn].kind == Function:
          return env.interned[fn]

    putLn: Fun =
      proc(args: LispObject): LispObject =
        let obj = args.car
        case obj.kind:
        of String:
          echo obj.str
        of Number:
          echo obj.num
        of Symbol:
          echo obj.sym.name
        of Function:
          echo obj
        of Cons:
          echo obj
        else:
          discard
        return NIL()
        
    typeOf: Fun =
      proc(args: LispObject): LispObject =
        return LispObject(kind: String, str: $args.first.kind)

    eq: Fun =
      proc(args: LispObject): LispObject =
        let
          x = args.first
          y = args.second
        assert x.kind == y.kind
        case x.kind:
        of Number:
          if x.num == y.num:
            return newSym "t"
          else:
            return NIL()
        of Symbol:
          if x.sym.name == y.sym.name:
            return newSym "t"
          else:
            return NIL()
        else:
          discard
          


   # setf: Fun =
   #   proc(args: LispObject): LispObject =
   #     echo args
   #     let
   #       sym = args.first
   #       val = args.second
   #     env.interned[sym.sym.name] = val
   #     return val
  result.interned = toTable {
    "t"            : newSym "t",
    "+"            : newFun(lispadd,       "+"),
    "*"            : newFun(lispmul,       "*"),
    ">"            : newFun(lispgthan,     ">"),
    "eq"           : newFun(eq,            "eq"),
    "list"         : newFun(list,          "list"),
    "car"          : newFun(car,           "car"),
    "cdr"          : newFun(cdr,           "cdr"),
    "putLn"        : newFun(putLn,         "putLn"),
    "function"     : newFun(function,      "function"),
    "typeOf"       : newFun(typeOf,        "typeOf"),
    "strConcat"    : newFun(strConcat,     "strConcat"),
    "strLen"       : newFun(strLen,        "strLen"),
    "strDowncase"  : newFun(strDowncase,   "strDowncase"),
    "strUpcase"    : newFun(strUpcase,     "strUpcase")
   }
   
  return result

