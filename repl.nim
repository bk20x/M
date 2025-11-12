import std/[strformat, rdstdin, tables]
import environment
import reader, lispobject



var env = newEnv()

var
  ln: string
  last: LispObject 

while true:
  try:
    let form = readLineFromStdin("#> ", ln)
    if not form: break
    if ln.len > 0:
      if ln == "#interned?":
        for k, v in env.interned:
          echo fmt"{k} := {v}"
      if ln == "**":
        echo fmt"=> {env.eval last}"
      else:
        let
          parsed = parse ln
          result = env.eval parsed
        last   = result 
        echo fmt"=> {result}"
  except CatchableError as e:
    echo fmt"!! Something happened but its okay {(e.name, e.msg)}"
    continue
      
