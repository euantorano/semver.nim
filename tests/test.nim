import semver, unittest, osproc

suite "semver tests":
  test "create version with negative":
    expect InvalidVersionError:
      discard newVersion(1, -1, 0)

  test "parse simple version":
    const str = "v1.0.0"
    let version = parseVersion(str)
    check version.major == 1
    check version.minor == 0
    check version.patch == 0

  test "shortcut version parser":
    let version = v"1.23.45"
    check version.major == 1
    check version.minor == 23
    check version.patch == 45

  test "parse simple full version":
    const str = "v1.20.3"
    let version = parseVersion(str)
    check version.major == 1
    check version.minor == 20
    check version.patch == 3

  test "parse too many integer values":
    const str = "1.0.0.0"
    expect ParseError:
      discard parseVersion(str)

  test "parse too few integer values":
    const str = "1.0"
    expect ParseError:
      discard parseVersion(str)

  test "parse with leading zeros":
    const str = "01.0.0"
    expect ParseError:
      discard parseVersion(str)

  test "parse with build":
    const str = "1.2.3-alpha"
    let ver = parseVersion(str)
    check ver.major == 1
    check ver.minor == 2
    check ver.patch == 3
    check ver.build == "alpha"

  test "build has dots":
    let ver = parseVersion("11.2.3-beta+exp.sha.5114f85")
    check ver.major == 11
    check ver.minor == 2
    check ver.patch == 3
    check ver.build == "beta"
    check ver.metadata == "exp.sha.5114f85"

  test "meta has dashes":
    let ver = parseVersion("2015.5.17+21AF26D3----117B344092BD")
    check ver.major == 2015
    check ver.minor == 5
    check ver.patch == 17
    check ver.build == ""
    check ver.metadata == "21AF26D3----117B344092BD"

  test "build & meta has dashes and dots":
    let ver = parseVersion("44.30.11-hey-this.is.build--+meta.-data-.")
    check ver.major == 44
    check ver.minor == 30
    check ver.patch == 11
    check ver.build == "hey-this.is.build--"
    check ver.metadata == "meta.-data-."

  test "parse with metadata":
    const str = "1.0.0+20130313144700"
    let ver = parseVersion(str)
    check ver.major == 1
    check ver.minor == 0
    check ver.patch == 0
    check ver.build == ""
    check ver.metadata == "20130313144700"

  test "parse with build and metadata":
    const str = "1.0.0-alpha+001"
    let ver = parseVersion(str)
    check ver.major == 1
    check ver.minor == 0
    check ver.patch == 0
    check ver.build == "alpha"
    check ver.metadata == "001"

  test "parse totally invalid version":
    const str = "a.b.c-alpha+001"
    expect ParseError:
      discard parseVersion(str)

  test "convert version to string":
    let ver = newVersion(1, 2, 3, "alpha", "001")
    check $ver == "1.2.3-alpha+001"

  test "Check whether two versions are equal":
    let ver1 = newVersion(1, 2, 3, "alpha", "001")
    let ver2 = newVersion(1, 2, 3, "alpha", "001")
    check isEqual(ver1, ver2) == true

  test "Check whether two versions are not equal":
    let ver1 = newVersion(1, 2, 3, "alpha", "001")
    let ver2 = newVersion(1, 2, 4, "alpha", "001")
    check isEqual(ver1, ver2) == false

  test "Check whether two versions are equal with operator":
    let ver1 = newVersion(1, 2, 3, "alpha", "001")
    let ver2 = newVersion(1, 2, 3, "alpha", "001")
    check ver1 == ver2

  test "Check whether two versions are not equal with operator":
    let ver1 = newVersion(1, 2, 3, "alpha", "001")
    let ver2 = newVersion(1, 2, 4, "alpha", "001")
    check ver1 != ver2

  test "Check whether version 1 is greater than version 2":
    let ver1 = newVersion(1, 2, 4, "alpha", "001")
    let ver2 = newVersion(1, 2, 3, "alpha", "001")
    check isGreaterThan(ver1, ver2)

  test "Check whether version 1 is less than version 2":
    let ver1 = newVersion(1, 2, 4, "alpha", "001")
    let ver2 = newVersion(1, 2, 6, "alpha", "001")
    check isLessThan(ver1, ver2)

  test "Check whether version 1 is greater than version 2 with operator":
    let ver1 = newVersion(1, 2, 4, "alpha", "001")
    let ver2 = newVersion(1, 2, 3, "alpha", "001")
    check ver1 > ver2

  test "Check whether version 1 is less than version 2 with operator":
    let ver1 = newVersion(1, 2, 4, "alpha", "001")
    let ver2 = newVersion(1, 2, 6, "alpha", "001")
    check ver1 < ver2

  test "Check whether version 1 is greater than or equal to version 2 with operator":
    let ver1 = newVersion(1, 2, 4, "alpha", "001")
    let ver2 = newVersion(1, 2, 4, "alpha", "001")
    check ver1 >= ver2

  test "Check whether version 1 is less than or equal to version 2 with operator":
    let ver1 = newVersion(1, 2, 6, "alpha", "001")
    let ver2 = newVersion(1, 2, 6, "alpha", "001")
    check ver1 <= ver2

  test "semver.org example: 1.0.0-alpha < 1.0.0-alpha.1 < 1.0.0-alpha.beta < 1.0.0-beta < 1.0.0-beta.2 < 1.0.0-beta.11 < 1.0.0-rc.1 < 1.0.0.":
    let ver1 = newVersion(1, 0, 0)
    let ver2 = newVersion(1, 0, 0, "alpha")
    let ver3 = newVersion(1, 0, 0, "alpha.1")
    let ver4 = newVersion(1, 0, 0, "alpha.beta")
    let ver5 = newVersion(1, 0, 0, "beta")
    let ver6 = newVersion(1, 0, 0, "beta.2")
    let ver7 = newVersion(1, 0, 0, "beta.11")
    let ver8 = newVersion(1, 0, 0, "rc.1")
    check ver2 < ver3
    check ver3 < ver4
    check ver4 < ver5
    check ver5 < ver6
    check ver6 < ver7
    check ver7 < ver8
    check ver8 < ver1

suite "issues":
  test "#3 `node -v`":
    let (output, _) = execCmdEx "node -v"
    let currentNodeVersion = parseVersion(output)
    echo "Node: " & $currentNodeVersion
