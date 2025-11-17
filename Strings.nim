import std/[strformat, strutils, tables, sugar, sequtils]
import lispobject



proc toString(obj: LispObject): string =
  case obj.kind:
  of String:
    return obj.str
  else:
    return $obj
      


proc strReplace(args: LispObject): LispObject =
  let
    first  = args.first
    second = args.second
    third  = args.third
  if not ((first.kind == String) or not (second.kind == String) or not (third.kind == String)):
    raise newException(ValueError, fmt"`strReplace` is of type String -> String -> String -> String but got {first} as {first.kind} and {second} as {second.kind} and {third} as {third.kind}")
  else:
    return newStr(first.str.replace(second.str, third.str))

proc strConcat(args: LispObject): LispObject =
  let
    first  = args.first
    second = args.second
  if not ((first.kind  == String) or not (second.kind == String)):
    raise newException(ValueError, fmt"`strConcat` is of type String -> String -> String but got {first} as {first.kind} and {second} as {second.kind}")
  else:
    return newStr(first.str & second.str)
    
proc strContains(args: LispObject): LispObject =
  let
    first  = args.first
    second = args.second
  if not((first.kind == String) or not (second.kind == String)):
    raise newException(ValueError, fmt"`strConcat` is of type String -> String -> Bool but got {first} as {first.kind} and {second} as {second.kind}")
  if first.str.contains(second.str):
    return T()
  return NIL()

proc strLen(args: LispObject): LispObject =
  if not (args.first.kind == String):
    raise newException(ValueError, fmt"`strLen` is of type String -> String but got {$args.first.kind}")
  else:
    return newInt(args.first.str.len)

proc strDowncase(args: LispObject): LispObject =
  if not (args.first.kind == String):
    raise newException(ValueError, fmt"`toLower` is of type String -> String but got {$args.first.kind}")
  else:
    return newStr(args.first.str.toLower)


proc strUpcase(args: LispObject): LispObject =
  if not (args.first.kind == String):
    raise newException(ValueError, fmt"`toUpper` is of type String -> String but got {$args.first.kind}")
  else:
    return newStr(args.first.str.toUpper)

proc splitLines(args: LispObject): LispObject =
  return args.first.str.splitLines.map(ln => newStr ln).list

proc strip(args: LispObject): LispObject =
  if args.len > 1:
    let
      str      = args.first.str
      leading  = if args.second.isT(): true else: false   
      trailing = if args.third.isT() : true else: false
    return newStr(str.strip(leading, trailing))
  else:
    let str = args.first.str
    return newStr(str.strip)



proc stringFormat(args: LispObject): LispObject =
  if args.len < 1 or args.first.kind != String:
    raise newException(ValueError, "`strFormat` expects a format string as its first argument.")
  var
    str       = ""
    formatStr = args.first.str
    vars      = args.cdr.toSeq 
    cursor    = 0
    i         = 0
  while i < formatStr.len:
    if formatStr[i] == '$':
      if i + 1 < formatStr.len and formatStr[i+1] == '$':
        str.add '$'
        i += 2
      else:
        if cursor >= vars.len:
          raise newException(ValueError, "Too few arguments provided for string format placeholders.")
        str.add vars[cursor].toString
        inc cursor
        inc i
    else:
      str.add formatStr[i]
      inc i
  if cursor < vars.len:
    discard
  return newStr(str)


proc substring(args: LispObject): LispObject =
  let
    str   = args.first
    start = args.second
    endp  = args.third
  return newStr(str.str[start.intVal..endp.intVal])
  
const
  Module* = toTable {
    "strReplace" : BuiltinFn strReplace,
    "strConcat"  : BuiltinFn strConcat,
    "strLen"     : BuiltinFn strLen,
    "strDowncase": BuiltinFn strDowncase,
    "strUpcase"  : BuiltinFn strUpcase,
    "strContains": BuiltinFn strContains,
    "splitLines" : BuiltinFn splitLines,
    "fmt"        : BuiltinFn stringFormat,
    "strip"      : BuiltinFn strip,
    "substring"  : BuiltinFn substring
  }
