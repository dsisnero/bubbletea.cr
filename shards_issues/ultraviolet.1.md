# ultraviolet.1 — Program Status Protocol (OSC 7501) decoder support

**Shard:** `ultraviolet` (`github.com/dsisnero/ultraviolet`)
**Pinned version:** `1.1.1` (`shard.lock`)
**Upstream reference:** `github.com/charmbracelet/ultraviolet` commit
`6b8d4baf91b4` (2026-10-08), used by bubbletea v2.1.0
**Local tracking number:** 1 (no upstream issue filed yet)
**Status:** open — the encoder landed in `ansi`, the decoder event has not

## Status

The decoder landed on `main` at `756d7a7`:

- `src/ultraviolet/program_status.cr` adds the `ProgramStatus` /
  `ProgramState` / `ProgramStatusKind` aliases and
  `ProgramStatusSupportEvent`.
- `Decoder` maps `OSC 7501` data beginning with `?` to
  `ProgramStatusSupportEvent` instead of `UnknownOscEvent`.

`ansi` already owns the types and encoder (`aa47d48`).

## Packaging blocker

No release tag includes the decoder yet: `v1.1.1` still points at `150cc99`,
and `shard.yml` still says `version: 1.1.1`. Pinning a branch or commit from
this repo does not resolve:

```
- `ultraviolet (branch main)` required by `shard.yml`
- `ultraviolet (*)` required by `lipgloss 2.0.1`
```

Shards cannot satisfy a git-ref pin from one source against the `*`
requirement from `lipgloss`. The action needed is a tagged release
(e.g. `v1.2.0`).

## Downstream impact

bubbletea.cr consumes the typed event when the installed shard has it and
falls back to raw OSC parsing for tagged releases:

```crystal
{% if Ultraviolet.has_constant?("ProgramStatusSupportEvent") %}
  return ProgramStatusSupportMsg.new if event.is_a?(Ultraviolet::ProgramStatusSupportEvent)
{% end %}
```

`Program#translate_input_event` still checks `ProgramStatusSupport.reply?` for
`UnknownOscEvent`. The fallback becomes dead code once a release ships the
decoder and can be deleted.

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

Verified locally against `main` (`756d7a7`): the typed event translates to
`ProgramStatusSupportMsg` and the full spec suite passes. After a tagged
release:

1. run `shards update ultraviolet`,
2. delete `ProgramStatusSupport.reply?` and the `UnknownOscEvent` fallback,
3. drop this issue file and update the **Known Divergences** row in
   `plans/parity.md`.
