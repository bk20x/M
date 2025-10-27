import std/[strformat, strutils]
import lispobject



let strConcat*: Fun = proc(args: LispObject): LispObject =
  let
    first  = args.first
    second = args.second
  if not ((first.kind  == String) and (second.kind == String)):
    raise newException(ValueError, fmt"`strConcat` is of type String -> String -> String but got {first} as {first.kind} and {second} as {second.kind}")
  else:
    return newStr(first.str & second.str)

let strLen*: Fun = proc(args: LispObject): LispObject =
  if not (args.first.kind == String):
    raise newException(ValueError, fmt"`strLen` is of type String -> String but got {$args.first.kind}")
  else:
    return newNum(float args.first.str.len)

let strDowncase*: Fun = proc(args: LispObject): LispObject =
  if not (args.first.kind == String):
    raise newException(ValueError, fmt"`toLower` is of type String -> String but got {$args.first.kind}")
  else:
    return newStr(args.first.str.toLower)


let strUpcase*: Fun = proc(args: LispObject): LispObject =
  if not (args.first.kind == String):
    raise newException(ValueError, fmt"`toUpper` is of type String -> String but got {$args.first.kind}")
  else:
    return newStr(args.first.str.toUpper)
