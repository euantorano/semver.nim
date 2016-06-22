# Package

version       = "1.0.0"
author        = "Euan T"
description   = "Semantic versioning parser for Nim."
license       = "BSD3"

# Dependencies

requires "nim >= 0.14.0"

task tests, "Run all tests":
  exec "nim c -r tests/semver_tests.nim"
