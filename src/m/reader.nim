import std/[strformat, streams]
import lispobject, lexer
from std/tables import `[]`, `[]=`

type
  Reader* = object
    lexer: MLexr

var parseSexp*: proc(p: var Reader, parsingIndex: bool = false): owned LispObject

func advance*(p: var Reader) =
  p.lexer.getTok

func expect*(p: var Reader; kind: TokenKind; callsite = "") =
  if p.lexer.curTok.kind != kind:
    raise newException(ValueError, fmt"at {callsite} Reader expected TokenKind: {$kind} but got {p.lexer.curTok.kind}")
  p.advance

proc parseStringIndex(p: var Reader; strObj: sink LispObject): owned LispObject =
  proc parseIdx(p: var Reader): owned LispObject = 
    result = p.parseSexp(true)
    case result.kind
    of Symbol, Int, Cons, FieldAccess: return result
    else: raise newException(ValueError, fmt"Invalid index type: {result.kind}")

  var startIdx, endIdx: LispObject
  p.expect(tkLBracket, "parseStringIndex")
  startIdx = p.parseIdx()
  if p.lexer.curTok.kind == tkDot and p.lexer.buf[p.lexer.bufpos] == '.':
    p.expect(tkDot, "parseStringIndex")
    p.expect(tkDot, "parseStringIndex")
    endIdx = p.parseIdx()
  else:
    endIdx = startIdx
    
  p.expect(tkRBracket, "parseStringIndex")
  return newStringIndex(strObj, startIdx, endIdx)

proc parseAtom(p: var Reader; parsingIndex = false): owned LispObject =
  case p.lexer.curTok.kind:
  of tkSym:
    var res = newSym p.lexer.curTok.sym.name
    p.advance
    if p.lexer.curTok.kind == tkLBracket:
      return p.parseStringIndex(res)
    
    while p.lexer.curTok.kind == tkDot:
      if p.lexer.buf[p.lexer.bufpos] == '.':
        break
      p.advance 
      if p.lexer.curTok.kind == tkSym:
        let field = newSym p.lexer.curTok.sym.name
        p.advance 
        res = newFieldAccess(tableSym=res, field=field)
      else:
        raise newException(ValueError, "Reader expected symbol after '.' for FieldAccess")
    return res
  of tkInt:
    let num = newInt(p.lexer.curTok.intv)
    p.advance
    return num
  of tkFloat:
    let num = newFloat(p.lexer.curTok.flt)
    p.advance
    return num
  of tkStr:
    let strObj = newStr(p.lexer.curTok.str)
    p.advance
    if p.lexer.curTok.kind == tkLBracket:
      return p.parseStringIndex(strObj)
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
    raise newException(ValueError, fmt"Invalid token: {$p.lexer.curTok.kind}")

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
      raise newException(ValueError, "Expected ',' or '}' in table")
  p.expect tkRBrace 

parseSexp = proc(p: var Reader; parsingIndex = false): owned LispObject =
  case p.lexer.curTok.kind:
  of tkLpar: return parseList(p)
  of tkRpar: 
    p.expect tkRpar
    return NIL()
  of tkLBrace: return parseTableLit(p)
  else: return p.parseAtom(parsingIndex)

proc parse*(input: string): owned LispObject =
  var parser: Reader
  initLexer(parser.lexer, newStringStream(input))
  parser.advance
  return parseSexp(parser)
