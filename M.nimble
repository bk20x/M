version       = "0.1.0"
author        = "bk20x"
description   = "Lightweight and easily extendable / embeddable Lisp dialect with no VM and deterministic performance"
license       = "BSD-3-Clause"
installExt    = @["nim"]
srcDir        = "src"
bin           = @["m/m"]
installDirs   = @["src/m"]
installFiles  = @["src/m.nim"]

# Dependencies
requires "bigints >= 1.0.0"
requires "nim >= 2.2.2"
