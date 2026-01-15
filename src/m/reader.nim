import std/[sugar, strformat, streams]
import lispobject, lexer
from std/tables import `[]`, `[]=`

type
  Reader* = object
    lexer: MLexr

var parseSexp*: (var Reader) -> owned LispObject

func advance*(p: var Reader) =
  p.lexer.getTok

func expect*(p: var Reader; kind: TokenKind; callsite="") =
  if p.lexer.curTok.kind != kind:
    raise newException(ValueError, fmt"at {callsite} Reader expected TokenKind: {$kind} but got {p.lexer.curTok.kind}")
  p.advance

proc parseStringIndex(p: var Reader; strObj: sink LispObject): owned LispObject =
  proc parseIdx(p: var Reader): owned LispObject = 
    result = p.parseSexp()
    case result.kind
    of Symbol, Int: # Allowed Kinds
      return result
    else:
      raise newException(ValueError, fmt"parseStringIndex: invalid type for String index {result.kind}")
  var
    startIdx: LispObject
    endIdx: LispObject
  p.expect(tkLBracket, callsite="parseStringIndex")
  startIdx = p.parseIdx()
  p.advance()
  if p.lexer.curTok.kind == tkDot:
    p.expect(tkDot, callsite="parseStringIndex")
    endIdx = p.parseIdx()
  else:
    endIdx = startIdx
  return newStringIndex(strObj, startIdx, endIdx)


    
proc parseAtom(p: var Reader): owned LispObject =
  case p.lexer.curTok.kind:
  of tkSym:
    var res = newSym p.lexer.curTok.sym.name
    p.advance
    # Check for field access w dot notation
    if p.lexer.curTok.kind == tkLBracket:
      return p.parseStringIndex(res)
    while p.lexer.curTok.kind == tkDot:
      p.advance 
      if p.lexer.curTok.kind == tkSym:
        let field = newSym p.lexer.curTok.sym.name
        p.advance 
        res = newFieldAccess(tableSym=res, field=field)
      else:
        raise newException(ValueError, fmt"Reader expected symbol after '.' for FieldAccess but got {p.lexer.curTok.kind}")
    if res.kind == Symbol and res.isNil: 
      return NIL()
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
    let quoted = parseSexp(p) 
    return cons(newSym "backquote", cons(quoted, NIL()))
  of tkComma: 
    p.advance 
    let unquoted = parseSexp(p) 
    return cons(newSym "unquote", cons(unquoted, NIL()))
  of tkSplice:
    p.advance 
    let spliced = parseSexp(p) 
    return cons(newSym "unquote-splicing", cons(spliced, NIL()))
  of tkQuote: 
    p.advance
    let quoted = parseSexp(p)
    return cons(newSym "quote", cons(quoted, NIL()))
  of tkComment:
    p.advance
    return NIL()
  of tkEof:
    raise newException(ValueError, "Unexpected end of token stream")
  else:
    raise newException(ValueError, fmt"Invalid token kind for atom: {$p.lexer.curTok.kind}")

    
proc parseList(p: var Reader): owned LispObject =
  p.expect tkLpar 
  result = NIL() 
  var l: seq[LispObject]
  while p.lexer.curTok.kind != tkRpar:
    if p.lexer.curTok.kind == tkEof:
      raise newException(ValueError, "Unmatched close parenthesis")
    l.add: parseSexp(p)
  p.expect tkRpar
  for i in countdown(l.len - 1, 0):
    result = cons(l[i], result)
  return result


proc parseTableLit(p: var Reader): owned LispObject =
  result = newTable()
  result.literal = true
  p.expect tkLBrace 

  # it's an empty table
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
      if p.lexer.curTok.kind == tkRBrace:
        break
    elif p.lexer.curTok.kind == tkRBrace:
      break 
    else:
      raise newException(ValueError, fmt"Expected ',' or '}}`' after table entry, got  {p.lexer.curTok.kind}")
  p.expect tkRBrace 

  
parseSexp = proc(p: var Reader): owned LispObject =
  case p.lexer.curTok.kind:
  of tkLpar:
    return parseList(p)
  of tkRpar: 
    p.expect tkRpar
    return NIL()
  of tkLBrace:
    return parseTableLit(p)
  else:
    return parseAtom(p)
        
           
proc parse*(input: string): owned LispObject =
  var
    parser: Reader
    inputstrm = newStringStream(input)
    lexer: MLexr
  initLexer(lexer, inputstrm)
  parser.lexer = lexer
  parser.advance
  return parseSexp parser
