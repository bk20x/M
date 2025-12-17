import std/[tables, strformat]
import ../lispobject





proc makeTable(args: LispObject): LispObject =
  return lispobject.newTable()

proc getHash(args: LispObject): LispObject =
  if args.len != 2 or not (args.second.kind == HashTable):
    raise newException(ValueError, fmt"`getHash` is of type T -> Table -> T but got {args}")
  let
    hashKey = args.first  
    table   = args.second
  return table.table.getOrDefault(hashKey, NIL())

proc putHash(args: LispObject): LispObject =
  if args.len != 3 or not (args.third.kind == HashTable):
    raise newException(ValueError, fmt"`putHash` is of type T -> T -> Table -> T but got {args}")
  let
    hash  = args.first
    val   = args.second
  var tableRef = args.third
  tableRef.table[hash] = val
  return hash

proc tableKeys(args: LispObject): LispObject =
  if args.len != 1 or not (args.first.kind == HashTable):
    raise newException(ValueError, fmt"`tableKeys` is of type Table -> T list but got {args}")
  let tableRef = args.first
  var keys: seq[LispObject]
  for k in tableRef.table.keys:
    keys.add: k
  return keys.list

proc tableValues(args: LispObject): LispObject =
  if args.len != 1 or not (args.first.kind == HashTable):
    raise newException(ValueError, fmt"`tableValues` is of type Table -> T list but got {args}")
  let table = args.first
  var values: seq[LispObject]
  for v in table.table.values:
    values.add: v
  return values.list

proc hasKey(args: LispObject): LispObject =
  if args.len != 2 or not (args.second.kind == HashTable):
    raise newException(ValueError, fmt"`hasKey` is of type T -> Table -> Bool but got {args}")
  let
    key   = args.first
    table = args.second
  return if table.table.hasKey key: T() else: NIL()

proc delete(args: LispObject): LispObject =
  if args.len != 2 or not (args.second.kind == HashTable):
    raise newException(ValueError, fmt"`rmkey` is of type T -> Table -> Bool but got {args}")
  let
    key    = args.first
    table  = args.second
  let exists =  table.table.hasKey(key)
  table.table.del(key)
  return if exists: T() else: NIL()
const
  Module* = toTable {
    "makeTable"  : BuiltinFn makeTable,
    "getHash"    : BuiltinFn getHash,
    "putHash"    : BuiltinFn putHash,
    "tableKeys"  : BuiltinFn tableKeys,
    "tableValues": BuiltinFn tableValues,
    "hasKey"     : BuiltinFn hasKey,
    "rmkey"      : BuiltinFn delete
  }
