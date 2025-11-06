import std/tables
import lispobject





proc makeTable(args: LispObject): LispObject =
  return lispobject.newTable()

proc getHash(args: LispObject): LispObject =
  let
    hashKey = args.first  
    table   = args.second
  if table.kind != HashTable:
      raise newException(ValueError, "Second argument to getHash must be a table")
  if hashKey.kind == HashTable: # Add this check
      raise newException(ValueError, "Cannot use a table as a hash key.")

  return table.table.getOrDefault(hashKey, NIL())

proc putHash(args: LispObject): LispObject =
  let
    hash  = args.first
    val   = args.second
  var  
    table = args.third
  table.table[hash] = val
  return hash
  
const
  Module* = toTable {
    "makeTable": BuiltinFn makeTable,
    "getHash"  : BuiltinFn getHash,
    "putHash"  : BuiltinFn putHash

  }
