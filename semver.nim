## Semantic versioning parser for Nim.

from strutils import strip, Whitespace
from streams import newStringStream
import private/semver_parser

const
  VERSION_STRING_TRIM_CHARS: set[char] = Whitespace + {'=', 'v'}

type
  VersionObj = object
    major*: int
    minor*: int
    patch*: int
    prerelease*: string
    build*: string # TODO: Parse metadata
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
  result = len(v.prerelease) > 0

proc cleanVersionString*(version: string): string {.raises: [InvalidVersionError].} =
  ## Clean a provided version string, removing leading and trailing whitespace and leading '=' and 'v' characters.
  if len(version) == 0:
    raise newException(InvalidVersionError, "Version string cannot be empty")

  # Trim whitespace, 'v' and '=' from the start of the version.
  result = version.strip(leading = true, trailing = false, chars = VERSION_STRING_TRIM_CHARS)

  # Trim whitespace from the end of the vesion.
  result = result.strip(leading = false, trailing = true)

proc newVersion*(major, minor, patch: int, prerelease = "", build = ""): Version {.raises: [InvalidVersionError].} =
  ## Create a new version using the given major, minor and patch values, with the given build and metadata information.
  ## If the major, minor or patch is negative, an InvalidVersionError is thrown.
  if major < 0 or minor < 0 or patch < 0:
    raise newException(InvalidVersionError, "Major, minor and patch must be positive. Got: " & $major & ", " & $minor & ", " & $patch)

  # TODO: Check the build is only alphanumeric and dash, and same for metadata
  new result
  result.major = major
  result.minor = minor
  result.patch = patch
  result.prerelease = prerelease
  result.build = build

proc parseVersion*(s: string): Version {.raises: [InvalidVersionError, Exception].} =
  let versionString = cleanVersionString(s)

  new result

  let stringStream = newStringStream(versionString)
  var parser: SemverParser
  parser.open(stringStream)
  defer: close(parser)

  while true:
    var evt = parser.next()
    case evt.kind
    of ekEof:
      break
    of ekDigit:
      echo "DECIMAL: " & $evt.value
    else:
      echo "EVENT: " & $evt
