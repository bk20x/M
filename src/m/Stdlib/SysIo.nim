import std/[tables, sequtils, sugar, osproc, os, strformat]
import ../lispobject

    
proc readFile(args: LispObject): LispObject =
  if args.len != 1 or not (args.first.kind == String):
    raise newException(ValueError, fmt"`slurp` is of type String -> String but got {args}")
  return newStr(readFile args.first.str)

proc readLines(args: LispObject): LispObject =
  if args.len != 2 or not (args.first.kind == String and args.second.kind == Int):
    raise newException(ValueError, fmt"`readLines` is of type String -> Int -> String list but got {args}")
  return readLines(args.first.str, args.second.intVal).map(ln => newStr ln).list

proc writeFile(args: LispObject): LispObject =
  if args.len != 2 or not (args.first.kind == String and args.second.kind == String):
    raise newException(ValueError, fmt"`writeFile` is of type String -> String -> () but got {args}")
  let
    filename = args.first.str
    content  = args.second.str
  writeFile(filename, content)
  return NIL()

proc runCmdCode(args: LispObject): LispObject =
  if args.len != 1 or not (args.first.kind  == String):
    raise newException(ValueError, fmt"`cmd!` is of type String -> Int but gut {args}")
  let
    command = args.first.str
    res     = execCmdEx(command)
  return cons(newInt(res.exitCode), newStr(res.output))

proc listDir(args: LispObject): LispObject =
  if args.len != 1 or not (args.first.kind == String):
    raise newException(ValueError, fmt"`listDir` is of type String -> String list but got {args}")
  let dirName = args.first
  var files: seq[string]
  for f in walkDir(dirName.str):
    files.add f.path
  return files.map(ln => newStr(ln)).list

proc isFile(args: LispObject): LispObject =
  if args.len != 1 or not (args.first.kind == String):
    raise newException(ValueError, fmt"`isFile` is of type String -> Bool but got {args}")
  let filename = args.first
  if filename.str.fileExists:
    return T()
  return NIL()

proc getEnv(args: LispObject): LispObject =
  if args.len != 1 or not (args.first.kind == String):
    raise newException(ValueError, fmt"`getEnv` is of type String -> String but got {args}")
  let env = getEnv(args.first.str)
  return if env == "": NIL() else: newStr(env)

proc getFileSize(args: LispObject): LispObject =
  if args.len != 1 or not (args.first.kind == String):
    raise newException(ValueError, fmt"`getFileSize` is of type String -> Int but got {args}")
  let filename = args.first.str
  return if fileExists filename: newInt getFileSize(filename) else: NIL()
  
proc input(args: LispObject): LispObject =
  return newStr(stdin.readLine())

proc sleep(args: LispObject): LispObject =
  if args.len != 1 or not (args.first.kind == Int):
    raise newException(ValueError, fmt"`sleep` is of type Int -> Nil but got {args}")
  sleep(args.first.intVal)
  return NIL()
  
proc absolutePath(args: LispObject): LispObject =
  if args.len != 1 or not (args.first.kind == String):
    raise newException(ValueError, fmt"`absolutePath` is of type String -> String but got {args}")
  return newStr(args.first.str.expandFilename)

proc getOccMem(args: LispObject): LispObject =
  return newInt(getOccupiedMem())

proc getCurDir(args: LispObject): LispObject =
  return newStr(getCurrentDir())

proc chdir(args: LispObject): LispObject =
  if args.len != 1 or not (args.first.kind == String):
    raise newException(ValueError,fmt"`chdir` is of type String -> Nil but got {args}")
  setCurrentDir(args.first.str)
  return NIL()

const
  Module* = toTable {
    "readFile"    : BuiltinFn SysIo.readFile,
    "readLines"   : BuiltinFn SysIo.readLines,
    "writeFile"   : BuiltinFn SysIo.writeFile,
    "listDir"     : BuiltinFn SysIo.listDir,
    "cmd!"        : BuiltinFn SysIo.runCmdCode,
    "isFile?"     : BuiltinFn SysIo.isFile,
    "getEnv"      : BuiltinFn SysIo.getEnv,
    "getFileSize" : BuiltinFn SysIo.getFileSize,
    "input"       : BuiltinFn SysIo.input,
    "sleep"       : BuiltinFn SysIo.sleep,
    "absolutePath": BuiltinFn SysIo.absolutePath,
    "getOccupiedMem": BuiltinFn SysIo.getOccMem,
    "getCurrentDir": BuiltinFn SysIo.getCurDir,
    "chdir"        : BuiltinFn SysIo.chdir
  }
