# Package

version       = "1.1.0"
author        = "Euan T"
description   = "Semantic versioning parser for Nim."
license       = "BSD3"

srcDir = "src"

# Dependencies

requires "nim >= 0.14.0"

task tests, "Run all tests":
  exec "nim c -r tests/main.nim"

task docs, "Build documentation":
  exec "nim doc2 --project --index:on -o:docs/ src/semver.nim"
