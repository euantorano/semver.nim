## Semantic versioning parser for Nim.

from strutils import strip, Whitespace
from streams import newStringStream

import private/semver_parser
import private/common
export common

type
  VersionObj = object
    major*: int
    minor*: int
    patch*: int
    build*: string
    metadata*: string
  Version* = ref VersionObj
    ## Represents a version.
  InvalidVersionError* = object of Exception
    ## Error thrown when a given version string is an invalid version.

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

  # TODO: Check the build is only alphanumeric and dash, and same for metadata
  new result
  result.major = major
  result.minor = minor
  result.patch = patch
  result.build = build
  result.metadata = metadata

proc parseVersion*(s: string): Version {.raises: [ParseError, Exception].} =
  ## Parse the given string `s` into a Version.
  new result
  result.build = ""
  result.metadata = ""

  let stringStream = newStringStream(s)
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
    else:
      echo "OTHER EVENT: " & $evt

  if numDigits != 3:
    raise newException(ParseError, "Not enough integer values in version")

proc `$`*(v: Version): string =
  ## Convert the given version to a string.
  result = $v.major & "." & $v.minor & "." & $v.patch
  if len(v.build) > 0:
    result &= "-" & v.build
  if len(v.metadata) > 0:
    result &= "+" & v.metadata

proc isEqual*(v1: Version, v2: Version, ignoreBuildAndMetadata: bool = false): bool =
  ## Check whether two versions are equal, optionally excluding the build and metadata.
  if v1.major != v2.major:
    return false
  if v1.minor != v2.minor:
    return false
  if v1.patch != v2.patch:
    return false

  if not ignoreBuildAndMetadata:
    if v1.build != v2.build:
      return false
    if v1.metadata != v2.metadata:
      return false

  return true

proc `==`*(v1: Version, v2: Version): bool = isEqual(v1, v2, false)
  ## Check whether two versions are equal.

proc `!=`*(v1: Version, v2: Version): bool = not isEqual(v1, v2, false)
  ## Check whether two versions are not equal.

proc isLessThan*(v1: Version, v2: Version): bool =
  ## Check whether v1 is less than v2.
  ## Note that this currently only does a string comparison on the build tag, and needs expanding as per item #11 of the semver specification.
  if v1.major < v2.major:
    return true
  if v1.minor < v2.minor:
    return true
  if v1.patch < v2.patch:
    return true
  if v1.build < v2.build:
    return true
  return false

proc isGreaterThan*(v1: Version, v2: Version): bool =
  ## Check whether v1 is greater than v2.
  ## Note that this currently only does a string comparison on the build tag, and needs expanding as per item #11 of the semver specification.
  if v1.major > v2.major:
    return true
  if v1.minor > v2.minor:
    return true
  if v1.patch > v2.patch:
    return true
  if v1.build > v2.build:
    return true
  return false

proc `>`*(v1: Version, v2: Version): bool = isGreaterThan(v1, v2)
  ## Check whether v1 is greater than v2.
  ## Note that this currently only does a string comparison on the build tag, and needs expanding as per item #11 of the semver specification.

proc `<`*(v1: Version, v2: Version): bool = isLessThan(v1, v2)
  ## Check whether v1 is less than v2.
  ## Note that this currently only does a string comparison on the build tag, and needs expanding as per item #11 of the semver specification.

proc `>=`*(v1: Version, v2: Version): bool =
  ## Check whether v1 is greater than or equal to v2.
  ## Note that this currently only does a string comparison on the build tag, and needs expanding as per item #11 of the semver specification.
  result = isEqual(v1, v2) or isGreaterThan(v1, v2)

proc `<=`*(v1: Version, v2: Version): bool =
  ## Check whether v1 is less than or equal to v2.
  ## Note that this currently only does a string comparison on the build tag, and needs expanding as per item #11 of the semver specification.
  result = isEqual(v1, v2) or isLessThan(v1, v2)
