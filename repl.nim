import std/[strformat, rdstdin]
import environment
import reader



var env = newEnv()

var ln: string
while true:
  try:
    let form = readLineFromStdin("#> ", ln)
    if not form: break
    if ln.len > 0:
      let
        parsed = parse ln
        result = env.eval parsed
      echo fmt"=> {result}"
  except CatchableError as e:
    echo fmt"!! Something happened but its okay {(e.name, e.msg)}"
    continue
      
