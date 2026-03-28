import std/[os, unittest]
import ../src/m/[environment, m, lispobject] 

suite "run tests":
  test "all examples are runnable":
    var interp = newEnv()
    interp.intern("~args", lispobject.newSeq())
    let 
        testDir = currentSourcePath().parentDir()
        exampleDir = testDir / "../examples"
    setCurrentDir(exampleDir)    
    for f in walkFiles("*.m"):
      let fileName = f.extractFilename
      if fileName != "run_all.m":
        checkpoint("Testing " & fileName)
        try:
          interp.doFile(fileName)
        except CatchableError as e:
          echo "Failed on: ", fileName, " with error: ", e.msg
          fail()
