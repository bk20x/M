import std/[strformat, strutils, sequtils, sugar]
import lispobject



let strReplace*: BuiltinFn = proc(args: LispObject): LispObject =
  let
    first  = args.first
    second = args.second
    third  = args.third
  if not ((first.kind == String) or not (second.kind == String) or not (third.kind == String)):
    raise newException(ValueError, fmt"`strReplace` is of type String -> String -> String -> String but got {first} as {first.kind} and {second} as {second.kind} and {third} as {third.kind}")
  else:
    return newStr(first.str.replace(second.str, third.str))

let strConcat*: BuiltinFn = proc(args: LispObject): LispObject =
  let
    first  = args.first
    second = args.second
  if not ((first.kind  == String) or not (second.kind == String)):
    raise newException(ValueError, fmt"`strConcat` is of type String -> String -> String but got {first} as {first.kind} and {second} as {second.kind}")
  else:
    return newStr(first.str & second.str)

let strLen*: BuiltinFn = proc(args: LispObject): LispObject =
  if not (args.first.kind == String):
    raise newException(ValueError, fmt"`strLen` is of type String -> String but got {$args.first.kind}")
  else:
    return newInt(args.first.str.len)

let strDowncase*: BuiltinFn = proc(args: LispObject): LispObject =
  if not (args.first.kind == String):
    raise newException(ValueError, fmt"`toLower` is of type String -> String but got {$args.first.kind}")
  else:
    return newStr(args.first.str.toLower)


let strUpcase*: BuiltinFn = proc(args: LispObject): LispObject =
  if not (args.first.kind == String):
    raise newException(ValueError, fmt"`toUpper` is of type String -> String but got {$args.first.kind}")
  else:
    return newStr(args.first.str.toUpper)

