import std/[cmdline, os]
import repl, environment, reader, lispobject



proc doFile*(env: var Env, file: string) =
  let sexprs = readAllSexprs file    
  for sexp in sexprs:
    env.eval sexp


template Mmain*(runtime: var Env) =
  let pc = paramCount()
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

when isMainModule:
  var runtime = newEnv()
  runtime.Mmain()
