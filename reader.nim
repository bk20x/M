import std/[sugar, strformat, streams]
import lispobject, lexer
from std/tables import `[]`, `[]=`

type
  Reader* = object
    lexer: MLexr

var parseSexp*: (var Reader) -> owned LispObject


func advance*(p: var Reader) =
  p.lexer.getTok

func expect*(p: var Reader, kind: TokenKind, callsite="") =
  if p.lexer.curTok.kind != kind:
    raise newException(ValueError, fmt"Reader expected TokenKind: {$kind} but got {p.lexer.curTok.kind}")
  p.advance


  
proc parseAtom(p: var Reader): owned LispObject =
  case p.lexer.curTok.kind:
  of tkSym:
    let sym = newSym p.lexer.curTok.sym.name
    p.advance
    if sym.sym.name == "nil": return NIL()
    return sym
  of tkInt:
    let num = newInt p.lexer.curTok.intv
    p.advance
    return num
  of tkFloat:
    let num = newFloat p.lexer.curTok.flt
    p.advance
    return num
  of tkStr:
    let str = newStr p.lexer.curTok.str
    p.advance
    return str
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
  var braceCount = 1
  while braceCount > 0:
    let key = parseSexp(p)
    p.expect tkColon
    let val = parseSexp(p)
    result.table[key] = val
    if p.lexer.curTok.kind == tkLBrace:
      inc braceCount
    if p.lexer.curTok.kind == tkRBrace:
      dec braceCount
    if braceCount > 0:
      p.expect(tkComma, "parseTableLit")
  p.advance
    
  

  
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
