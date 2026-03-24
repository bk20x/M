import m/[environment, reader, lispobject, m]

var toplevel = newEnv()

## All builtins share this signature
proc nimSquare (args: LispObject): LispObject =
  if args.len != 1 or args.first.kind != Int:
    raise newException(ValueError, "Invalid params for nimSquare: " & $args) # catchable in M with `safe`
  return newInt(args.first.intVal * args.first.intVal)

toplevel.intern("nimSquare", newBuiltin(nimSquare, "nimSquare"))

let 
  code = parse("(nimSquare 5)")
  obj  = toplevel.eval code

assert obj.intVal == 25

Mmain(toplevel) ## this template is the same entrypoint as the M binary. run ./basic_example filename or ./basic_example -i



