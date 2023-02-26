# semver.nim

[Semantic versioning](http://semver.org/) parser for Nim.

Allows the parsing of version strings into objects and the comparing of version objects.

## Installation

```
nimble install semver
```

Or add the following to your .nimble file:

```
# Dependencies

requires "semver >= 1.2.0"
```

## Usage

```nim
import semver

let version = newVersion(1, 2, 3)
let usersVersion = parseVersion("v1.2.4-alpha") # Version(major: 1, minor: 2, patch: 4, build: "alpha", metadata: "")

check usersVersion > version # true
check usersVersion == version # false
```

When parsing versions, the module will automatically ignore any proceeding "=v" or "v", allowing it to work with user submitted versions for packages.
