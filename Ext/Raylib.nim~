import raylib
import ../alien, ../lispobject
import std/[tables, strformat, enumutils]

proc lInitWindow(args: LispObject): LispObject =
  result = NIL()
  if args.len != 3 or not (args.first.kind == Int and args.second.kind == Int and args.third.kind == String):
    raise newException(ValueError,fmt"`initWindow` is of type Int -> Int -> String -> () but got {args}")
  let
    windowWidth  = args.first.intVal
    windowHeight = args.second.intVal
    title        = args.third.str
  initWindow(windowWidth.int32, windowHeight.int32, title)

proc keyOfString(s: string): KeyboardKey =
  for k in KeyboardKey.items:
    if k.symbolName == s:
      return k

proc lKeyDown(args: LispObject): LispObject =
  if args.len != 1 or not (args.first.kind == Symbol):
    raise newException(ValueError, fmt"`isKeyDown` is of type Symbol -> Bool but got {args}")
  let key = keyOfString args.first.sym.name
  return if isKeyDown(key): T() else: NIL()
  
proc lKeyPressed(args: LispObject): LispObject =
  if args.len != 1 or not (args.first.kind == Symbol):
    raise newException(ValueError, fmt"`isKeyPressed` is of type Symbol -> Bool but got {args}")
  let key = keyOfString args.first.sym.name
  return if isKeyPressed(key): T() else: NIL()
    
proc lWindowShouldClose(args: LispObject): LispObject =
  return if windowShouldClose(): T() else: NIL()

proc lBeginDrawing(args: LispObject): LispObject =
  result = NIL()
  beginDrawing()

proc lEndDrawing(args: LispObject): LispObject =
  result = NIL()
  endDrawing()
  
proc lCloseWindow(args: LispObject): LispObject =
  result = NIL()
  closeWindow()

proc lSetTargetFps(args: LispObject): LispObject =
  result = NIL()
  if args.len != 1 or not (args.first.kind == Int):
    raise newException(ValueError, fmt"`setTargetFps` is of type Int -> () but got {args}")
  setTargetFps(args.first.intVal.int32)

proc lClearBackground(args: LispObject): LispObject =
  result = NIL()
  if args.len != 4 or not (args.first.kind == Int and args.second.kind == Int and args.third.kind == Int and args.fourth.kind == Int):
    raise newException(ValueError, fmt"`clearBackground` is of type Int -> Int -> Int -> Int -> () but got {args}")
  let
    r = args.first.intVal.uint8
    g = args.second.intVal.uint8
    b = args.third.intVal.uint8
    a = args.fourth.intVal.uint8
  clearBackground(Color(r: r, g: g, b: b, a: a))

proc drawRectangle(args: LispObject): LispObject =
  result = NIL()
  let
    x       = args.first.floatVal
    y       = args.second.floatVal
    width   = args.third.floatVal
    height  = args.fourth.floatVal
    color   = args.fifth  
  drawRectangle(x.int32, y.int32, width.int32, height.int32, Color(r: color.first.intVal.uint8, g: color.second.intVal.uint8, b: color.third.intVal.uint8, a: color.fourth.intVal.uint8))


proc ldrawText(args: LispObject): LispObject =
  result = NIL()
  let
    text   = args.first.str
    x      = if args.second.kind == Float: args.second.floatVal else: args.second.intVal.float
    y      = if args.third.kind == Float: args.third.floatVal else: args.third.intVal.float
    size   = if args.fourth.kind == Float: args.fourth.floatVal else: args.fourth.intVal.float 
    color  = args.fifth
  if color.isNil:
    drawText(text, x.int32, y.int32, size.int32,  Black)
  else:
    drawText(text, x.int32, y.int32, size.int32,  Color(r: color.first.intVal.uint8, g: color.second.intVal.uint8, b: color.third.intVal.uint8, a: color.fourth.intVal.uint8))
  
proc getDeltaTime(args: LispObject): LispObject =
  return newFloat(getFrameTime())
const
  Module* = toTable {
    "initWindow"        : BuiltinFn lInitWindow,
    "windowShouldClose" : BuiltinFn lWindowShouldClose,
    "beginDrawing"      : BuiltinFn lBeginDrawing,
    "endDrawing"        : BuiltinFn lEndDrawing,
    "closeWindow"       : BuiltinFn lCloseWindow,
    "setTargetFps"      : BuiltinFn lSetTargetFps,
    "clearBackground"   : BuiltinFn lClearBackground,
    "isKeyPressed"      : BuiltinFn lKeyPressed,
    "isKeyDown"         : BuiltinFn lKeyDown,
    "drawRectangle"     : BuiltinFn Raylib.drawRectangle,
    "getDeltaTime"      : BuiltinFn getDeltaTime,
    "drawText"          : BuiltinFn lDrawText



  }
