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
    let str = "v1.2.3"
    let version = parseVersion(str)
    check version.major == 1
    check version.minor == 2
    check version.patch == 3

  test "parse too many integer values":
    let str = "1.0.0.0"
    try:
      discard parseVersion(str)
      check false
    except ParseError:
      check true

  test "parse too few integer values":
    let str = "1.0"
    try:
      discard parseVersion(str)
      check false
    except ParseError:
      check true

