import std/tables
import lispobject





proc makeTable(args: LispObject): LispObject =
  return lispobject.newTable()

func getHash(args: LispObject): LispObject =
  let
    hashKey = args.first  
    table   = args.second
  if table.kind != HashTable:
      raise newException(ValueError, "Second argument to getHash must be a table")
  return table.table.getOrDefault(hashKey, NIL())

func putHash(args: LispObject): LispObject =
  let
    hash  = args.first
    val   = args.second
  var  
    table = args.third
  table.table[hash] = val
  return hash

func tableKeys(args: LispObject): LispObject =
  let
    table = args.first
  var
    keys: seq[LispObject]
  for k in table.table.keys:
    keys.add: k
  return keys.list

func tableValues(args: LispObject): LispObject =
  let
    table = args.first
  var
    values: seq[LispObject]
  for v in table.table.values:
    values.add: v
  return values.list
  
const
  Module* = toTable {
    "makeTable"  : BuiltinFn makeTable,
    "getHash"    : BuiltinFn getHash,
    "putHash"    : BuiltinFn putHash,
    "tableKeys"  : BuiltinFn tableKeys,
    "tableValues": BuiltinFn tableValues
  }
