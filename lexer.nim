import std/[strutils, strformat, streams, lexbase]
import lispobject

type
  TokenKind* = enum
    tkLpar, tkRpar, tkDot, tkQuote, tkSym, tkFloat,tkInt, tkStr, tkEof, tkBquote, tkComma, tkSplice

  Token* = object
    case kind*: TokenKind:
      of tkSym: sym*:   SymbolRef
      of tkStr: str*:   string
      of tkFloat: flt*: float
      of tkInt:  intv*: int
      else: discard

  MLexr* = object of BaseLexer
    filename*: string
    curLine*: string
    curTok*: Token
    

const
  SymbolChars = {'a'..'z', 'A'..'Z', '0'..'9', '*', '+', '-', '!', '?', '_', '>', '<', '$', '|', '=', '@', ',', '`'}

proc initLexer*(lx: var MLexr, input: Stream, filename: string = "") =
  lexbase.open(lx, input)
  lx.filename = filename

proc skip*(lx: var MLexr) =
  while lx.bufpos < lx.buf.len and lx.buf[lx.bufpos] in {' ', '\t', '\n', '\r'}:
    inc lx.bufpos


proc parseSym*(lx: var MLexr, start: int) =
  while lx.buf[lx.bufpos] in SymbolChars:
    inc lx.bufpos
  let symStr = lx.buf.substr(start, lx.bufpos - 1)
  lx.curTok = Token(kind: tkSym, sym: newSym(symStr).sym)

proc parseNumber*(lx: var MLexr, start: int) =
  var 
    pos = start 
    isFloat = false
    
  if lx.buf[pos] in {'+', '-'}:
    inc pos

  while pos < lx.buf.len and (lx.buf[pos].isDigit or lx.buf[pos] == '.'):
    if lx.buf[pos] == '.':
      isFloat = true
    inc pos
  if pos < lx.buf.len and lx.buf[pos] in {'e', 'E'}:
    isFloat = true
    inc pos
    if pos < lx.buf.len and lx.buf[pos] in {'+', '-'}:
      inc pos
    while pos < lx.buf.len and lx.buf[pos].isDigit:
      inc pos
      
  let numStr = lx.buf.substr(start, pos - 1) 
  lx.bufpos = pos 
  
  try:
    if isFloat:
      lx.curTok = Token(kind: tkFloat, flt: parseFloat(numStr))
    else:
      lx.curTok = Token(kind: tkInt, intv: parseInt(numStr))
  except:
    raise newException(ValueError, fmt"Invalid number: {numStr} at {start}")

proc parseStr*(lx: var MLexr) =
  var str = ""
  inc lx.bufpos
  while true:
    if lx.buf[lx.bufpos] == '"':
      inc lx.bufpos
      break
    if lx.buf[lx.bufpos] == '\0':
      raise newException(ValueError, fmt"Unterminated string at {lx.bufpos}")
    str.add: lx.buf[lx.bufpos]
    inc lx.bufpos
  lx.curTok = Token(kind: tkStr, str: str)

proc getTok*(lx: var MLexr) =
  lx.skip()

 
  let start = lx.bufpos 
  if lx.buf[lx.bufpos] == '\0':
    lx.curTok = Token(kind: tkEof)
    return
    
  case lx.buf[lx.bufpos]:
  of '(':
    inc lx.bufpos
    lx.curTok = Token(kind: tkLpar)
  of ')':
    inc lx.bufpos
    lx.curTok = Token(kind: tkRpar)
  of '.':
    inc lx.bufpos
    lx.curTok = Token(kind: tkDot)
  of '\'':
    inc lx.bufpos
    lx.curTok = Token(kind: tkQuote)
  of '`':
    inc lx.bufpos
    lx.curTok = Token(kind: tkBquote)
  of ',':
    if (lx.bufpos + 1 < lx.buf.len) and (lx.buf[lx.bufpos + 1] == '@'):
      inc lx.bufpos 
      inc lx.bufpos 
      lx.curTok = Token(kind: tkSplice)
    else:
      inc lx.bufpos
      lx.curTok = Token(kind: tkComma)
  of '"':
    lx.parseStr()
  of '0'..'9':
    lx.parseNumber(start) 
  of '+', '-':
    if (lx.bufpos + 1 < lx.buf.len) and lx.buf[lx.bufpos + 1].isDigit:
      lx.parseNumber(start)
    else:
      lx.parseSym(start)
  else:
    if lx.buf[lx.bufpos] in SymbolChars:
      lx.parseSym(start)
    else:
      raise newException(ValueError, fmt"Invalid character: {$lx.buf[lx.bufpos]} at {lx.bufpos}")
