import std/[strformat, rdstdin, tables, terminal]
import environment, reader, lispobject



var env = newEnv()

var
  ln: string
  last: LispObject


enableTrueColors()
while true:
  try:
    let form = readLineFromStdin("#> ", ln)
    if not form: break
    if ln.len > 0:
      if ln == "#interned?":
        for k, v in env.interned:
          echo fmt"{k} := {v}"
      else:
        let
          parsed = parse ln
          result = env.eval parsed
        last   = result 
        stdout.write("=> "); stdout.styledWriteLine(fgGreen, styleBright,   fmt"{result}")
  except CatchableError as e:
    stdout.styledWriteLine(fgRed, styleBright, fmt"Error: {e.msg}")
    continue
    
disableTrueColors()
stdout.resetAttributes()
