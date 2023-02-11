## Semantic versioning parser for Nim.
##
## Example
## --------
##
## .. code-block::nim
##    import semver
##
##    let minVersion = newVersion(1, 0, 0)
##    let parsedVersion = v"1.23.45"
##
##    if parsedVersion < minVersion:
##      echo "You do not meet the minimum required version"
##    else:
##      echo "You are using a version with the following details: "
##      echo "Major: ", parsedVerison.major
##      echo "Minor: ", parsedVerison.minor
##      echo "Patch Level: ", parsedVerison.patch
##

import strutils, parseutils

type
  Version* = object
    ## Represents a version.
    major*: int
    minor*: int
    patch*: int
    build*: string
    metadata*: string

  InvalidVersionError* = object of ValueError
  ParseError* = object of ValueError


func newVersion*(major, minor, patch: int, build = "", metadata = ""
  ): Version {.raises: [InvalidVersionError].} =

  ## Create a new version using the given major, minor and patch values, with the given build and metadata information.
  ## If the major, minor or patch is negative, an InvalidVersionError is thrown.
  if major < 0 or minor < 0 or patch < 0:
    raise newException(InvalidVersionError,
        "Major, minor and patch must be positive. Got: " &
        $major & ", " & $minor & ", " & $patch)

  Version(
    major: major,
    minor: minor,
    patch: patch,
    build: build,
    metadata: metadata
  )

func `$`*(v: Version): string =
  ## Convert the given version to a string.
  result = $v.major & "." & $v.minor & "." & $v.patch
  if len(v.build) > 0:
    result &= "-" & v.build
  if len(v.metadata) > 0:
    result &= "+" & v.metadata

func parsePositiveNumber(s: string, n, i: var int) =
  var step = parseInt(s, n, i)

  if (s[i] == '0' and step == 1) or (s[i] != '0' and n > 0):
    inc i, step
  else:
    raise newException(ParseError, "invalid number")

func skipChar(s: string, i: var int, ch: char) =
  if i >= s.len:
    raise newException(ParseError, "expected '" & ch & "' but string ends")
  elif s[i] == ch:
    inc i
  else:
    raise newException(ParseError, "expected '" & ch & "' but given")

func parseVersionCore*(s: string, i: var int, v: var Version) =
  parsePositiveNumber(s, v.major, i)
  skipChar s, i, '.'
  parsePositiveNumber(s, v.minor, i)
  skipChar s, i, '.'
  parsePositiveNumber(s, v.patch, i)

func parseDotSeparated*(s: string, i: var int, result: var string,
    boundChars: set[char]) =

  let start = i
  var j = i

  while j != s.len:
    case s[j]
    of Letters, Digits, '-':
      inc j

    of '.':
      if j - i == 1:
        raise newException(ParseError, "invalid character '.'")
      else:
        i = j
        inc j

    elif s[j] in boundChars:
      break

    else:
      raise newException(ParseError, "invalid character: '" & s[j] & "'")

  result = s[start..<j]
  i = j

func parseVersion*(s: string): Version =
  ## Parse the given string `versionString` into a Version.
  ## according to the Backus–Naur Form of https://semver.org/

  if s.len < "0.0.0".len:
    raise newException(ParseError, "minimum string length is violated")

  var i =
    if s[0] == 'v': 1
    elif s[0] == '=' and s[1] == 'v': 2
    else: 0

  parseVersionCore s, i, result

  if i < s.len and s[i] == '-':
    inc i
    parseDotSeparated s, i, result.build, {'+'} + Whitespace

  if i < s.len and s[i] == '+':
    inc i
    parseDotSeparated s, i, result.metadata, Whitespace

  if i < s.len and s[i] notin Whitespace:
    raise newException(ParseError, "expected white-space or OEF")

func v*(s: string): Version = parseVersion s


func isPublicApiStable*(v: Version): bool =
  ## Whether the public API should be considered stable:
  ##
  ##  Major version zero (0.y.z) is for initial development. Anything may change at any time. The public API should not be considered stable.
  result = v.major > 0

func isbuild*(v: Version): bool =
  ## Whether the given version is a pre-release version:
  ##
  ##  A pre-release version MAY be denoted by appending a hyphen and a series of dot separated identifiers immediately following the patch version.
  result = len(v.build) > 0

func isNumeric(s: string): bool =
  result = true

  for c in s:
    if not isDigit(c):
      return false


func compare(v1: Version, v2: Version, ignoreBuild: bool = false): int =
  ## Compare two versions
  ##
  ## -1 == v1 is less than v2
  ## 0 == v1 is equal to v2
  ## 1 == v1 is greater than v2

  let
    cmpMajor = cmp(v1.major, v2.major)
    cmpMinor = cmp(v1.minor, v2.minor)
    cmpPatch = cmp(v1.patch, v2.patch)

  if cmpMajor != 0: cmpMajor
  elif cmpMinor != 0: cmpMinor
  elif cmpPatch != 0: cmpPatch
  elif not ignoreBuild:
    # Comparison if a version has no build versions
    if len(v1.build) == 0 and len(v2.build) == 0: 0
    elif len(v1.build) == 0 and len(v2.build) > 0: +1
    elif len(v1.build) > 0 and len(v2.build) == 0: -1
    else:
      # split build version by dots and compare each identifier
      var
        i = 0
        build1 = split(v1.build, ".")
        build2 = split(v2.build, ".")
        comp: int

      while i < len(build1) and i < len(build2):
        comp =
          if isNumeric(build1[i]) and isNumeric(build2[i]):
            cmp(parseInt(build1[i]), parseInt(build2[i]))
          else:
            cmp(build1[i], build2[i])

        if comp == 0:
          inc i
          continue
        else:
          return comp

        inc i

      # If build versions are the equal but one have further build version
      if i == len(build1) and i == len(build2): 0
      elif i == len(build1) and i < len(build2): -1
      else: +1

  else: 0

func isEqual*(v1: Version, v2: Version, ignoreBuild: bool = false): bool =
  ## Check whether two versions are equal, optionally excluding the build and metadata.
  compare(v1, v2, false) == 0

func isLessThan*(v1: Version, v2: Version): bool =
  ## Check whether v1 is less than v2.
  compare(v1, v2, false) < 0

func isGreaterThan*(v1: Version, v2: Version): bool =
  ## Check whether v1 is greater than v2.
  compare(v1, v2, false) > 0

func `==`*(v1: Version, v2: Version): bool =
  ## Check whether two versions are equal.
  isEqual(v1, v2, false)

func `<`*(v1: Version, v2: Version): bool =
  ## Check whether v1 is less than v2.
  isLessThan(v1, v2)

func `<=`*(v1: Version, v2: Version): bool =
  ## Check whether v1 is less than or equal to v2.
  not isGreaterThan(v2, v1)
