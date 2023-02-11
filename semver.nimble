# Package

version       = "1.2.0"
author        = "Euan T"
description   = "Semantic versioning parser for Nim"
license       = "BSD3"

srcDir = "src"

# Dependencies

requires "nim >= 1.0.0"

task docs, "Build documentation":
  exec "nim doc2 --project --index:on -o:docs/ src/semver.nim"
