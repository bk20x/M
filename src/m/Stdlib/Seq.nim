from std/tables import toTable
from std/strformat import fmt
import ../lispobject
import std/sequtils



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
    
proc newSeqWith(args: LispObject): LispObject =
  if args.len != 2 or not (args.first.kind == Int):
    raise newException(ValueError, fmt"`newSeqWith` is of type Int -> T | Nil -> Seq but got {args}")
  let
    length = args.first.intVal
    init   = args.second
  return lispobject.newSeq(newSeqWith(length, init))

proc contains(args: LispObject): LispObject =
  if args.len != 2 or not (args.first.kind == Seq):
    raise newException(ValueError, fmt"`contains` is of type Seq -> T | Nil -> T | Nil but got {args}")
  result = NIL()
  let
    sequence  = args.first.sequence
    obj       = args.second
  for x in sequence:
    if x == obj:
      return T()
    
    
const Module* = toTable {
  "length"     : BuiltinFn length,
  "high"       : BuiltinFn high,
  "add"        : BuiltinFn add,
  "newSeqWith" : BuiltinFn Seq.newSeqWith,
  "contains"   : BuiltinFn contains

}
