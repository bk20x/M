import std/[tables, strutils]

type
  LispObjectKind* = enum
    Nil, Int, Float, Symbol, String, Cons, Builtin, Lambda
    
  SymbolRef* = ref object
    name*: string
  
  BuiltinFn* = proc(args: LispObject): LispObject
               
  Env* = object
    interned*: Table[string, LispObject]
 
  LispObject* = ref object
    case kind*: LispObjectKind:
      of Symbol:
        sym*: SymbolRef
      of Int:
        intVal*: int
      of Float:
        floatVal*: float
      of String:
        str*: string
      of Cons:
        car*, cdr*: LispObject
      of Builtin:
        fun*: BuiltinFn
        name*: string
      of Lambda:
        params*, body*: LispObject
        closure*: ref Env
      of Nil:
        discard



func T*(): LispObject   {.inline.} = LispObject(kind: Symbol, sym: SymbolRef(name: "t"))
func NIL*(): LispObject {.inline.} = LispObject(kind: Nil)
  
func newLambda*(env: ref Env, params, body: LispObject): LispObject =
  return LispObject(kind: Lambda, params: params, body: body)

func newBuiltin*(fun: BuiltinFn, name: string): owned LispObject {.inline.} =
  return LispObject(kind: Builtin, fun: fun, name: name)
                    
func newSym*(sym: sink string): owned LispObject =
  return LispObject(kind: Symbol, sym: SymbolRef(name: sym))

func newInt*(val: sink int): owned LispObject =
  return LispObject(kind: Int , intVal: val)

func newFloat*(val: sink float): owned LispObject =
  return LispObject(kind: Float, floatVal: val)
  
func newStr*(s: sink string): owned LispObject =
  return LispObject(kind: String, str: s)

func cons*(car, cdr: LispObject): owned LispObject =
  return LispObject(kind: Cons, car: car, cdr: cdr)

func first*(list: LispObject): LispObject =
  return list.car

func second*(list: LispObject): LispObject =
  return list.cdr.car 
  
func third*(list: LispObject): LispObject =
  return list.cdr.cdr.car

func fourth*(list: LispObject): LispObject =
  return list.cdr.cdr.cdr.car 

func fifth*(list: LispObject): LispObject =
  return list.cdr.cdr.cdr.cdr.car



  
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
    
  
import std/strformat
func `$`*(s: LispObject): string = 
  case s.kind:
  of Nil:
    return "NIL"
  of Symbol:
    if s.sym.name == "t": return s.sym.name.toUpper
    return s.sym.name
  of Builtin:
    return fmt"<#BUILTIN {s.name}>"
  of Lambda:
    return fmt"<#LAMBDA {s.params} {s.body}>"
  of Float:
    result = $s.floatVal
    if result.find('.') == -1:
      result &= ".0"
    return result
  of Int:
    return $s.intVal
  of String:
    return s.str.escape
  of Cons:
    result = "("
    var current = s.cdr
    result &= $s.car
    while not current.isNil and current.kind == Cons:
      result &= " " & $current.car
      current = current.cdr

    if not current.isNil:
      result &= " . " & $current
    result &= ")"
    
    return result 
  

    
proc toSeq*(list: LispObject): seq[LispObject] =
  proc collect(obj: LispObject, result: var seq[LispObject]) =
    if obj.isNil:
      return 
    if obj.kind == Cons:
      if not obj.car.isNil:
        result.add: obj.car
    else:
      result.add: obj
    collect(obj.cdr, result) 

  result  = @[]
  collect(list, result)
  return result
