# ultraviolet.1 — Program Status Protocol (OSC 7501) support

**Shard:** `ultraviolet` (`github.com/dsisnero/ultraviolet`)  
**Pinned version:** `1.0.1` (`shard.lock`)  
**Upstream reference:** `github.com/charmbracelet/ultraviolet` commit
`6b8d4baf91b4` (2026-10-08), used by bubbletea v2.1.0  
**Local tracking number:** 1 (no upstream issue filed yet)

## What is missing

The Program Status Protocol (OSC 7501) is not implemented anywhere in the
shard:

- No `ProgramStatus`, `ProgramState`, or `ProgramStatusKind` types/aliases.
- No `EncodeProgramStatus`.
- No `TerminalScreen#set_program_status` / `program_status` accessors.
- The decoder does not recognise the support reply, so there is no
  `ProgramStatusSupportEvent` (or equivalent) and no alias member for it in
  `Ultraviolet::Event`.

A grep for `ProgramStatus|7501` over the shard source returns no matches at
the pinned version.

## Why it is missing

The shard tracks Charm's ultraviolet, but it lags the upstream commit that
bubbletea v2.1.0 depends on. Upstream added program status after the version
this port vendors:

- `charmbracelet/ultraviolet@6b8d4ba` imports the types from
  `charmbracelet/x/ansi v0.11.9` (`uv.ProgramStatus = ansi.ProgramStatus`).
- Its decoder maps `OSC 7501` data beginning with `?` to
  `ProgramStatusSupportEvent`.

The Crystal port's remote `HEAD` (`150cc99`) also lacks this feature, so this
is not just a stale lockfile — the shard itself needs the port.

## Downstream impact

bubbletea.cr v2.1.0 ports the feature locally:

- `src/tea/program_status.cr` defines the types and OSC 7501 encoding.
- Support replies are detected from `Ultraviolet::UnknownOscEvent` because the
  decoder has no typed event for them.

This is a documented divergence and should be removed once the shard exposes
the API. The local parser is intentionally narrow (see the shard issue for
`ansi`) and does not replace a real decoder implementation.

## Suggested API

```crystal
module Ultraviolet
  alias ProgramStatus = Ansi::ProgramStatus
  alias ProgramState = Ansi::ProgramState
  alias ProgramStatusKind = Ansi::ProgramStatusKind

  ProgramStateIdle    = Ansi::ProgramStateIdle
  ProgramStateWorking = Ansi::ProgramStateWorking
  ProgramStateDone    = Ansi::ProgramStateDone
  ProgramStateBlocked = Ansi::ProgramStateBlocked
  ProgramStateError   = Ansi::ProgramStateError
  ProgramStateClear   = Ansi::ProgramStateClear

  ProgramStatusKindPermission = Ansi::ProgramStatusKindPermission
  ProgramStatusKindQuestion   = Ansi::ProgramStatusKindQuestion
  ProgramStatusKindAuth       = Ansi::ProgramStatusKindAuth

  struct ProgramStatusSupportEvent
  end

  # TerminalScreen
  def set_program_status(status : ProgramStatus?) : Nil
  def program_status : ProgramStatus?
end
```

Decoder behaviour to add: for `OSC` command `7501`, when the data starts with
`?` (a support reply such as `\e]7501;?\a`), emit `ProgramStatusSupportEvent`;
otherwise emit `UnknownOscEvent` as today.

## Verification

Once implemented, bubbletea.cr should be able to:

1. drop `src/tea/program_status.cr` and alias the shard types,
2. translate a typed `ProgramStatusSupportEvent` in `Program#translate_input_event`,
3. delete the `UnknownOscEvent` fallback parser and its spec.
