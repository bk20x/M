import std/[strformat, streams, strutils]
import lispobject, lexer
from std/tables import `[]`, `[]=`

type
  Reader* = object
    lexer: MLexr

var parseSexp*: proc(p: var Reader, parsingIndex: bool = false): owned LispObject

func advance*(p: var Reader) =
  p.lexer.getTok

func expect*(p: var Reader; kind: TokenKind; callsite = "";) =
  if p.lexer.curTok.kind != kind:
      raise newException(ValueError, fmt"at {callsite} Reader expected TokenKind: {kind} but got {p.lexer.curTok}")
  p.advance

proc parseIndex(p: var Reader; obj: sink LispObject): owned LispObject =
  result = obj
  
  proc parseIdx(p: var Reader): owned LispObject = 
    let idx = p.parseSexp(true)
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
    

    let touchingNext = p.lexer.buf[p.lexer.bufpos] == '['    
    p.expect(tkRBracket, "parseIndex")
    result = newIndex(result, startIdx, endIdx)
    if touchingNext:
      continue
    else:
      break


proc parseTableLit(p: var Reader): owned LispObject =
  result = newTable()
  result.literal = true
  p.expect tkLBrace 
  if p.lexer.curTok.kind == tkRBrace:
    p.advance
    return result
  while true:
    let key = parseSexp(p)
    p.expect tkColon
    let val = parseSexp(p)
    result.table[key] = val
    if p.lexer.curTok.kind == tkComma:
      p.advance
      if p.lexer.curTok.kind == tkRBrace: break
    elif p.lexer.curTok.kind == tkRBrace: break 
    else:
      raise newException(ValueError, fmt"Expected ',' or '}}' in Table literal but got {p.lexer.curTok}")
  p.expect tkRBrace 

proc parseAtom(p: var Reader; parsingIndex = false): owned LispObject =
  case p.lexer.curTok.kind:
  of tkSym:
    if p.lexer.curTok.sym.name == "nil":
      p.advance
      return NIL()
    var res = newSym p.lexer.curTok.sym.name
    let start = p.lexer.bufpos 
    p.advance
    if p.lexer.curTok.kind == tkLBracket and (p.lexer.bufpos - start == 1): # its only an index if the symbol is touching the bracket
      return p.parseIndex(res)
    while p.lexer.curTok.kind == tkDot:
      if p.lexer.buf[p.lexer.bufpos] == '.':
        break
      p.advance 
      if p.lexer.curTok.kind == tkSym:
        let field = newSym p.lexer.curTok.sym.name
        p.advance 
        res = newFieldAccess(tableSym=res, field=field)
      else:
        raise newException(ValueError, fmt"Reader expected symbol after '.' for FieldAccess but got {p.lexer.curTok}")
    return res
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
    let
      strObj = newStr(p.lexer.curTok.str)
      start  = p.lexer.bufpos
    p.advance
    if p.lexer.curTok.kind == tkLBracket and (p.lexer.bufpos - start == 1): # its only an index if the string is touching the bracket
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
  var l: seq[LispObject]
  while p.lexer.curTok.kind != tkRpar:
    if p.lexer.curTok.kind == tkEof:
      raise newException(ValueError, "Unmatched parenthesis")
    l.add: parseSexp(p)
  p.expect tkRpar
  result = NIL()
  for i in countdown(l.len - 1, 0):
    result = cons(l[i], result)
  return result



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

    
  
  

parseSexp = proc(p: var Reader; parsingIndex = false): owned LispObject =
  case p.lexer.curTok.kind:
  of tkLpar:
    return parseList(p)
  of tkRpar: 
    p.expect tkRpar
    return NIL()
  of tkLBrace:
    return parseTableLit(p)
  of tkLBracket:
    return parseSeqLit(p)
  else:
    return p.parseAtom(parsingIndex)


proc parse*(input: string): owned LispObject =
  var parser: Reader
  initLexer(parser.lexer, newStringStream(input))
  parser.advance
  return parseSexp(parser)




proc readAllSexprs*(filename: string): seq[LispObject] =
  result = @[]
  var s = newFileStream(filename, fmRead)
  if s == nil:
    quit("Could not open file: " & filename)
  var
    buffer = ""
    parenCount = 0
  while not s.atEnd:
    let c = s.readChar()
    case c:
    of '(':
      parenCount += 1
      buffer.add(c)
    of ')':
      parenCount -= 1
      buffer.add(c)
      if parenCount == 0:
        result.add: parse buffer.strip()
        buffer = ""
    of ' ', '\n', '\t':
      if parenCount > 0:
        buffer.add(c)
    else:
      buffer.add(c)
  s.close()
  
