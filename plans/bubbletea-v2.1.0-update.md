# bubbletea.v2 — v2.0.10 → v2.1.0 Update Plan

**Upstream:** `github.com/charmbracelet/bubbletea`  
**Current pinned:** `d5bfd5c` (v2.0.10)  
**Target:** `f9df43c` (v2.1.0, released 2026-10-08)  
**Submodule:** `vendor/bubbletea`  
**Parent plan:** [plans/parity.md](parity.md)

---

## Release scope

`v2.1.0` is a minor release: the Program Status Protocol (OSC 7501), a tty
dimension fallback, a signal-shutdown fix, and documentation corrections.

| Upstream commit | Change | Crystal target |
| --------------- | ------ | -------------- |
| `41bc626` (#1841) | Program Status Protocol (OSC 7501): types, `View.ProgramStatus`, renderer reporting, support query | `src/tea/program_status.cr`, `src/tea.cr`, `src/tea/cursed_renderer.cr` |
| `96d69d2` (#1836) | Fall back to `COLUMNS`/`LINES` or 80x24 when terminal size is non-positive | `src/tea.cr`, `src/tea/tty.cr` |
| `ff51ba4` (#1806) | Do not block the signal handler forever when the event loop stopped | `src/tea.cr` (documented divergence) |
| `33f6a40` (#1833) | Documentation/example corrections | Comments only |

### Program Status Protocol (OSC 7501)

Upstream aliases types from `charmbracelet/x/ansi v0.11.9` and relies on
`charmbracelet/ultraviolet` for decoding the support reply. Neither Crystal
shard has the protocol yet, so this port implements it locally:

- `ProgramStatus`, `ProgramState`, `ProgramStatusKind` + state/kind constants.
- Encoding: `SetProgramStatus` (`\e]7501;state=...:key=value\a`),
  `ClearProgramStatus`, `ClearProgramStatusID`, `RequestProgramStatusSupport`
  (`\e]7501;?\a`), with the upstream validation rules (id segments, progress
  gating/clamping, title/message sanitisation + base64 + length limits).
- `View#program_status`, renderer start/flush/clear behaviour, view equality.
- `ProgramStatusSupportMsg` + `Tea.request_program_status_support`; the reply
  is recognised from `Ultraviolet::UnknownOscEvent` because the decoder has no
  typed event.

Shard gaps are tracked in:
[shards_issues/ansi.1.md](../shards_issues/ansi.1.md) and
[shards_issues/ultraviolet.1.md](../shards_issues/ultraviolet.1.md).

### Fallback dimensions

When the tty reports `0x0` (or a negative size), use `COLUMNS` / `LINES` from
the program environment (falling back to the process environment when no
`WithEnvironment` was supplied), then `80x24`. Non-tty outputs keep their
configured dimensions (including `0x0`) instead of inventing 80x24.

### Signal shutdown

Upstream's fix prevents a Go signal goroutine from blocking on a stopped
message channel. Crystal signal traps already hand off to detached fibers, so
the Go deadlock cannot occur; this port adds a shutdown guard before sending
and documents the structural divergence instead of porting the exact test.

### New upstream tests

| Go test | Crystal spec | Notes |
| ------- | ------------ | ----- |
| `programstatus_test.go::TestCursedRenderer_programStatus` | `spec/program_status_spec.cr` | Renderer lifecycle |
| `programstatus_test.go::TestTranslateProgramStatusSupport` | `spec/program_status_spec.cr` | Raw OSC reply → support msg |
| `tty_test.go::TestFallbackDimensions` | `spec/tty_spec.cr` | Env + defaults |
| `tty_test.go::TestProgramNonTTYDimensions` | `spec/tty_spec.cr` | 0x0 vs `WithWindowSize` |
| `signals_test.go::TestHandleSignalsReturnsAfterContextCancelDuringPendingSend` | — | Skipped: Go-goroutine-specific |

---

## Plan

### Phase 1: Update submodule

- [x] Checkout `vendor/bubbletea` at v2.1.0 (`f9df43c`)
- [x] Record `ansi` and `ultraviolet` gaps in `shards_issues/`

### Phase 2: Tests first (red)

- [x] `spec/program_status_spec.cr`: encoding table, renderer lifecycle,
      support-reply translation
- [x] `spec/tty_spec.cr`: fallback dimensions and non-tty dimension behaviour
- [x] Confirm red (missing API and current 80x24 behaviour)

### Phase 3: Port implementation

- [x] `src/tea/program_status.cr` — types, constants, protocol encoder
- [x] `View#program_status` + renderer start/flush/close/equality
- [x] Event loop: `ProgramStatusSupportMsg` → gated query
- [x] Input translation: OSC 7501 support reply from `UnknownOscEvent`
- [x] `Program#fallback_dimensions` + apply in `run` and `check_resize`
- [x] Signal delivery shutdown guard (documented divergence)
- [x] Confirm green

### Phase 4: Parity ledgers

- [x] Add the `programstatus.go` API and `examples/program-status` rows to
      `plans/inventory/go_port_inventory.tsv` and `go_source_parity.tsv`
- [x] Add the five test rows (four `ported`, signals `skipped`)
- [x] Confirm all strict ledger checks pass (613 port items, 573 source items,
      40 tests)

### Phase 5: Documentation and pins

- [x] Update pinned revision to `f9df43c` (v2.1.0) in `plans/parity.md`,
      `docs/porting-parity.md`, `README.md`, `CLAUDE.md`
- [x] Add the v2.1.0 roadmap section and link this file from `plans/parity.md`
- [x] Document the shard divergences in **Known Divergences**
- [x] Update `CHANGELOG.md` and `shard.yml` (2.1.0)

### Phase 6: Verify

- [x] `make format`
- [x] `make lint` — 18 files, 0 findings
- [x] `make test` — 159 examples, 0 failures
- [x] `make parity-specs` — 4 examples, 0 failures
- [x] `make check-go-port-inventory`
- [x] `make check-go-source-parity`
- [x] `make check-go-test-parity`
- [x] `scripts/check_{port,source,test}_parity.sh`
