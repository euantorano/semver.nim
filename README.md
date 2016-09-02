# semver.nim ![Build Status](https://api.travis-ci.org/euantorano/semver.nim.svg)

[Semantic versioning](http://semver.org/) parser for Nim.

Allows the parsing of version strings into objects and the comparing of version objects.

## Installation

```
nimble install semver
```

## Usage

```nim
import semver

let version = newVersion(1, 2, 3)
let usersVersion = parseVersion("v1.2.4-alpha") # Version(major: 1, minor: 2, path: 4, build: "alpha", metadata: "")

check usersVersion > version # true
check usersVersion == version # false
```

When parsing versions, the module will automatically ignore any receeding "=v" or "v", allowing it to work with user submitted versions for packages.

## TODO

This module is mostly complete, but the comparsion of verisons doesn't currently fully comply with the `semver` specification. At the minute, the build tag is ignored when doing comparisons (except for when checking if equal, in which case it is simply compared for equality). According to the specification, the build tag should be examined as follows:

>Precedence for two pre-release versions with the same major, minor, and patch version MUST be determined by comparing each dot separated identifier from left to right until a difference is found as follows: identifiers consisting of only digits are compared numerically and identifiers with letters or hyphens are compared lexically in ASCII sort order. Numeric identifiers always have lower precedence than non-numeric identifiers. A larger set of pre-release fields has a higher precedence than a smaller set, if all of the preceding identifiers are equal. Example: 1.0.0-alpha < 1.0.0-alpha.1 < 1.0.0-alpha.beta < 1.0.0-beta < 1.0.0-beta.2 < 1.0.0-beta.11 < 1.0.0-rc.1 < 1.0.0.
