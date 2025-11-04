import std/[tables, sequtils, sugar]
import lispobject




proc readFile(args: LispObject): LispObject =
  if not args.len == 1:
    raise newException(ValueError, "`readFile` is of type String -> String but got {args}")
  return newStr(readFile args.first.str)

proc readLines(args: LispObject): LispObject =
  if not args.len == 2:
    raise newException(ValueError, "`readLines` is of type String -> String list but got {args}")
  return readLines(args.first.str, args.second.intVal).map(ln => newStr ln).list

proc writeFile(args: LispObject): LispObject =
  if not args.len == 2:
    raise newException(ValueError, "`writeFile` is of type String -> String -> () but got {args}")
  let
    filename = args.first.str
    content  = args.second.str
  writeFile(filename, content)
  return NIL()
  
const
  Module* = toTable {
    "readFile"  : BuiltinFn SysIo.readFile,
    "readLines" : BuiltinFn SysIo.readLines,
    "writeFile" : BuiltinFn SysIo.writeFile
  }
