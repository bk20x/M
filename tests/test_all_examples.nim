import m/[environment, m]
import std/[os, unittest]

suite "run tests":
  test "all examples are runnable":
    var interp = newEnv()
    try:
      for f in walkFiles("../examples/*.m"):
        checkpoint("Testing " & f)
        interp.doFile(f)
    except:
      fail()
  

