import std/[strutils, strformat, streams, lexbase]
import lispobject

type
  TokenKind* = enum
    tkSym
    tkFloat,
    tkInt,
    tkStr,
    tkEof,
    tkLpar,    # (
    tkRpar,    # )
    tkDot,     # .
    tkQuote,   # '
    tkBquote,  # `
    tkComma,   # ,
    tkSplice,  # ,@
    tkComment, # ;
    tkColon,   # :
    tkLBrace,  # {
    tkRBrace   # }
    tkLBracket # [
    tkRBracket # ]

  Token* = object
    case kind*: TokenKind:
      of tkSym:   sym*:   SymbolRef
      of tkStr:   str*:   string
      of tkFloat: flt*: float
      of tkInt:   intv*: int
      else: discard

  MLexr* = object of BaseLexer
    filename*: string
    curLine*: string
    curTok*: Token
    

const
  SymbolChars = {'a'..'z', 'A'..'Z', '0'..'9', '*', '+', '-', '!', '?', '_', '>', '<', '$', '|', '=', '@', '`', '^', '/', '~'}

proc initLexer*(lx: var MLexr, input: Stream, filename: string = "") =
  lexbase.open(lx, input)
  lx.filename = filename

func skip*(lx: var MLexr) =
  while lx.bufpos < lx.buf.len and lx.buf[lx.bufpos] in {' ', '\t', '\n', '\r'}:
    inc lx.bufpos


func parseSym*(lx: var MLexr, start: int) =
  while lx.buf[lx.bufpos] in SymbolChars:
    inc lx.bufpos
  let symStr = lx.buf.substr(start, lx.bufpos - 1)
  lx.curTok = Token(kind: tkSym, sym: newSym(symStr).sym)

func parseNumber*(lx: var MLexr, start: int) =
  var 
    pos = start 
    isFloat = false
  
  if lx.buf[pos] in {'+', '-'}:
    inc pos

  while pos < lx.buf.len:
    let c = lx.buf[pos]
    if c.isDigit:
      inc pos
    elif c == '.':
      if pos + 1 < lx.buf.len and lx.buf[pos+1] == '.': # ignore if there is `..` because its StringIndex initializer; see `parseStringIndex` in `reader.nim`
        break 
      isFloat = true
      inc pos
    else:
      break

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
    raise newException(ValueError, fmt"Invalid number: {numStr}")


func parseStr*(lx: var MLexr) =
  var str = ""
  inc lx.bufpos
  while lx.buf[lx.bufpos] != '\0':
    let c = lx.buf[lx.bufpos]
    if c == '"':
      inc lx.bufpos
      break
    elif c == '\\':
      # Found an escape seq
      inc lx.bufpos # Move past the backslash
      let escapedChar = lx.buf[lx.bufpos]
      case escapedChar
      of '"': str.add('"')
      of '\\': str.add('\\')
      of 'n': str.add('\n')
      of 'r': str.add('\r')
      of 't': str.add('\t')
      else:
        str.add(escapedChar)
    else:
      str.add(c)
    inc lx.bufpos 
  if lx.buf[lx.bufpos] == '\0' and lx.buf[lx.bufpos - 1] != '"':
    raise newException(ValueError, fmt"Unterminated string at {lx.bufpos}")
  lx.curTok = Token(kind: tkStr, str: str)

func getTok*(lx: var MLexr) =
  lx.skip()
  let start = lx.bufpos 
  if lx.buf[lx.bufpos] == '\0':
    lx.curTok = Token(kind: tkEof)
    return    
  case lx.buf[lx.bufpos]:
  of '{':
    inc lx.bufpos
    lx.curTok = Token(kind: tkLBrace)
  of '}':
    inc lx.bufpos
    lx.curTok = Token(kind: tkRBrace)
  of '[':
    inc lx.bufpos
    lx.curTok = Token(kind: tkLBracket)
  of ']':
    inc lx.bufpos
    lx.curTok = Token(kind: tkRBracket)
  of ':':
    inc lx.bufpos
    lx.curTok = Token(kind: tkColon)
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
  of ';':
    inc lx.bufpos
    lx.curTok = Token(kind: tkComment)
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
