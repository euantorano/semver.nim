## Common types shared by private parser and public API.

type
  ParseError* = object of Exception
    ## Error raised if parsing fails. Always includes a message explaining the problem.
