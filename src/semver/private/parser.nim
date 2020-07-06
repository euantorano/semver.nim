## Internal semver parser.

import lexbase
from streams import Stream
from strutils import `%`, parseInt

const
  decimalPoint*: char = '.'
  buildSeparator*: char = '-'
  metaDataSeparator*: char = '+'

type
  TokenKind = enum
    ## The type of the current token the cursor is on.
    tkInvalid, tkPoint, tkDigit, tkBuild, tkMetadata, tkEof
  Token = object
    ## A token has a type and a literal value.
    kind: TokenKind
    literal: string

  EventKind* {.pure.} = enum
    ## The parser returns events on each call to next, each event has an assigned kind.
    digit, build, metadata, eof, error
  ParserEvent* = object
    case kind*: EventKind
    of EventKind.digit:
      value*: int
    of EventKind.build, EventKind.metadata:
      content*: string
    of EventKind.error:
      errorMessage*: string
    else: discard

  SemverParser* = object of BaseLexer
    ## Parser used to parse semantic version strings.
    tok: Token

proc errorStr*(p: SemverParser, msg: string): string = `%`("($1, $2) Error: $3", [$p.linenumber, $getColNumber(p, p.bufpos), msg])
  ## Returns a properly formatted error.

proc rawGetTok(p: var SemverParser, tok: var Token)
  ## Advance the parser, setting the current token to the next token.

proc skipStartCharacters(p: var SemverParser) =
  ## Skip any preceeding '=' and 'v'.
  while true:
    case p.buf[p.bufpos]
    of '=', 'v':
      inc(p.bufpos)
    else: break # Any other (in)valid characters will be handled later.

proc open*(p: var SemverParser, input: Stream) =
  ## Open the parser, with the given input.
  lexbase.open(p, input)
  p.tok.kind = tkInvalid
  p.tok.literal = ""
  skipStartCharacters(p)
  rawGetTok(p, p.tok)

proc close*(p: var SemverParser) = lexbase.close(p)
  ## Close the parser

proc getDigit(p: var SemverParser, tok: var Token) =
  ## Get a full digit from the input.
  var pos = p.bufpos
  var buf = p.buf
  tok.kind = tkDigit

  var ch: char
  while true:
    ch = buf[pos]
    if ch in {decimalPoint, buildSeparator, metaDataSeparator, lexBase.EndOfFile}:
      break

    if ch in {'0'..'9'}:
      add(tok.literal, ch)
      inc(pos)
    else:
      tok = Token(
        kind: tkInvalid
      )
      break
  p.bufpos = pos

proc getBuild(p: var SemverParser, tok: var Token) =
  ## Get the full build details from the input.
  var pos = p.bufpos
  var buf = p.buf
  tok.kind = tkBuild

  var ch: char
  while true:
    ch = buf[pos]
    if ch in {metaDataSeparator, lexBase.EndOfFile}:
      break

    if ch in {'0'..'9', 'a'..'z', 'A'..'Z', '-', '.'}:
      add(tok.literal, ch)
      inc(pos)
    else:
      tok.kind = tkInvalid
      break
  p.bufpos = pos

proc getMetadata(p: var SemverParser, tok: var Token) =
  ## Get the full metadata from the input.
  var pos = p.bufpos
  var buf = p.buf
  tok.kind = tkMetadata

  var ch: char
  while true:
    ch = buf[pos]
    if ch in {lexBase.EndOfFile}:
      break

    if ch in {'0'..'9', 'a'..'z', 'A'..'Z', '-', '.'}:
      add(tok.literal, ch)
      inc(pos)
    else:
      tok.kind = tkInvalid
      break
  p.bufpos = pos

proc rawGetTok(p: var SemverParser, tok: var Token) =
  ## Advance the parser, setting the current token to the next token.
  setLen(tok.literal, 0)
  case p.buf[p.bufpos]
  of '0'..'9':
    getDigit(p, tok)
  of decimalPoint:
    tok.kind = tkPoint
    tok.literal = "."
    inc(p.bufpos)
  of buildSeparator:
    inc(p.bufpos)
    getBuild(p, tok)
  of metaDataSeparator:
    inc(p.bufpos)
    getMetadata(p, tok)
  of lexbase.EndOfFile:
    tok.kind = tkEof
    tok.literal = "[EOF]"
  else:
    tok.kind = tkInvalid
    tok.literal = $p.buf[p.bufpos]

proc getDigitValue(p: var SemverParser): ParserEvent =
  ## Get the current digit value
  # Check for preceeding 0s.
  if len(p.tok.literal) > 1 and p.tok.literal[0] == '0':
    result = ParserEvent(
      kind: EventKind.error,
      errorMessage: errorStr(p, "Version numbers must not contain leading zeros")
    )
  else:
    result = ParserEvent(
      kind: EventKind.digit,
      value: parseInt(p.tok.literal)
    )
    rawGetTok(p, p.tok)

proc getBuildValue(p: var SemverParser): ParserEvent =
  ## Get the current digit value
  result = ParserEvent(
    kind: EventKind.build,
    content: p.tok.literal
  )
  rawGetTok(p, p.tok)

proc getMetaDataValue(p: var SemverParser): ParserEvent =
  ## Get the current digit value
  result = ParserEvent(
    kind: EventKind.metadata,
    content: p.tok.literal
  )
  rawGetTok(p, p.tok)

proc next*(p: var SemverParser): ParserEvent =
  ## Get the next event from the parser.
  case p.tok.kind:
  of tkEof:
    result = ParserEvent(
      kind: EventKind.eof
    )
  of tkDigit:
    result = getDigitValue(p)
  of tkBuild:
    result = getBuildValue(p)
  of tkMetadata:
    result = getMetaDataValue(p)
  of tkPoint:
    rawGetTok(p, p.tok)
    result = next(p)
  else:
    result = ParserEvent(
      kind: EventKind.error,
      errorMessage: errorStr(p, "invalid token: " & p.tok.literal)
    )
    rawGetTok(p, p.tok)
