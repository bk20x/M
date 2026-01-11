import std/[strformat, strutils, tables, sugar, sequtils]
import ../lispobject
import unicode


proc toString(obj: LispObject): string =
  case obj.kind:
  of String:
    return obj.str
  else:
    return $obj
      


proc strReplace(args: LispObject): LispObject =
  if args.len != 3 or not (args.first.kind == String and args.second.kind == String and args.third.kind == String):
    raise newException(ValueError, fmt"`strReplace` is of type String -> String -> String -> String but got {args}")
  let
    first  = args.first
    second = args.second
    third  = args.third
  return newStr(first.str.replace(second.str, third.str))

proc strConcat(args: LispObject): LispObject =
  if args.len != 2 or not (args.first.kind == String and args.second.kind == String):
    raise newException(ValueError, fmt"`strConcat` is of type String -> String -> String but got {args}")
  let
    first  = args.first
    second = args.second
  return newStr(first.str & second.str)
    
proc strContains(args: LispObject): LispObject =
  if args.len != 2 or not (args.first.kind == String and args.second.kind == String):
    raise newException(ValueError, fmt"`strContains` is of type String -> String -> Bool but got {args}")
  let
    first  = args.first
    second = args.second
  if first.str.contains(second.str):
    return T()
  return NIL()

proc strLen(args: LispObject): LispObject =
  if args.len != 1 or not (args.first.kind == String):
    raise newException(ValueError, fmt"`strLen` is of type String -> String but got {args}")
  else:
    return newInt(args.first.str.len)

proc strCharLen(args: LispObject): LispObject =
  if args.len != 1 or not (args.first.kind == String):
    raise newException(ValueError, fmt"`strCharLen` is of type String -> String but got {args}")
  else:
    return newInt(args.first.str.runeLen)

proc strDowncase(args: LispObject): LispObject =
  if args.len != 1 or not (args.first.kind == String):
    raise newException(ValueError, fmt"`strDowncase` is of type String -> String but got {args}")
  else:
    return newStr(args.first.str.toLower)


proc strUpcase(args: LispObject): LispObject =
  if args.len != 1 or not (args.first.kind == String):
    raise newException(ValueError, fmt"`strUpcase` is of type String -> String but got {args}")
  else:
    return newStr(args.first.str.toUpper)

proc splitLines(args: LispObject): LispObject =
  if args.len != 1 or not (args.first.kind == String):
    raise newException(ValueError, fmt"`splitLines` is of type String -> String list but got {args}")
  return args.first.str.splitLines.map(ln => newStr ln).list

proc strip(args: LispObject): LispObject =
  if not args.len >= 1:
    raise newException(ValueError, fmt"`strip` is of type String -> Bool -> !!optional!! Bool -> String")
  if args.len > 1:
    let
      str      = args.first.str
      leading  = if args.second.isT(): true else: false   
    var trailing: bool = true
    if args.len > 2:
      trailing = if args.third.isT(): true else: false
    return newStr(str.strip(leading = leading, trailing = trailing))
  else:
    let str = args.first.str
    return newStr(str.strip)



proc stringFormat(args: LispObject): LispObject =
  if args.len < 1 or args.first.kind != String:
    raise newException(ValueError, "`fmt` is of type String -> Varargs[T] -> String but got {args}")
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
  if args.len != 3 or not (args.first.kind == String and args.second.kind == Int and args.third.kind == Int):
    raise newException(ValueError, fmt"`substring` is of type String -> Int -> Int -> String but got {args}")
  let
    str   = args.first
    start = args.second
    endp  = args.third
  return newStr(str.str[start.intVal..endp.intVal])


proc parseI(args: LispObject): LispObject =
  if args.len != 1 or not (args.first.kind == String):
    raise newException(ValueError, fmt"`parseInt` is of type String -> Int but got {args}")
  let str = args.first
  return newInt(parseInt str.str)
  
    
const
  Module* = toTable {
    "strReplace" : BuiltinFn strReplace,
    "strConcat"  : BuiltinFn strConcat,
    "strLen"     : BuiltinFn strLen,
    "strCharLen" : BuiltinFn strCharLen,
    "strDowncase": BuiltinFn strDowncase,
    "strUpcase"  : BuiltinFn strUpcase,
    "strContains": BuiltinFn strContains,
    "splitLines" : BuiltinFn splitLines,
    "fmt"        : BuiltinFn stringFormat,
    "strip"      : BuiltinFn strip,
    "substring"  : BuiltinFn substring,
    "parseInt"   : BuiltinFn parseI
  }
