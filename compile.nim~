import std/[strutils, streams]
import lispobject
import environment
import reader 

var
  env = newEnv()


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
  
proc doFile(file: string) =
  let sexprs = readAllSexprs file
    
  for sexp in sexprs:
    env.eval sexp


doFile "test.as"
