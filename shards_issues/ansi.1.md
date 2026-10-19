# ansi.1 — Program Status Protocol (OSC 7501) encoding

**Shard:** `ansi` (`github.com/dsisnero/ansi`)  
**Pinned version:** `0.1.0+commit.4cf33c14` (`shard.lock`)  
**Upstream reference:** `github.com/charmbracelet/x/ansi v0.11.9`
(`ansi/programstatus.go`)  
**Local tracking number:** 1 (no upstream issue filed yet)

## What is missing

The shard has no Program Status Protocol support:

- No `ProgramStatus` / `ProgramState` / `ProgramStatusKind` types.
- No `SetProgramStatus`, `ClearProgramStatus`, `ClearProgramStatusID`, or
  `RequestProgramStatusSupport`.
- None of the protocol validation/sanitisation helpers (id segment rules,
  title/message limits, base64 encoding of free text, progress/kind gating).

A grep for `ProgramStatus|ProgramState|7501` over the pinned shard source
returns no matches.

## Why it is missing

The upstream implementation landed in `charmbracelet/x/ansi v0.11.9`, which is
newer than the commit this port vendors (`4cf33c14`). The Crystal shard's
remote `HEAD` still equals that commit, so the feature has not been ported at
all rather than merely being behind a tag.

## Downstream impact

bubbletea.cr v2.1.0 implements the encoder in
`src/tea/program_status.cr`:

- sequence construction and validation,
- `ClearProgramStatus` / `ClearProgramStatusID`,
- `RequestProgramStatusSupport` (`\e]7501;?\a`),
- base64-encoded title/message with the protocol limits.

This duplicates upstream logic and must be replaced by shard calls when the
API exists. Keeping it local risks drift if the protocol is revised.

## Suggested API

```crystal
module Ansi
  struct ProgramStatus
    property state : ProgramState
    property id : String
    property app : String
    property kind : ProgramStatusKind?
    property progress : Int32
    property has_progress : Bool
    property title : String
    property message : String
  end

  enum ProgramState
    Idle
    Working
    Done
    Blocked
    Error
    Clear
  end

  enum ProgramStatusKind
    Permission
    Question
    Auth
  end

  ClearProgramStatus         = "\e]7501;state=clear\a"
  RequestProgramStatusSupport = "\e]7501;?\a"

  def self.set_program_status(status : ProgramStatus) : String # "" when invalid
  def self.clear_program_status_id(id : String) : String
end
```

### Validation rules to port

- Allowed states: `idle`, `working`, `done`, `blocked`, `error`, `clear`;
  anything else yields an empty sequence.
- `id`: at most 128 bytes, at most 8 `/`-separated segments, each matching
  `[A-Za-z0-9_.+-]{1,32}`; an empty id means the root record.
- `kind` only with `blocked`; `progress` only with `working`/`blocked` when
  `has_progress`, clamped to `0..100`.
- `title`/`message`: control characters collapsed to single spaces, trimmed,
  truncated to 192/2048 bytes on a UTF-8 boundary, then base64-encoded.
- `clear` ignores every other field.

## Verification

The encoder is covered by `spec/program_status_spec.cr` in bubbletea.cr. When
the shard lands this API, delete the local implementation and point the spec at
`Ansi.set_program_status` / `Ansi.clear_program_status_id`.
