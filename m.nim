import std/[cmdline, strutils, streams]
import repl, environment, reader, lispobject






proc readAllSexprs(filename: string): seq[LispObject] =
  result = @[]
  var s = newFileStream(filename, fmRead)
  if s == nil:
    quit("Could not open file: " & filename)

  var
    buffer = ""
    parenCount = 0

  while not s.atEnd:
    let c = s.readChar()
    case c:
    of '(':
      parenCount += 1
      buffer.add(c)
    of ')':
      parenCount -= 1
      buffer.add(c)
      if parenCount == 0:
        result.add: parse buffer.strip()
        buffer = ""
    of ' ', '\n', '\t':
      if parenCount > 0:
        buffer.add(c)
    else:
      buffer.add(c)

  s.close()
  
proc doFile(env: var Env, file: string) =
  let sexprs = readAllSexprs file    
  for sexp in sexprs:
    env.eval sexp



import std/os

let pc = paramCount()

var runtime = newEnv()

if pc > 0:
  let arg1 = paramStr 1
  case arg1:
    of "-i":
      runtime.runRepl()
    else:
      if fileExists arg1:
        runtime.doFile arg1
      else:
        echo "Cannot open file " & arg1



