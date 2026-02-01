import std/[tables, streams]
import ../lispobject
import ../alien



type
  FileStreamObj = ref object of Alien
    stream: FileStream
  StringStreamObj = ref object of Alien
    stream: StringStream


func newFileStreamObj()
