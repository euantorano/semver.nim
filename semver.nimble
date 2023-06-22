# Package

version       = "1.2.1"
author        = "Euan T"
description   = "Semantic versioning parser for Nim"
license       = "BSD-3-Clause"

srcDir = "src"

# Dependencies

requires "nim >= 1.0.0"

task docs, "Build documentation":
  exec "nim doc2 --project --index:on -o:docs/ src/semver.nim"
