import std/[sugar, strformat, streams]
import lispobject, lexer


type
  Reader* = object
    lexer: MLexr


proc advance*(p: var Reader) =
  p.lexer.getTok

proc expect*(p: var Reader, kind: TokenKind) =
  if p.lexer.curTok.kind != kind:
    raise newException(ValueError, fmt"Expected {$kind} but got {$p.lexer.curTok.kind}")
  p.advance


var parseSexp*: (var Reader) -> LispObject

proc parseAtom*(p: var Reader): LispObject =
  case p.lexer.curTok.kind:
  of tkSym:
    let sym = newSym p.lexer.curTok.sym.name
    p.advance
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
  of tkEof:
    raise newException(ValueError, "Unexpected end of token stream")
  else:
    raise newException(ValueError, fmt"Invalid token kind for atom: {$p.lexer.curTok.kind}")
    
proc parseList*(p: var Reader): LispObject =
  p.expect tkLpar 
  result = NIL() 

  var l: seq[LispObject]
  while p.lexer.curTok.kind != tkRpar:
    if p.lexer.curTok.kind == tkEof:
      raise newException(ValueError, "Unclosed list at end of input")
    l.add: parseSexp(p)
    
  p.expect tkRpar
  for i in countdown(l.len - 1, 0):
    result = cons(l[i], result)
    
  return result

parseSexp = proc(p: var Reader): LispObject =
  case p.lexer.curTok.kind:
  of tkLpar:
    return parseList(p)
  of tkRpar: 
    p.expect tkRpar
    return NIL()
  else:
    return parseAtom(p)
        
      
          
      
proc parse*(input: string): LispObject =
  var
    parser: Reader
    inputstrm = newStringStream(input)
    lexer: MLexr
  initLexer(lexer, inputstrm)
  parser.lexer = lexer
  parser.advance
  return parseSexp parser
