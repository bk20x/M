import std/[strformat, rdstdin, terminal]
import environment, reader, lispobject


proc runRepl*(env: var Env) =
  var 
    ln:     string
    buffer: string
  enableTrueColors()
  
  while true:
    try:
      let 
        prompt = if buffer.len == 0: "#> " else: ".. "
        ok = readLineFromStdin(prompt, ln)
      if not ok: break

      if buffer.len > 0: buffer.add("\n")
      buffer.add(ln)
      try:
        let 
          parsed = parse buffer
          result = env.eval parsed
        stdout.write("=> "); styledEcho(fgGreen, styleBright, fmt"{result}")
        buffer = "" 
      except ParseError as e:
        if e.kind in {pekUnmatchedParens, pekUnmatchedBraces}:
          continue
        else:
          styledEcho(fgRed, styleBright, fmt"Error: {e.msg}")
          buffer = ""
    except LispException as e:
      styledEcho(fgRed, styleBright, fmt"Error: {e.errMsgOrObject}")
      buffer = ""
      continue
    except CatchableError as e:
      styledEcho(fgRed, styleBright, fmt"Error: {e.msg}")
      buffer = ""
      continue

  disableTrueColors()
  stdout.resetAttributes()
