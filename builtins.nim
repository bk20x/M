import std/[strformat]
import lispobject
import environment




  
let lispAdd*: BuiltinFn =
  proc(args: LispObject): LispObject =
    let nums = args.toSeq
    var
      isFloat   = false
      intSum    = 0
      floatSum  = 0.0
    for num in nums:
      if num.kind == Float:
        isFloat = true
        break
    for num in nums:
      if isFloat:
        case num.kind:
        of Int:
          floatSum += num.intVal.float
        of Float:
          floatSum += num.floatVal
        else:
          raise newException(ValueError, fmt"got {num.kind} but expected Int or Float")
      else:
        case num.kind:
        of Int:
          intSum += num.intVal
        else:
          raise newException(ValueError, fmt"got {num.kind} but expected Int or Float")
    if isFloat:
      return newFloat(floatSum)
    else:
      return newInt(intSum)

let lispMultiply*: BuiltinFn =
  proc(args: LispObject): LispObject =
    let
      x = args.first
      y = args.second
    if x.kind == Float or y.kind == Float:
      let
        xVal = if x.kind == Float: x.floatVal else: x.intVal.float
        yVal = if y.kind == Float: y.floatVal else: y.intVal.float
        res  = xVal * yVal
      if res is float:
        return newFloat(res)
    else:
      return newInt(x.intVal * y.intVal)

let lispGreaterThan*: BuiltinFn =
  proc(args: LispObject): LispObject =
    if args.cdr.isNil:
      raise newException(ValueError, "`>` expects 2 arguments")
    let
      x = args.first
      y = args.second
    if not (x.kind in {Int, Float}) or not (y.kind in {Int, Float}):
      raise newException(ValueError, fmt"`>` expects Int or Float but got {x.kind} and {y.kind}")
      
    var isGreater: bool
    if x.kind == Float or y.kind == Float:
      var
        xVal = if x.kind == Float: x.floatVal else: x.intVal.float
        yVal = if y.kind == Float: y.floatVal else: y.intVal.float
      isGreater = xVal > yVal
    else:
      isGreater = x.intVal > y.intVal
      if isGreater:
        return T()
      else:
        return NIL()
