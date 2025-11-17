import lispobject, alien
import std/[json, strformat, tables, sequtils]


type
  JsonObject* = ref object of Alien
    data*: JsonNode

method describe*(a: JsonObject): string = $a.data
  
func newJsonObject(data: JsonNode): owned JsonObject {.inline.} =
  return JsonObject(tname: "JsonObject", data: data)

proc parseFile(args: LispObject): LispObject =
  result = NIL()
  if not args.len == 1 or not (args.first.kind == String):
    raise newException(ValueError, fmt"`parseFile` is of type String -> JsonObject but got {args}")
  let
    filename = args.first.str
    parsed   = parseFile(filename)
  return newAlien newJsonObject(parsed)

proc parseJson(args: LispObject): LispObject =
  result = NIL()
  if not args.len == 1 or not (args.first.kind == String):
    raise newException(ValueError, fmt"`parseJson` is of type String -> JsonObject but got {args}")
  let
    jsonStr = args.first.str
    parsed  = parseJson(jsonStr)
  return newAlien newJsonObject(parsed)
    
proc jsonToList(args: LispObject): LispObject =
  result = NIL()
  if not args.len == 1 or not (args.first.kind == AlienObj):
    raise newException(ValueError, fmt"`listJson` is of type JsonObject !JArray! -> JsonObject list but got {args}")
  let obj = JsonObject(args.first.alien)
  if obj.data.kind != JArray:
    raise newException(ValueError, fmt"`listJson` expects a JsonArray")
  return (obj.data.elems.map do (elem: JsonNode) -> LispObject: newAlien newJsonObject(elem)).list
    
    
proc unbox(args: LispObject): LispObject =
  result = NIL()
  if not args.len == 1 or not (args.first.kind == AlienObj):
    raise newException(ValueError, fmt"`unbox` is of type JsonObject !∉ {{JObject, JArray}}! -> T but got {args}")
  let obj = JsonObject(args.first.alien)    
  case obj.data.kind:
  of JObject, JArray:
    raise newException(ValueError, fmt"`unbox` only works on primitive types or null")
  of JInt:
    return newInt(obj.data.num)
  of JFloat:
    return newFloat(obj.data.fnum)
  of JString:
    return newStr(obj.data.str)
  of JBool:
    return if obj.data.bval: T() else: NIL()
  of JNull:
    return NIL()
    
proc nodeKind(args: LispObject): LispObject =
  result = NIL()
  if not args.len == 1 or not (args.first.kind == AlienObj):
    raise newException(ValueError, fmt"`nodeKind` is of type JsonObject -> Symbol but got {args}")
  let obj = JsonObject(args.first.alien)
  return newSym($obj.data.kind)
    
proc toTable(args: LispObject): LispObject =
  result = NIL()
  var table: Table[LispObject, LispObject]
  if not args.len == 1 or not (args.first.kind == AlienObj):
    raise newException(ValueError, fmt"`toTable` is of type JsonObject !JObject! -> HashTable but got {args}")
  let obj = JsonObject(args.first.alien)
  if not (obj.data.kind == JObject):
    raise newException(ValueError, fmt"for `toTable` jsonKind for argument must be `JObject`")
  for key, field in obj.data.fields:
    table[newStr key] = newAlien(newJsonObject field)
  return lispobject.newTable(table)
    

proc field(args: LispObject): LispObject =
  result = NIL()
  if not args.len == 2 or not (args.first.kind == String and args.second.kind == AlienObj):
    raise newException(ValueError, fmt"`field` is of type String -> JsonObject -> JsonObject but got {args}")
  let
    key = args.first.str
    obj = JsonObject(args.second.alien)
  if not (obj.data.kind == JObject):
    raise newException(ValueError, "`field` expects a JsonObject of Kind JObject")
  return if obj.data.contains(key): newAlien(newJsonObject(obj.data[key])) else: NIL()
  
const
  Module* = toTable {
    "parseFile": BuiltinFn Json.parseFile,
    "parseJson": BuiltinFn Json.parseJson,
    "listJson" : BuiltinFn Json.jsonToList,
    "unbox"    : BuiltinFn Json.unbox,
    "field"    : BuiltinFn Json.field,
    "jsonKind" : BuiltinFn Json.nodeKind,
    "toTable"  : BuiltinFn Json.toTable
  }


func `$`*(o: JsonObject): string = $o.data
