import std/[strformat, streams]
import lispobject, lexer
from std/tables import `[]`, `[]=`

type
  Reader* = object
    lexer: MLexr
    lastEndPos: int # position of the end of the last token

var parseSexp*: proc(p: var Reader): owned LispObject

func advance*(p: var Reader) =
  p.lastEndPos = p.lexer.bufpos
  p.lexer.getTok

func expect*(p: var Reader; kind: TokenKind; callsite = "";) =
  if p.lexer.curTok.kind != kind:
      raise newException(ValueError, fmt"at {callsite} Reader expected TokenKind: {kind} but got {p.lexer.curTok}")
  p.advance

proc parseFieldAccess(p: var Reader; rootSymbol: LispObject): LispObject =
  result = rootSymbol
  while p.lexer.curTok.kind == tkDot:
    if p.lexer.buf[p.lexer.bufpos] == '.':
      break
    p.advance 
    if p.lexer.curTok.kind == tkSym:
      let field = newSym p.lexer.curTok.sym.name
      p.advance 
      result = newFieldAccess(tableSym=result, field=field)
    else:
      raise newException(ValueError, fmt"Reader expected symbol after '.' for FieldAccess but got {p.lexer.curTok}")
      

proc parseIndex*(p: var Reader; obj: sink LispObject): owned LispObject =
  result = obj
  
  proc parseIdx(p: var Reader): owned LispObject = 
    let idx = p.parseSexp()
    case idx.kind
    of Symbol, Int, Cons, FieldAccess: return idx
    else: raise newException(ValueError, fmt"Invalid object for index {idx}")

  while true:
    p.expect(tkLBracket, "parseIndex")
    let startIdx = p.parseIdx()
    var endIdx: LispObject
    if p.lexer.curTok.kind == tkDot and p.lexer.buf[p.lexer.bufpos] == '.':
      p.expect(tkDot, "parseIndex")
      p.expect(tkDot, "parseIndex")
      endIdx = p.parseIdx()
    else:
      endIdx = startIdx    
    p.expect(tkRBracket, "parseIndex")
    result = newIndex(result, startIdx, endIdx)
    let touchingNext = (p.lexer.bufpos - 1 == p.lastEndPos)
    if p.lexer.curTok.kind == tkLBracket and touchingNext:
      continue
    elif p.lexer.curTok.kind == tkDot and touchingNext: # For deeper indexing/access like xs[0].ys[0].z
      result = p.parseFieldAccess(result)
      if p.lexer.curTok.kind == tkLBracket and (p.lexer.bufpos - 1 == p.lastEndPos):
        continue
      break
    else:
      break

proc parseTableLit(p: var Reader): owned LispObject =
  result = newTable()
  result.literal = true
  p.expect(tkLBrace, "parseTableLit")
  if p.lexer.curTok.kind == tkRBrace:
    p.advance
    return result
  while true:
    let key = parseSexp(p)
    p.expect(tkColon, "parseTableLit")
    let val = parseSexp(p)
    result.table[key] = val
    if p.lexer.curTok.kind == tkComma:
      p.advance
      if p.lexer.curTok.kind == tkRBrace: break
    elif p.lexer.curTok.kind == tkRBrace: break 
    else:
      raise newException(ValueError, fmt"Expected ',' or '}}' in Table literal but got {p.lexer.curTok}")
  p.expect(tkRBrace, "parseTableLit")

proc parseSeqLit(p: var Reader): owned LispObject =
  result = lispobject.newSeq()
  result.literalSeq = true
  p.expect(tkLBracket, callsite="parseSeqLit")
  if p.lexer.curTok.kind == tkRBracket:
    p.advance
    return result
  while true:
    let obj = parseSexp(p)
    result.sequence.add(obj) 
    if p.lexer.curTok.kind == tkComma:
      p.advance
      if p.lexer.curTok.kind == tkRBracket: break
    elif p.lexer.curTok.kind == tkRBracket:
      break 
    else:
      raise newException(ValueError, fmt"Expected ',' or ']' in Seq literal but got {p.lexer.curTok}")
  p.expect tkRBracket
  
proc parseAtom(p: var Reader): owned LispObject =
  case p.lexer.curTok.kind:
  of tkSym:
    if p.lexer.curTok.sym.name == "nil" or p.lexer.curTok.sym.name == "NIL":
      p.advance
      return NIL()
    if p.lexer.curTok.sym.name == "t" or p.lexer.curTok.sym.name == "T":
      p.advance
      return T()
    result = newSym p.lexer.curTok.sym.name
    p.advance
    if p.lexer.curTok.kind == tkLBracket and (p.lexer.bufpos - 1 == p.lastEndPos): # only an index if its physically touching the symbol
      return p.parseIndex(result)
    if p.lexer.curTok.kind == tkDot and (p.lexer.bufpos - 1 == p.lastEndPos): # same with field access
      return p.parseFieldAccess(result)
    return result
  of tkInt:
    let num = newInt(p.lexer.curTok.intv)
    p.advance
    return num
  of tkFloat:
    let num = newFloat(p.lexer.curTok.flt)
    p.advance
    return num
  of tkChar:
    let charObj = newChar(p.lexer.curTok.charVal)
    p.advance
    return charObj
  of tkStr:
    let strObj = newStr(p.lexer.curTok.str)
    p.advance
    if p.lexer.curTok.kind == tkLBracket and (p.lexer.bufpos - 1 == p.lastEndPos):
      return p.parseIndex(strObj)
    return strObj
  of tkBquote:
    p.advance 
    return cons(newSym "backquote", cons(parseSexp(p), NIL()))
  of tkComma: 
    p.advance 
    return cons(newSym "unquote", cons(parseSexp(p), NIL()))
  of tkSplice:
    p.advance 
    return cons(newSym "unquote-splicing", cons(parseSexp(p), NIL()))
  of tkQuote: 
    p.advance
    return cons(newSym "quote", cons(parseSexp(p), NIL()))
  of tkComment:
    p.advance
    return NIL()
  of tkEof:
    raise newException(ValueError, "Unexpected end of token stream")
  else:
    raise newException(ValueError, fmt"Invalid token: {p.lexer.curTok}")

proc parseList(p: var Reader): owned LispObject =
  p.expect tkLpar 
  var
    l: seq[LispObject]
    cdr: owned LispObject = NIL()
  
  while p.lexer.curTok.kind != tkRpar:
    if p.lexer.curTok.kind == tkEof:
      raise newException(ValueError, "Unmatched opening parenthesis")
    
    if p.lexer.curTok.kind == tkDot:
      p.expect tkDot
      cdr = parseSexp(p)
      p.expect tkRpar
      result = cdr
      for i in countdown(l.len - 1, 0):
        result = cons(l[i], result)
      if p.lexer.curTok.kind == tkDot and (p.lexer.bufpos - 1 == p.lastEndPos):
        return p.parseFieldAccess(result)
      return result
    l.add: parseSexp(p)
  p.expect tkRpar 
  result = cdr
  for i in countdown(l.len - 1, 0):
    result = cons(l[i], result)
  if p.lexer.curTok.kind == tkDot and (p.lexer.bufpos - 1 == p.lastEndPos):
    return p.parseFieldAccess(result)



parseSexp = proc(p: var Reader): owned LispObject =
  case p.lexer.curTok.kind:
  of tkLpar:
    return parseList(p)
  of tkRpar: 
    raise newException(ValueError, "stray closing parens")
  of tkLBrace:
    return parseTableLit(p)
  of tkLBracket:
    return parseSeqLit(p)
  else:
    return p.parseAtom()

proc parse*(input: string): owned LispObject =
  var parser: Reader
  initLexer(parser.lexer, newStringStream(input))
  parser.advance
  return parseSexp(parser)



proc readAllSexprs*(filename: string): seq[LispObject] =
  result = @[]
  var stream = newFileStream(filename, fmRead)
  defer: close stream
  if stream == nil:
    raise newException(ValueError, fmt"Could not open file {filename}")
  var parser: Reader
  initLexer(parser.lexer, stream)
  parser.advance
  while parser.lexer.curTok.kind != tkEof:
    result.add parser.parseSexp()  

