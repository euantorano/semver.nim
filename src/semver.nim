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

import strutils, streams

import semver/private/parser, semver/private/errors
export errors

type
  Version* = object
    ## Represents a version.
    major*: int
    minor*: int
    patch*: int
    build*: string
    metadata*: string

proc isPublicApiStable*(v: Version): bool =
  ## Whether the public API should be considered stable:
  ##
  ##  Major version zero (0.y.z) is for initial development. Anything may change at any time. The public API should not be considered stable.
  result = v.major > 0

proc isPrerelease*(v: Version): bool =
  ## Whether the given version is a pre-release version:
  ##
  ##  A pre-release version MAY be denoted by appending a hyphen and a series of dot separated identifiers immediately following the patch version.
  result = len(v.build) > 0

proc newVersion*(major, minor, patch: int, build = "", metadata = ""): Version {.raises: [InvalidVersionError].} =
  ## Create a new version using the given major, minor and patch values, with the given build and metadata information.
  ## If the major, minor or patch is negative, an InvalidVersionError is thrown.
  if major < 0 or minor < 0 or patch < 0:
    raise newException(InvalidVersionError, "Major, minor and patch must be positive. Got: " & $major & ", " & $minor & ", " & $patch)

  result = Version(
    major: major,
    minor: minor,
    patch: patch,
    build: build,
    metadata: metadata
  )

proc parseVersion*(versionString: string): Version {.raises: [ParseError, Exception].} =
  ## Parse the given string `versionString` into a Version.
  result = Version(
    major: 0,
    minor: 0,
    patch: 0,
    build: "",
    metadata: ""
  )

  let stringStream = newStringStream(versionString)
  var parser: SemverParser
  parser.open(stringStream)
  defer: close(parser)

  var numDigits: int = 0

  while true:
    var evt = parser.next()
    case evt.kind
    of EventKind.eof:
      break
    of EventKind.digit:
      case numDigits
      of 0:
        result.major = evt.value
      of 1:
        result.minor = evt.value
      of 2:
        result.patch = evt.value
      else: raise newException(ParseError, "Too many integer values in version: " & $numDigits)
      inc numDigits
    of EventKind.build:
      if len(evt.content) < 1:
        raise newException(ParseError, "Build data should be 1 or more characters long")
      result.build = evt.content
    of EventKind.metadata:
      if len(evt.content) < 1:
        raise newException(ParseError, "Metadata should be 1 or more characters long")
      result.metadata = evt.content
    of EventKind.error:
      raise newException(ParseError, evt.errorMessage)

  if numDigits != 3:
    raise newException(ParseError, "Not enough integer values in version")

template v*(versionString: string): Version =
  ## Parse the given string `versionString` into a Version.
  ##
  ## This is a shortcut for the `parseVersion` function.
  parseVersion(versionString)

proc `$`*(v: Version): string =
  ## Convert the given version to a string.
  result = $v.major & "." & $v.minor & "." & $v.patch
  if len(v.build) > 0:
    result &= "-" & v.build
  if len(v.metadata) > 0:
    result &= "+" & v.metadata

proc isNumeric(s: string): bool =
  result = true

  for c in s:
    if not isDigit(c):
      return false

proc compare(v1: Version, v2: Version, ignoreBuild: bool = false): int =
  ## Compare two versions
  ##
  ## -1 == v1 is less than v2
  ## 0 == v1 is equal to v2
  ## 1 == v1 is greater than v2

  let cmpMajor = cmp(v1.major, v2.major)
  let cmpMinor = cmp(v1.minor, v2.minor)
  let cmpPatch = cmp(v1.patch, v2.patch)

  if cmpMajor != 0:
    return cmpMajor
  if cmpMinor != 0:
    return cmpMinor
  if cmpPatch != 0:
    return cmpPatch

  if not ignoreBuild:
    # Comparison if a version has no prerelease versions
    if len(v1.build) == 0 and len(v2.build) == 0:
      return 0
    elif len(v1.build) == 0 and len(v2.build) > 0:
      return 1
    elif len(v1.build) > 0 and len(v2.build) == 0:
      return -1

    # split build version by dots and compare each identifier
    var
      i = 0
      build1 = split(v1.build, ".")
      build2 = split(v2.build, ".")
      comp: int
    while i < len(build1) and i < len(build2):
      if isNumeric(build1[i]) and isNumeric(build2[i]):
        comp = cmp(parseInt(build1[i]), parseInt(build2[i]))
      else:
        comp = cmp(build1[i], build2[i])
      if comp == 0:
        inc(i)
        continue
      else:
        return comp
      inc(i)

    # If build versions are the equal but one have further build version
    if i == len(build1) and i == len(build2):
      return 0
    elif i == len(build1) and i < len(build2):
      return -1
    else:
      return 1

  return 0

proc isEqual*(v1: Version, v2: Version, ignoreBuild: bool = false): bool =
  ## Check whether two versions are equal, optionally excluding the build and metadata.
  result = (compare(v1, v2, false) == 0)

proc `==`*(v1: Version, v2: Version): bool = isEqual(v1, v2, false)
  ## Check whether two versions are equal.

proc `!=`*(v1: Version, v2: Version): bool = not isEqual(v1, v2, false)
  ## Check whether two versions are not equal.

proc isLessThan*(v1: Version, v2: Version): bool =
  ## Check whether v1 is less than v2.
  result = (compare(v1, v2, false) < 0)

proc isGreaterThan*(v1: Version, v2: Version): bool =
  ## Check whether v1 is greater than v2.
  result = (compare(v1, v2, false) > 0)

proc `>`*(v1: Version, v2: Version): bool = isGreaterThan(v1, v2)
  ## Check whether v1 is greater than v2.

proc `<`*(v1: Version, v2: Version): bool = isLessThan(v1, v2)
  ## Check whether v1 is less than v2.

proc `>=`*(v1: Version, v2: Version): bool =
  ## Check whether v1 is greater than or equal to v2.
  result = isEqual(v1, v2) or isGreaterThan(v1, v2)

proc `<=`*(v1: Version, v2: Version): bool =
  ## Check whether v1 is less than or equal to v2.
  result = isEqual(v1, v2) or isLessThan(v1, v2)
