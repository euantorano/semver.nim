## Common error types.

type
  InvalidVersionError* = object of Exception
    ## Error thrown when a given version string is an invalid version.
  ParseError* = object of Exception
    ## Error raised if parsing fails. Always includes a message explaining the problem.
