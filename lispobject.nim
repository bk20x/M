import std/[tables, strutils, hashes]
import bigints
import alien

type
  LispObjectKind* = enum
    Nil, Int, Float, BigInt, Symbol, String, Cons, Builtin, Lambda, Macro, HashTable, AlienObj
    
  SymbolRef* = ref object
    name*: string
  
  BuiltinFn* = proc(args: LispObject): LispObject
               
  Env* = ref object
    interned*     : Table[string, LispObject]
    loadedModules*: Table[string, Table[string, BuiltinFn]]
    parent*       : Env
    ctr*          : int
    
  LispObject* = ref object
    case kind*: LispObjectKind:
      of Symbol:
        sym*: SymbolRef
      of Int:
        intVal*: int
      of Float:
        floatVal*: float
      of BigInt:
        bigNum*: BigInt
      of String:
        str*: string
      of Cons:
        car*, cdr*: LispObject
      of Builtin:
        fun*: BuiltinFn
        name*: string
      of Lambda, Macro:
        params*, body*: LispObject
        closure*: Env
      of HashTable:
        table*: Table[LispObject, LispObject]
      of AlienObj:
        alien*: Alien
      of Nil:
       discard




func T*(): owned LispObject   {.inline.} = LispObject(kind: Symbol, sym: SymbolRef(name: "t"))
func NIL*(): owned LispObject {.inline.} = LispObject(kind: Nil)

func newAlien*(alien: Alien): owned LispObject =
  return LispObject(kind: AlienObj, alien: alien)

func newTable*(): owned LispObject =
  return LispObject(kind: HashTable, table: initTable[LispObject, LispObject]())

func newTable*(table: Table[LispObject, LispObject]): LispObject =
  return LispObject(kind: HashTable, table: table)
  
func newScope*(parent: Env): owned Env =
  return Env(interned: initTable[string, LispObject](), loadedModules: initTable[string, Table[string, BuiltinFn]](), parent: parent, ctr: 0)
  
func newLambda*(env: Env, params, body: LispObject): owned LispObject =
  return LispObject(kind: Lambda, params: params, body: body, closure: env.newScope())
  
func newMacro*(env: Env, params, body: LispObject): owned LispObject =
  return LispObject(kind: Macro, params: params, body: body, closure: env.newScope())
  
func newBuiltin*(fun: BuiltinFn, name: string): owned LispObject {.inline.} =
  return LispObject(kind: Builtin, fun: fun, name: name)
                    
func newSym*(sym: sink string): owned LispObject =
  return LispObject(kind: Symbol, sym: SymbolRef(name: sym))

func newInt*(val: sink int): owned LispObject =
  return LispObject(kind: Int , intVal: val)

func newFloat*(val: sink float): owned LispObject =
  return LispObject(kind: Float, floatVal: val)

func newBigInt*(val: sink int): owned LispObject =
  return LispObject(kind: BigInt, bigNum: initBigInt(val))
  
func newStr*(s: sink string): owned LispObject =
  return LispObject(kind: String, str: s)

func cons*(car, cdr: LispObject): owned LispObject =
  return LispObject(kind: Cons, car: car, cdr: cdr)




func list*(objs: seq[LispObject]): owned LispObject =
  result = NIL()
  for i in countdown(objs.high, 0):
    result = cons(objs[i], result)


func `==`*(a, b: SymbolRef)    : bool   = a.name == b.name
func isNil*(obj: LispObject)   : bool   =
  if obj.kind == Symbol:  obj.sym.name == "nil" else: obj.kind == Nil
func isAtom*(obj: LispObject)  : bool   = obj.kind != Cons
func isSymbol*(obj: LispObject): bool   = obj.kind == Symbol
func isT*(obj: LispObject)     : bool   = obj.kind != Nil



  
func len*(list: LispObject): int =
  if list.isNil:
    return 0
  else:
    return 1 + len(list.cdr)
    
func first*(list: LispObject): owned LispObject =
  if not list.len >= 1: return NIL()
  return list.car

func second*(list: LispObject): owned LispObject =
  if not list.len >= 2: return NIL()
  return list.cdr.car 
  
func third*(list: LispObject): owned LispObject =
  if not list.len >= 3: return NIL()
  return list.cdr.cdr.car

func fourth*(list: LispObject): owned LispObject =
  if not list.len >= 4: return NIL()
  return list.cdr.cdr.cdr.car 

func fifth*(list: LispObject): owned LispObject =
  if not list.len >= 5: return NIL()
  return list.cdr.cdr.cdr.cdr.car

   
import std/strformat
proc `$`*(s: LispObject): string =
  case s.kind:
  of Nil:
    return "NIL"
  of Symbol:
    if s.sym.name == "t": return s.sym.name.toUpper
    return s.sym.name
  of Builtin:
    return fmt"#<Builtin {s.name}>"
  of Lambda:
    return fmt"#<Lambda {s.params} {s.body}>"
  of Macro:
    return fmt"#<Macro {s.params} {s.body}>"
  of HashTable:
    return $s.table
  of AlienObj:
    return fmt"#<{s.alien.tname} {describe s.alien}>"
  of Float:
    result = $s.floatVal
    if result.find('.') == -1:
      result &= ".0"
    return result
  of Int:
    return $s.intVal
  of BigInt:
    return $s.bigNum
  of String:
    return s.str.escape
  of Cons:
    result = "("
    var
      current = s
      first = true

    while not current.isNil and current.kind == Cons:
      if not first:
        result &= " "
      result &= $(current.car) 
      current = current.cdr 
      first = false

    if not current.isNil:
      result &= " . " & $current
    result &= ")"
    
    return result

func toSeq*(list: LispObject): owned seq[LispObject] =
  var current: LispObject = list
  while not current.isNil:
    if current.kind == Cons:
      if not current.car.isNil:
        result.add(current.car)
      current = current.cdr
    else:
      result.add(current)
      break 
      
  return result



proc `==`*(x, y: LispObject): bool =
  if x.kind != y.kind:
    return false
  
  case x.kind
  of Int:
    return x.intVal == y.intVal
  of Float:
    return x.floatVal == y.floatVal
  of String:
    return x.str == y.str
  of Symbol:
    return x.sym.name == y.sym.name
  of BigInt:
    return x.bigNum == y.bigNum
  of Nil: 
    return true
  of Cons:
    var
      currX = x
      currY = y
    while not currX.isNil and not currY.isNil:
      if not (currX.car == currY.car): 
        return false
      currX = currX.cdr
      currY = currY.cdr
    return currX.isNil and currY.isNil    
  of Builtin, Lambda, HashTable, Macro, AlienObj:
    return (cast[pointer](addr x) == cast[pointer](addr y))


func hash*(obj: LispObject): Hash =
  case obj.kind
  of Int:
    result = hash(obj.intVal)
  of Float:
    result = hash(obj.floatVal)
  of String:
    result = hash(obj.str)
  of Symbol:
    if obj.sym.name == "t":
      result = hash(true)
    else:
      result = hash(obj.sym.name)
  of BigInt:
    result = hash(obj.bigNum) 
  of Nil:
    result = hash(false) 
  of Cons:
    var
      h: Hash = 0
      curr = obj
    while not curr.isNil:
      h = h !& hash(curr.car) 
      curr = curr.cdr
    return h
  of Builtin, Lambda, HashTable, Macro, AlienObj:
    return hash(cast[pointer](addr obj)) 
