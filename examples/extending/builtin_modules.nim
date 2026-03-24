import m/[environment, lispobject, reader, m]
import std/[tables, strformat]


var toplevel = newEnv()

proc nimHello (args: LispObject): LispObject =
  result = NIL() ## always remember to set the result, no param checks required because we arent using any.
  echo "Hello From my custom builtin!"


proc rangeOf (args: LispObject): LispObject =
  if args.len != 2 or not (args.first.kind == Int and args.second.kind == Int):
    raise newException(ValueError, fmt"rangeOf is of type Int -> Int -> Seq[Int] but got {args}") ## catchable in M with `safe` special form
  result = lispobject.newSeq()
  for x in args.first.intVal..args.second.intVal:
    result.sequence.add newInt(x)
  return result


const Module = toTable {
  "hello"   : BuiltinFn nimHello,
  "rangeOf" : BuiltinFn rangeOf
}

toplevel.registerModule("MyModule", Module) ## ready to: "(open MyModule)" and call any builtins from inside


Mmain(toplevel) ## same entrypoint as the M binary from Nimble. can run './builtin_modules filename' or './builtin_modules -i' for repl
