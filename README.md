# semver.nim ![Build Status](https://api.travis-ci.org/euantorano/semver.nim.svg) [![CircleCI](https://circleci.com/gh/euantorano/semver.nim/tree/master.svg?style=svg)](https://circleci.com/gh/euantorano/semver.nim/tree/master)

[Semantic versioning](http://semver.org/) parser for Nim.

Allows the parsing of version strings into objects and the comparing of version objects.

## Installation

```
nimble install semver
```

Or add the following to your .nimble file:

```
# Dependencies

requires "semver >= 1.1.1"
```

## Usage

```nim
import semver

let version = newVersion(1, 2, 3)
let usersVersion = parseVersion("v1.2.4-alpha") # Version(major: 1, minor: 2, path: 4, build: "alpha", metadata: "")

check usersVersion > version # true
check usersVersion == version # false
```

When parsing versions, the module will automatically ignore any proceeding "=v" or "v", allowing it to work with user submitted versions for packages.
