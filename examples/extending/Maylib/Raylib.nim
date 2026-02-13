import raylib
import std/[tables, strformat]
import m/[lispobject]


proc initWindow(args: LispObject): LispObject =
  if not args.len == 3 or not (
    args.first.kind  == Int and
    args.second.kind == Int and
    args.third.kind  == String
  ):
    raise newException(ValueError, fmt"`initWindow` is of type Int -> Int -> String => Nil but got {args}")
  result = NIL()
  initWindow(args.first.intVal.int32, args.second.intVal.int32, args.third.str)

proc closeWindow(args: LispObject): LispObject =
  result = NIL()
  closeWindow()
  
proc windowShouldClose(args: LispObject): LispObject =
  return if windowShouldClose(): T() else: NIL()

proc setTargetFPS(args: LispObject): LispObject =
  if args.len != 1 or not (args.first.kind == Int):
    raise newException(ValueError, fmt"`setTargetFPS` is of type Int => Nil but got {args}")
  result = NIL()
  setTargetFPS(args.first.intVal.int32)
  
proc beginDrawing(args: LispObject): LispObject =
  result = NIL()
  beginDrawing()

proc endDrawing(args: LispObject): LispObject =
  result = NIL()
  endDrawing()

proc clearBackground(args: LispObject): LispObject =
  if args.len != 1 or not (args.first.kind in {Cons, HashTable}):
    raise newException(ValueError, fmt"`clearBackground` is of type (Cons | Table) => Nil but got {args}")
  result = NIL()
  let
    rgb    = args.first
    color  = if rgb.kind   == Cons:
               Color(r: rgb.first.intVal.uint8,
                     g: rgb.second.intVal.uint8,
                     b: rgb.third.intVal.uint8,
                     a: rgb.fourth.intVal.uint8
               )
             else:
               Color(r: rgb.table[newSym("r")].intVal.uint8,
                     g: rgb.table[newSym("g")].intVal.uint8,
                     b: rgb.table[newSym("b")].intVal.uint8,
                     a: rgb.table[newSym("a")].intVal.uint8
               )
  clearBackground(color)
  
proc drawRectangle(args: LispObject): LispObject =
  if args.len != 5 or not (
    args.first.kind  in {lispobject.Int,  Float} and
    args.second.kind in {lispobject.Int,  Float} and
    args.third.kind  in {lispobject.Int,  Float} and
    args.fourth.kind in {lispobject.Int,  Float} and
    args.fifth.kind  in {Cons, HashTable}
  ):
    raise newException(ValueError, fmt"`drawRectangle` is of type Number -> Number -> Number -> Number -> (Cons | Table) => Nil but got {args}")
  result = NIL()
  let
    x      = if args.first.kind   == Int: args.first.intVal.int32   else: args.first.floatVal.int32
    y      = if args.second.kind  == Int: args.second.intVal.int32  else: args.second.floatVal.int32
    width  = if args.third.kind   == Int: args.third.intVal.int32   else: args.third.floatVal.int32
    height = if args.fourth.kind  == Int: args.fourth.intVal.int32  else: args.fourth.floatVal.int32
    rgb    = args.fifth
    color  = if rgb.kind   == Cons:
               Color(r: rgb.first.intVal.uint8,
                     g: rgb.second.intVal.uint8,
                     b: rgb.third.intVal.uint8,
                     a: rgb.fourth.intVal.uint8
               )
             else:
               Color(r: rgb.table[newSym("r")].intVal.uint8,
                     g: rgb.table[newSym("g")].intVal.uint8,
                     b: rgb.table[newSym("b")].intVal.uint8,
                     a: rgb.table[newSym("a")].intVal.uint8
               )
    
  drawRectangle(x, y, width, height, color)



const Module* = toTable {
  "setTargetFPS"     : BuiltinFn Raylib.setTargetFPS,
  "clearBackground"  : BuiltinFn Raylib.clearBackground,
  "initWindow"       : BuiltinFn Raylib.initWindow,
  "closeWindow"      : BuiltinFn Raylib.closeWindow,
  "windowShouldClose": BuiltinFn Raylib.windowShouldClose,
  "beginDrawing"     : BuiltinFn Raylib.beginDrawing,
  "endDrawing"       : BuiltinFn Raylib.endDrawing,
  "drawRectangle"    : BuiltinFn Raylib.drawRectangle
}
