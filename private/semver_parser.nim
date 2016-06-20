## Internal semver parser.

import lexbase
from streams import Stream
from strutils import `%`, parseInt

import common

const
  decimalPoint*: char = '.'
  buildSeparator*: char = '-'
  metaDataSeparator*: char = '+'

type
  TokenKind = enum
    ## The type of the current token the cursor is on.
    tkInvalid, tkPoint, tkDigit, tkBuildSeparator, tkMetadataSeparator, tkEof
  Token = object
    ## A token has a type and a literal value.
    kind: TokenKind
    literal: string

  EventKind* {.pure.} = enum
    ## The parser returns events on each call to next, each event has an assigned kind.
    digit, prerelease, build, eof, error
  ParserEvent* = object
    case kind*: EventKind
    of EventKind.digit:
      value*: int
    of EventKind.prerelease, EventKind.build:
      content*: string
    of EventKind.error:
      errorMessage*: string
    else: discard

  SemverParser* = object of BaseLexer
    ## Parser used to parse semantic version strings.
    data: string
    currentToken: Token

proc errorStr*(p: SemverParser, msg: string): string = `%`("($1, $2) Error: $3", [$p.linenumber, $getColNumber(p, p.bufpos), msg])
  ## Returns a properly formatted error.

proc rawGetTok(p: var SemverParser, tok: var Token)
  ## Advance the parser, setting the current token to the next token.

proc skipStartCharacters(p: var SemverParser) {.raises: [ParseError].} =
  ## Skip any preceeding '=' and 'v'.
  while true:
    case p.buf[p.bufpos]
    of '=':
      inc(p.bufpos)
    of 'v':
      inc(p.bufpos)
    else: break # Any other (in)valid characters will be handled later.

proc open*(p: var SemverParser, input: Stream) {.raises: [ParseError, Exception].} =
  ## Open the parser, with the given input.
  lexbase.open(p, input)
  p.currentToken.kind = tkInvalid
  p.currentToken.literal = ""
  skipStartCharacters(p)
  rawGetTok(p, p.currentToken)
  if p.currentToken.kind != tkDigit:
    raise newException(ParseError, "Invalid start token: " & p.currentToken.literal)

proc close*(p: var SemverParser) = lexbase.close(p)
  ## Close the parser

proc getDigit(p: var SemverParser, tok: var Token) =
  ## Get a digit from the parser.
  var pos = p.bufpos
  var buf = p.buf
  tok.kind = tkDigit

  var ch: char

  while true:
    ch = buf[pos]
    if ch in '0'..'9':
      add(tok.literal, ch)
      inc(pos)
    else: break
  p.bufpos = pos

proc rawGetTok(p: var SemverParser, tok: var Token) =
  ## Advance the parser, setting the current token to the next token.
  setLen(tok.literal, 0)

  case p.buf[p.bufpos]
  of '0'..'9':
    getDigit(p, tok)
  of decimalPoint:
    tok.kind = tkPoint
    inc(p.bufpos)
    tok.literal = "."
  of buildSeparator:
    tok.kind = tkBuildSeparator
    inc(p.bufpos)
    tok.literal = $buildSeparator
  of metaDataSeparator:
    tok.kind = tkMetadataSeparator
    inc(p.bufpos)
    tok.literal = $metaDataSeparator
  of lexbase.EndOfFile:
    tok.kind = tkEof
    tok.literal = "[EOF]"
  else:
    tok.kind = tkInvalid
    tok.literal = $p.buf[p.bufpos]

proc getDigitValue(p: var SemverParser, tok: var Token): ParserEvent =
  ## Get the current digit value
  if tok.kind == tkDigit:
    result.kind = EventKind.digit
    result.value = parseInt(tok.literal)
    inc(p.bufpos)

  rawGetTok(p, tok)

proc next*(p: var SemverParser): ParserEvent =
  ## Get the next event from the parser.
  case p.currentToken.kind:
  of tkEof:
    result.kind = EventKind.eof
  of tkDigit:
    result = getDigitValue(p, p.currentToken)
  of tkPoint:
    inc(p.bufpos)
    rawGetTok(p, p.currentToken)
  else:
    result.kind = EventKind.error
    result.errorMessage = errorStr(p, "invalid token: " & p.currentToken.literal)
    rawGetTok(p, p.currentToken)
