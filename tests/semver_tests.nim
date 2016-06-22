import semver, unittest

suite "semver tests":
  test "create version with negative":
    try:
      discard newVersion(1, -1, 0)
      check false
    except InvalidVersionError:
      check true

  test "parse simple version":
    let str = "v1.0.0"
    let version = parseVersion(str)
    check version.major == 1
    check version.minor == 0
    check version.patch == 0

  test "parse simple full version":
    let str = "v1.20.3"
    let version = parseVersion(str)
    check version.major == 1
    check version.minor == 20
    check version.patch == 3

  test "parse too many integer values":
    let str = "1.0.0.0"
    try:
      discard parseVersion(str)
      check false
    except ParseError:
      check getCurrentExceptionMsg() == "Too many integer values in version: 3"

  test "parse too few integer values":
    let str = "1.0"
    try:
      discard parseVersion(str)
      check false
    except ParseError:
      check getCurrentExceptionMsg() == "Not enough integer values in version"

  test "parse with leading zeros":
    let str = "01.0.0"
    try:
      discard parseVersion(str)
      check false
    except ParseError:
      check getCurrentExceptionMsg() == "(1, 2) Error: Version numbers must not contain leading zeros"

  test "parse with build":
    let str = "1.2.3-alpha"
    let ver = parseVersion(str)
    check ver.major == 1
    check ver.minor == 2
    check ver.patch == 3
    check ver.build == "alpha"

  test "parse with metadata":
    let str = "1.0.0+20130313144700"
    let ver = parseVersion(str)
    check ver.major == 1
    check ver.minor == 0
    check ver.patch == 0
    check ver.build == ""
    check ver.metadata == "20130313144700"

  test "parse with build and metadata":
    let str = "1.0.0-alpha+001"
    let ver = parseVersion(str)
    check ver.major == 1
    check ver.minor == 0
    check ver.patch == 0
    check ver.build == "alpha"
    check ver.metadata == "001"

  test "parse totally invalid version":
    let str = "a.b.c-alpha+001"
    try:
      discard parseVersion(str)
    except ParseError:
      check getCurrentExceptionMsg() == "(1, 0) Error: invalid token: a"
