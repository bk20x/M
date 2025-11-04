import std/[math, strformat, tables]
import lispobject


proc sin(args: LispObject): LispObject =
  if not args.len == 1:
    raise newException(IndexDefect, "`sin` expects one argument!")
  let
    x = args.first
  case x.kind:
  of Float:
    return newFloat(sin x.floatVal)
  of Int:
    return newFloat(sin x.intVal.float)
  else:
    raise newException(ValueError, fmt"`sin` expected Int | Float but got {x.kind}!")
  
proc pow(args: LispObject): LispObject =
  if not args.len == 2:
    raise newException(IndexDefect, "`pow` expects 2 arguments but got {args.len}")
  let
    x = args.first
    y = args.second
  if not (x.kind in {Int, Float} or not (y.kind in {Int, Float})):
    raise newException(ValueError, "`pow` expected Int | Float but got {x.kind} and {y.kind}")
  let
    xVal = if x.kind == Float: x.floatVal else: x.intVal.float
    yVal = if y.kind == Float: y.floatVal else: y.intVal.float
  return newFloat(xVal.pow(yVal))

    
const
  Module* = toTable {
    "sin": BuiltinFn(Math.sin),
    "pow": BuiltinFn(Math.pow)
  }
    
