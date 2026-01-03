# Package

version       = "0.1.0"
author        = "bk20x"
description   = "Lightweight and easily extendable / embeddable Lisp dialect with no VM and deterministic performance"
license       = "BSD-3-Clause"
srcDir        = "src"
bin           = @["m"]


# Dependencies
requires "bigints >= 1.0.0"
requires "nim >= 2.2.6"
