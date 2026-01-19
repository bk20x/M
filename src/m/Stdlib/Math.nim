import std/[math, strformat, tables]
import ../lispobject


proc sin(args: LispObject): LispObject =
  if args.len != 1 or not (args.first.kind in {Int, Float}):
    raise newException(ValueError, fmt"`sin` is of type Int | Float -> Float but got {args}")
  let
    x = args.first
  if x.kind == Float:
    return newFloat(sin x.floatVal)
  else:
    return newFloat(sin x.intVal.float)
  
  
proc pow(args: LispObject): LispObject =
  if args.len != 2 or not ({args.first.kind, args.second.kind} <= {Int, FLoat}):
    raise newException(ValueError, fmt"`pow` is of type Int | Float -> Int | Float -> Float but got {args}")
  let
    x = args.first
    y = args.second
  let
    xVal = if x.kind == Float: x.floatVal else: x.intVal.float
    yVal = if y.kind == Float: y.floatVal else: y.intVal.float
  return newFloat(xVal.pow(yVal))


proc ceil(args: LispObject): LispObject =
  if args.len != 1 or not (args.first.kind == Float):
    raise newException(ValueError, fmt"`ceil` is of type Float -> Float but got {args}")
  let x = args.first.floatVal
  return newFloat(ceil(x))
  
proc floor(args: LispObject): LispObject =
  if args.len != 1 or not (args.first.kind == Float):
    raise newException(ValueError, fmt"`floor` is of type Float -> Float but got {args}")
  let x = args.first.floatVal
  return newFloat(floor(x))

proc sqrt(args: LispObject): LispObject =
  if args.len != 1 or not (args.first.kind == Float):
    raise newException(ValueError, fmt"`sqrt` is of type Float -> Float but got {args}")
  let x = args.first.floatVal
  return newFloat(sqrt(x))

proc tan(args: LispObject): LispObject =
  if args.len != 1 or not (args.first.kind == Float):
    raise newException(ValueError, fmt"`tan` is of type Float -> Float but got {args}")
  let x = args.first.floatVal
  return newFloat(tan(x))
  
const
  Module* = toTable {
    "sin"    : BuiltinFn Math.sin,
    "pow"    : BuiltinFn Math.pow,
    "ceil"   : BuiltinFn Math.ceil,
    "floor"  : BuiltinFn Math.floor,
    "sqrt"   : BuiltinFn Math.sqrt,
    "tan"    : BuiltinFn Math.tan
  }
    
