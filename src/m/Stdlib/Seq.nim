from std/tables import toTable
from std/strformat import fmt
import ../lispobject




proc length(args: LispObject): LispObject =
  if args.len != 1 or not (args.first.kind == LispObjectKind.Seq):
    raise newException(ValueError, fmt"`length` is of type Seq -> Int but got {args}")
  return newInt(args.first.sequence.len)

proc high(args: LispObject): LispObject =
  if args.len != 1 or not (args.first.kind == LispObjectKind.Seq):
    raise newException(ValueError, fmt"`high` is of type Seq -> Int but got {args}")
  return newInt(args.first.sequence.high)

proc add(args: LispObject): LispObject =
  if args.len != 2 or not (args.first.kind == LispObjectKind.Seq):
    raise newException(ValueError, fmt"`add` is of type Seq -> T | Nil -> Int but got {args}")
  let
    sequence = args.first
    val      = args.second
  sequence.sequence.add(val)
  return newInt(sequence.sequence.high)
    

const Module* = toTable {
  "length": BuiltinFn length,
  "high"  : BuiltinFn high,
  "add"   : BuiltinFn add
}
