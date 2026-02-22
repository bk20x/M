import std/[httpclient, tables, strformat, sequtils, sugar]
import ../[lispobject, alien]

type
  HttpClientObj = ref object of Alien
    client: HttpClient
    isOpen: bool

template isHttpClient(obj: LispObject): bool =
  (obj.kind == AlienObj and obj.alien.tname == "HttpClient")

proc newHttpClientObj(): HttpClientObj =
  return HttpClientObj(tname: "HttpClient", client: newHttpClient(), isOpen: true)

proc makeHttpClient(args: LispObject): LispObject =
  return newAlien(newHttpClientObj())

proc closeClient(args: LispObject): LispObject =
  if args.len != 1 or not args.first.isHttpClient:
    raise newException(ValueError, fmt"`close` is of type HttpClient -> Nil but got {args}")
  result = NIL()
  let
    clientObj = HttpClientObj(args.first.alien)
    client    = clientObj.client
  if not clientObj.isOpen:
    raise newException(ValueError, fmt"attempt to close already closed HttpClient")
  client.close()
  clientObj.isOpen = false

proc makeRequest(args: LispObject): LispObject =
  if args.len != 3 or not (args.first.isHttpClient and args.second.kind == String and args.third.kind == Symbol):
    raise newException(ValueError, fmt"`request` is of type HttpClient -> String -> Symbol -> HashTable but got {args}")
  let
    client     = HttpClientObj(args.first.alien).client
    url        = args.second.str
    httpMethod = args.third.sym.name
    resp = client.request(url, httpMethod)
  result = lispobject.newTable()
  result.table[newSym "version"] = newStr(resp.version)
  result.table[newSym "status"]  = newStr(resp.status)
  let headers = lispobject.newTable()
  for k, v in resp.headers.table:
    headers.table[newStr k] = lispobject.newSeq(v.map(str => newStr str))
  result.table[newSym "headers"] = headers
    

proc clientGetContent(args: LispObject): LispObject =
  if args.len != 2 or not (args.first.isHttpClient and args.second.kind == String):
    raise newException(ValueError, fmt"`getContent` is of type HttpClient -> String -> String but got {args}")
  let
    client = HttpClientObj(args.first.alien).client
    url    = args.second.str
  return newStr(client.getContent(url))

const
  Module* = toTable {
    "newHttpClient": BuiltinFn makeHttpClient,
    "close"        : BuiltinFn closeClient,
    "request"      : BuiltinFn makeRequest,
    "getContent"   : BuiltinFn clientGetContent
  }
