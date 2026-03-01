import std/[cmdline, os]
import repl, environment, reader, lispobject

proc doFile*(env: var Env, file: string) =
  let sexprs = readAllSexprs file    
  for sexp in sexprs:
    env.eval sexp


template Mmain*(runtime: var Env) =
  let pc = paramCount()
  if pc > 0:
    let arg1 = paramStr(1)
    case arg1:
      of "-i":
        interactive = true
        if pc > 1:
          let withFile = paramStr(2)
          if fileExists withFile:
            echo "Loading " & withFile & "..."
            runtime.doFile(withFile)
          else:
            echo "Cannot open file " & withFile
        runtime.runRepl()
      else:
        let lispArgs = lispobject.newSeq()
        for arg in commandLineParams():
          lispArgs.sequence.add newStr(arg)
        runtime.intern("~args", lispArgs)          
        if fileExists arg1:
          runtime.doFile arg1
        else:
          echo "Cannot open file " & arg1

when isMainModule:
  var runtime = newEnv()
  runtime.Mmain()
