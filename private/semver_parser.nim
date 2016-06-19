## Internal semver parser.

import lexbase
from streams import Stream
from strutils import `%`, parseInt

const
  decimalPoint: char = '.'
  buildSeparator: char = '-'
  metaDataSeparator: char = '+'

type
  TokenKind = enum
    tkInvalid, tkPoint, tkDigit, tkDash, tkPlus, tkEof
  Token = object
    literal: string
    kind: TokenKind
  SemverParser* = object of BaseLexer
    tok: Token
    data: string
    hasFoundStartDigit: bool
  EventKind* = enum
    ekDigit, ekPrerelease, ekBuild, ekEof, ekError
  SemverParserEvent* = object of RootObj
    case kind*: EventKind
    of ekEof: nil
    of ekDigit:
      value*: int
    of ekBuild:
      build*: string
    of ekPrerelease:
      prerelease: string
    of ekError:
      msg*: string

  ParseError = object of Exception

proc errorStr*(p: SemverParser, msg: string): string =
  ## returns a properly formated error message containing current line and
  ## column information.
  result = `%`("($1, $2) Error: $3",
               [$p.linenumber, $getColNumber(p, p.bufpos), msg])

proc rawGetTok(p: var SemverParser, tok: var Token) {.gcsafe.}

proc open*(p: var SemverParser, input: Stream) =
  lexbase.open(p, input)
  p.tok.kind = tkInvalid
  p.tok.literal = ""
  p.hasFoundStartDigit = false
  rawGetTok(p, p.tok)

proc close*(p: var SemverParser) =
  lexbase.close(p)

proc getDigit(p: var SemverParser, tok: var Token): SemverParserEvent =
  ## Read a digit value, up to a point or other separator.
  result.kind = ekDigit
  var buf = p.buf
  tok.kind = tkDigit
  var ch: char
  while true:
    ch = buf[p.bufpos]
    case ch
    of '0':
      # Can't have leading zeros, error
      tok.kind = tkInvalid
      break
    of '1'..'9':
      add(tok.literal, ch)
      inc(p.bufpos)
    of decimalPoint:
      result.value = parseInt(tok.literal)
      tok.kind = tkPoint
      break
    else:
      tok.kind = tkInvalid
      break

proc rawGetTok(p: var SemverParser, tok: var Token) =
  tok.kind = tkInvalid
  setLen(tok.literal, 0)
  case p.buf[p.bufpos]
  of '0'..'9':
    tok.kind = tkDigit
    tok.literal = tok.literal & p.buf[p.bufpos]
    p.hasFoundStartDigit = true
    inc(p.bufpos)
  of decimalPoint:
    tok.kind = tkPoint
    inc(p.bufpos)
    tok.literal = "."
    if not p.hasFoundStartDigit:
      raise newException(ParseError, "Version must start with a digit")
  of buildSeparator:
    echo "BUILD"
    inc(p.bufPos)
    # TODO: getBuild
  of metaDataSeparator:
    echo "METADATA"
    inc(p.bufpos)
  of lexbase.EndOfFile:
    tok.kind = tkEof
    tok.literal = "[EOF]"
  else:
    echo "OTHER"
    inc(p.bufpos)

proc next*(p: var SemverParser): SemverParserEvent =
  case p.tok.kind:
  of tkEof:
    result.kind = ekEof
  of tkDigit:
    result = getDigit(p, p.tok)
  of tkPoint:
    inc(p.bufpos)
    rawGetTok(p, p.tok)
  else:
    result.kind = ekError
    result.msg = errorStr(p, "invalid token: " & p.tok.literal)
    rawGetTok(p, p.tok)
