import std/[tables, sequtils, sugar, osproc, os]
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

proc runCmdCode(args: LispObject): LispObject =
  if not args.len == 1 and not (args.first.kind  == String):
    raise newException(ValueError, "`cmd!` is of type String -> Int but gut {args}")
  let
    command = args.first.str
    res     = execCmdEx(command)
  return cons(newInt(res.exitCode), newStr(res.output))

proc listDir(args: LispObject): LispObject =
  let
    dirName = args.first
  var
    files: seq[string]
  for f in walkDir(dirName.str):
    files.add f.path
  return files.map(ln => newStr(ln)).list

proc isFile(args: LispObject): LispObject =
  let
    filename = args.first
  if filename.str.fileExists:
    return T()
  return NIL()
  
const
  Module* = toTable {
    "readFile"  : BuiltinFn SysIo.readFile,
    "readLines" : BuiltinFn SysIo.readLines,
    "writeFile" : BuiltinFn SysIo.writeFile,
    "listDir"   : BuiltinFn SysIo.listDir,
    "cmd!"      : BuiltinFn SysIo.runCmdCode,
    "isFile?"   : BuiltinFn SysIo.isFile
  }
