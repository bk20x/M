import std/[strformat, rdstdin, terminal]
import environment, reader, lispobject



proc runRepl*(env: var Env) =
  var ln: string
  enableTrueColors()
  while true:
    try:
      let form = readLineFromStdin("#> ", ln)
      if not form: break
      if ln.len > 0:
        let
          parsed = parse ln
          result = env.eval parsed
        stdout.write("=> "); styledEcho(fgGreen, styleBright, fmt"{result}")
    except CatchableError as e:
      styledEcho(fgRed, styleBright, fmt"Error: {e.msg}")
      continue
    disableTrueColors()
    stdout.resetAttributes()
