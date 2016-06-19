import semver, unittest

suite "semver tests":
  test "clean nil string":
    let versionString: string = nil
    try:
      let cleaned = cleanVersionString(versionString)
      check false
    except InvalidVersionError:
      check true

  test "clean empty string":
    let versionString = ""
    try:
      let cleaned = cleanVersionString(versionString)
      check false
    except InvalidVersionError:
      check true

  test "clean version with leading chars":
    let versionString = " =v1.0.0"
    let cleaned = cleanVersionString(versionString)
    check cleaned == "1.0.0"

  test "clean version with trailing chars":
    let versionString = "1.0.0    "
    let cleaned = cleanVersionString(versionString)
    check cleaned == "1.0.0"

  test "clean with both leading and trailing":
    let versionString = " =v1.0.0  "
    let cleaned = cleanVersionString(versionString)
    check cleaned == "1.0.0"

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
