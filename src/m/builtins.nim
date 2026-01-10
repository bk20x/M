import std/[strformat, strutils]
import lispobject
import bigints





proc toBigInt(obj: LispObject): BigInt =
  case obj.kind
  of Int:    return initBigInt(obj.intVal)
  of BigInt: return obj.bigNum
  else: raise newException(ValueError, fmt"Expected Int or BigInt, got {obj.kind}")

proc toFloat(bi: BigInt): float =
  return parseFloat($bi)
  

proc lispAdd*(args: LispObject): LispObject =
    let nums = args.toSeq
    var
      isFloat   = false
      isBigInt  = false
    for num in nums:
      if num.kind == Float: isFloat = true; break
      elif num.kind == LispObjectKind.BigInt: isBigInt = true
    if isFloat:
      var floatSum  = 0.0
      for num in nums:
        if   num.kind == Int:    floatSum += num.intVal.float
        elif num.kind == Float:  floatSum += num.floatVal
        elif num.kind == LispObjectKind.BigInt: floatSum += num.bigNum.toFloat
        else: raise newException(ValueError, fmt"`+` got {num.kind} but expected numeric types")
      return newFloat(floatSum)
    elif isBigInt:
      var bigIntSum = nums[0].toBigInt() 
      for i in 1..<nums.len:
        bigIntSum += nums[i].toBigInt()
      return LispObject(kind: BigInt, bigNum: bigIntSum)
    else:
      var intSum = 0
      try:
        for num in nums:
          if num.kind == Int:
            intSum += num.intVal # This might overflow
          else:
            raise newException(ValueError, fmt"`+` got {num.kind} but expected Int")
        return newInt(intSum)
      except OverflowDefect:
        var bigIntSum = initBigInt(0)
        for num in nums:
           bigIntSum += initBigInt(num.intVal)
        return LispObject(kind: BigInt, bigNum: bigIntSum)

proc lispSub*(args: LispObject): LispObject =
  if args.len != 2:
    raise newException(ValueError, fmt"`-` expects 2 args of Int | Float | BigInt but got {args}")
  let
    x = args.first
    y = args.second
  if x.kind == Float or y.kind == Float:
    let
      xVal = if x.kind == Float: x.floatVal elif x.kind == Int: x.intVal.float else: x.bigNum.toFloat
      yVal = if y.kind == Float: y.floatVal elif y.kind == Int: y.intVal.float else: y.bigNum.toFloat
      res  = xVal - yVal
    return newFloat(res)
  elif x.kind == LispObjectKind.BigInt or y.kind == LispObjectKind.BigInt:
    let
      xVal = x.toBigInt()
      yVal = y.toBigInt()
      res  = xVal - yVal
    return LispObject(kind: BigInt, bigNum: res)
  else:
    try:
      let res = x.intVal - y.intVal
      return newInt(res)
    except OverflowDefect:
      let res = initBigInt(x.intVal) - initBigInt(y.intVal)
      return LispObject(kind: BigInt, bigNum: res)

      
proc lispDiv*(args: LispObject): LispObject =
  if args.len != 2:
    raise newException(ValueError, fmt"`/` expects 2 args of Int | Float | BigInt but got {args}")
  let
    x = args.first
    y = args.second
  if x.kind == Float or y.kind == Float:
    let
      xVal = if x.kind == Float: x.floatVal elif x.kind == Int: x.intVal.float else: x.bigNum.toFloat
      yVal = if y.kind == Float: y.floatVal elif y.kind == Int: y.intVal.float else: y.bigNum.toFloat
      res  = xVal / yVal
    return newFloat(res)
  elif x.kind == LispObjectKind.BigInt or y.kind == LispObjectKind.BigInt:
    let
      xVal = x.toBigInt()
      yVal = y.toBigInt()
      res  = xVal div yVal
    return LispObject(kind: BigInt, bigNum: res)
  else:
    try:
      let res = x.intVal / y.intVal
      return newFloat(res)
    except OverflowDefect:
      let res = initBigInt(x.intVal) div initBigInt(y.intVal)
      return LispObject(kind: BigInt, bigNum: res)
      
proc lispMultiply*(args: LispObject): LispObject =
    if args.len != 2:
      raise newException(ValueError, fmt"`*` expects 2 args of Int | Float | BigInt but got {args}")
    let
      x = args.first
      y = args.second
    if x.kind == Float or y.kind == Float:
      let
        xVal = if x.kind == Float: x.floatVal elif x.kind == Int: x.intVal.float else: x.bigNum.toFloat
        yVal = if y.kind == Float: y.floatVal elif y.kind == Int: y.intVal.float else: y.bigNum.toFloat
        res  = xVal * yVal
      return newFloat(res)
    elif x.kind == LispObjectKind.BigInt or y.kind == LispObjectKind.BigInt:
      let
        xVal = x.toBigInt()
        yVal = y.toBigInt()
        res  = xVal * yVal
      return LispObject(kind: BigInt, bigNum: res)
    else:
      try:
        let res = x.intVal * y.intVal
        return newInt(res)
      except OverflowDefect:
        let res = initBigInt(x.intVal) * initBigInt(y.intVal)
        return LispObject(kind: BigInt, bigNum: res)
    


proc lispGreaterThan*(args: LispObject): LispObject =
    if args.len != 2:
      raise newException(ValueError, fmt"`>` expects 2 args of Int | Float | BigInt but got {args}")
    let
      x = args.first
      y = args.second
    var isGreater: bool
    if x.kind == Float or y.kind == Float:
      let
        xVal    = if x.kind == Float: x.floatVal elif x.kind == Int: x.intVal.float else: x.bigNum.toFloat
        yVal    = if y.kind == Float: y.floatVal elif y.kind == Int: y.intVal.float else: y.bigNum.toFloat
      isGreater = xVal > yVal
    elif x.kind == LispObjectKind.BigInt or y.kind == LispObjectKind.BigInt:
      let
        xVal    = x.toBigInt()
        yVal    = y.toBigInt()
      isGreater = xVal > yVal
    else:
      isGreater = x.intVal > y.intVal      
    if isGreater:
      return T()
    else:
      return NIL()

proc lispLessThan*(args: LispObject): LispObject =
  return if lispGreaterThan(args).isT: NIL() else: T()

proc lispMod*(args: LispObject): LispObject =
    if args.len != 2:
      raise newException(ValueError, fmt"`mod` expects 2 args of Int | Float | BigInt but got {args}")
    let
      x = args.first
      y = args.second
    if not (x.kind in {Int, BigInt}) or not (y.kind in {Int, BigInt}):
       raise newException(ValueError, fmt"`mod` expects Int or BigInt but got {x.kind} and {y.kind}")
    let
      xVal = x.toBigInt()
      yVal = y.toBigInt()
    if xVal == initBigInt(0) or yVal == initBigInt(0):
      raise newException(ValueError, "Cant divide by 0!!!")
    let res  = xVal mod yVal

    return LispObject(kind: BigInt, bigNum: res)


proc lispEquals*(args: LispObject): LispObject =
    if args.len != 2:
      raise newException(ValueError, fmt"`=` expects 2 args but got {args}")
    let
      x = args.first 
      y = args.second
    var areEqual: bool = false

    if x.kind == Nil and y.kind == Nil:
      areEqual = true

    elif x.kind in {Int, Float, BigInt} and y.kind in {Int, Float, BigInt}:
      if x.kind == Float or y.kind == Float:
        let
          xVal = if x.kind == Float: x.floatVal elif x.kind == Int: x.intVal.float else: x.bigNum.toFloat
          yVal = if y.kind == Float: y.floatVal elif y.kind == Int: y.intVal.float else: y.bigNum.toFloat
        areEqual = (xVal == yVal)
      elif x.kind == LispObjectKind.BigInt or y.kind == LispObjectKind.BigInt:
        let
          xVal = x.toBigInt()
          yVal = y.toBigInt()
        areEqual = (xVal == yVal)
      else:
        areEqual = (x.intVal == y.intVal)
    elif x.kind == String and y.kind == String:
        areEqual = (x.str == y.str)
    elif x.kind == Symbol and y.kind == Symbol:
        areEqual = (x.sym.name == y.sym.name)
    elif x.kind == Builtin and y.kind == Builtin:
      areEqual = x.fun == y.fun
    elif x == y:
      areEqual = true
    if areEqual:
      return T()
    else:
      return NIL()


proc lispLessThanEq*(args: LispObject): LispObject =
  return if (lispLessThan(args).isT) or (lispEquals(args).isT): T() else: NIL()

proc lispGreaterThanEq*(args: LispObject): LispObject =
  return if (lispGreaterThan(args).isT) or (lispEquals(args).isT): T() else: NIL()
  
proc lispUneql*(args: LispObject): LispObject =
  return if lispEquals(args).isNil: T() else: NIL()

proc append*(args: LispObject): LispObject =
  result = NIL()
  var
    list = args.first.toSeq
    elem = args.second
  if elem.kind == Cons:
    for e in elem.toSeq:
      list.add e
    return list.list
  list.add elem
  return list.list



  
let first*: BuiltinFn =
  proc(args: LispObject): LispObject =
    if args.len != 1 or not (args.first.kind == Cons):
      raise newException(ValueError, fmt"`second` is of type Cons -> T but got {args}")
    return args.car.first

let second*: BuiltinFn =
  proc(args: LispObject): LispObject =
    if args.len != 1 or not (args.first.kind == Cons):
      raise newException(ValueError, fmt"`second` is of type Cons -> T but got {args}")
    let
      form = args.car
    if form.cdr.isAtom:
      return form.cdr    
    return form.second

