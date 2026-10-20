# ultraviolet.1 — Program Status Protocol (OSC 7501) decoder support

**Shard:** `ultraviolet` (`github.com/dsisnero/ultraviolet`)
**Pinned version:** `1.1.1` (`shard.lock`)
**Upstream reference:** `github.com/charmbracelet/ultraviolet` commit
`6b8d4baf91b4` (2026-10-08), used by bubbletea v2.1.0
**Local tracking number:** 1 (no upstream issue filed yet)
**Status:** open — the encoder landed in `ansi`, the decoder event has not

## What is missing

The decoder does not recognise the OSC 7501 support reply:

- No `ProgramStatusSupportEvent` (or equivalent) in the event aliases.
- `Ultraviolet::Decoder` falls through to `UnknownOscEvent` for
  `OSC 7501 ; ?` instead of emitting a typed event.
- No `ProgramStatus` / `ProgramState` / `ProgramStatusKind` aliases (the
  `ansi` shard has the types; ultraviolet has no re-exports).
- No `TerminalScreen#set_program_status` / `#program_status`.

A grep for `ProgramStatus|7501` over the shard source returns no matches at
version 1.1.1.

## What is already resolved

`ansi` now implements the types and encoder (commit `aa47d48`), and this port
uses `Ansi::ProgramStatus`, `Ansi.set_program_status`,
`Ansi.clear_program_status_id`, and `Ansi::RequestProgramStatusSupport`
directly. The former local encoder shim was deleted.

## Why it is missing

The shard tracks Charm's ultraviolet, but it has not ported the decoder half
of the feature yet. Upstream maps OSC 7501 data beginning with `?` to
`ProgramStatusSupportEvent` in `decoder.go`; that code has no Crystal
counterpart.

## Downstream impact

bubbletea.cr keeps a narrow shim in `src/tea/program_status.cr`:

```crystal
module ProgramStatusSupport
  def self.reply?(sequence : String) : Bool
    prefix = "\e]7501;"
    sequence.starts_with?(prefix) && sequence[prefix.size]? == '?'
  end
end
```

`Program#translate_input_event` checks it for `UnknownOscEvent`. This works but
means the whole raw sequence reaches the program, and any future protocol
variation must be parsed by hand.

## Suggested API

```crystal
module Ultraviolet
  alias ProgramStatus = Ansi::ProgramStatus
  alias ProgramState = Ansi::ProgramState
  alias ProgramStatusKind = Ansi::ProgramStatusKind

  ProgramStateIdle    = Ansi::ProgramState::Idle
  ProgramStateWorking = Ansi::ProgramState::Working
  ProgramStateDone    = Ansi::ProgramState::Done
  ProgramStateBlocked = Ansi::ProgramState::Blocked
  ProgramStateError   = Ansi::ProgramState::Error
  ProgramStateClear   = Ansi::ProgramState::Clear

  ProgramStatusKindPermission = Ansi::ProgramStatusKind::Permission
  ProgramStatusKindQuestion   = Ansi::ProgramStatusKind::Question
  ProgramStatusKindAuth       = Ansi::ProgramStatusKind::Auth

  struct ProgramStatusSupportEvent
  end

  # TerminalScreen
  def set_program_status(status : ProgramStatus?) : Nil
  def program_status : ProgramStatus?
end
```

Decoder behaviour: for `OSC` command `7501`, when the data starts with `?`
(a support reply such as `\e]7501;?\a`), emit `ProgramStatusSupportEvent`;
otherwise keep emitting `UnknownOscEvent`.

## Verification

Once implemented, bubbletea.cr should:

1. translate a typed `ProgramStatusSupportEvent` in
   `Program#translate_input_event`,
2. delete `ProgramStatusSupport.reply?` and the `UnknownOscEvent` fallback,
3. drop this issue file and update the **Known Divergences** row in
   `plans/parity.md`.
