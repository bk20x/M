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
      case num.kind
      of Int: discard
      of Float: isFloat = true; break
      of LispObjectKind.BigInt: isBigInt = true; break
      else:
        raise newException(ValueError, fmt"invalid argument for `+`! {num}")
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
  if args.len != 2 or not(args.first.kind in {Int, Float, BigInt} and args.second.kind in {Int, Float, BigInt}):
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
  if args.len != 2 or not(args.first.kind in {Int, Float, BigInt} and args.second.kind in {Int, Float, BigInt}):
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
    if args.len != 2 or not(args.first.kind in {Int, Float, BigInt} and args.second.kind in {Int, Float, BigInt}):
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
  if args.len != 2 or not(args.first.kind in {Int, Float, BigInt} and args.second.kind in {Int, Float, BigInt}):
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
    if args.len != 2 or not(args.first.kind in {Int, Float, BigInt} and args.second.kind in {Int, Float, BigInt}):
      raise newException(ValueError, fmt"`<` expects 2 args of Int | Float | BigInt but got {args}")
    let
      x = args.first
      y = args.second
    var isLess: bool
    if x.kind == Float or y.kind == Float:
      let
        xVal    = if x.kind == Float: x.floatVal elif x.kind == Int: x.intVal.float else: x.bigNum.toFloat
        yVal    = if y.kind == Float: y.floatVal elif y.kind == Int: y.intVal.float else: y.bigNum.toFloat
      isLess = xVal < yVal
    elif x.kind == LispObjectKind.BigInt or y.kind == LispObjectKind.BigInt:
      let
        xVal    = x.toBigInt()
        yVal    = y.toBigInt()
      isLess = xVal < yVal
    else:
      isLess = x.intVal < y.intVal      
    if isLess:
      return T()
    else:
      return NIL()

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
    return if x == y: T() else: NIL()


proc lispLessThanEq*(args: LispObject): LispObject =
  return if (lispLessThan(args).isT) or (lispEquals(args).isT): T() else: NIL()

proc lispGreaterThanEq*(args: LispObject): LispObject =
  return if (lispGreaterThan(args).isT) or (lispEquals(args).isT): T() else: NIL()
  
proc lispUneql*(args: LispObject): LispObject =
  return if lispEquals(args).isNil: T() else: NIL()

proc append*(args: LispObject): LispObject =
  if not args.len == 2:
    raise newException(ValueError, fmt"append expects 2 arguments but got {args}")
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

