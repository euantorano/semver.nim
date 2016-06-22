## Semantic versioning parser for Nim.

from strutils import strip, Whitespace
from streams import newStringStream

import private/semver_parser
import private/common
export common

const
  VERSION_STRING_TRIM_CHARS: set[char] = Whitespace + {'=', 'v'}

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

proc parseVersion*(s: string): Version {.raises: [InvalidVersionError, Exception].} =
  new result

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
    else: discard

  if numDigits != 3:
    raise newException(ParseError, "Not enough integer values in version")
