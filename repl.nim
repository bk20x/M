import std/[strformat, rdstdin]
import lispobject, environment
import reader



var env = newEnv()

var ln: string
while true:
  let form = readLineFromStdin("#> ", ln)
  if not form: break
  if ln.len > 0:
    let
      parsed = parse ln
      result = env.eval parsed
    echo fmt"=> {result}"
