---
upstream_repo: "github.com/charmbracelet/bubbletea"
pinned_revision: "f9df43c4f2c021d8740a2628d59cd810a862eb98"
import_mode: "submodule"
upstream_submodule_path: "vendor/bubbletea"
language: go
crystal_target: "src/"
inventory_dir: "plans/inventory/"
---

# Porting Parity — bubbletea.cr

## Source of Truth

- **Upstream**: `github.com/charmbracelet/bubbletea` at `v2.1.0`
- **Revision**: `f9df43c4f2c021d8740a2628d59cd810a862eb98`
- **Path**: `vendor/bubbletea`

## Where we are

**Recently completed:** the upstream `v2.1.0` update
([plans/bubbletea-v2.1.0-update.md](bubbletea-v2.1.0-update.md)). It adds
Program Status Protocol (OSC 7501) reporting, tty `COLUMNS`/`LINES` fallback
dimensions, and a signal-shutdown guard. The `ansi` and `ultraviolet` shards
still lack OSC 7501, so the protocol is implemented locally and tracked in
[shards_issues/ansi.1.md](../shards_issues/ansi.1.md) and
[shards_issues/ultraviolet.1.md](../shards_issues/ultraviolet.1.md).

**Current focus:** no active chunk; `v2.1.0` is complete and is the latest
upstream release.

**Next up (in order):**

1. **Audit the remaining baseline test-ledger rows.** 28 rows in
   `plans/inventory/go_test_parity.tsv` are still `missing` from the initial
   auto-generated baseline. Walk upstream tests, point each at its Crystal spec
   (or leave it `missing` with a reason), and keep the checker green.
2. **Keep example parity green** in the `bubbletea-examples` submodule.
3. **Watch for the next upstream release** and the shard issues above.

### Chunk status

| Area | Status | Notes |
| ---- | ------ | ----- |
| Core runtime | Complete | `tea.go`, `commands.go`, `options.go`, `exec.go` |
| Terminal I/O | Complete | TTY delegated to `ultraviolet` (documented) |
| Input, messages, logging | Complete | Keys, mouse, clipboard, focus, paste |
| Upstream v2.0.8 upgrade | Complete | See roadmap section below |
| Upstream v2.0.9 upgrade | Complete | [Plan](bubbletea-v2.0.9-update.md) |
| Upstream v2.0.10 upgrade | Complete | [Plan](bubbletea-v2.0.10-update.md) |
| Upstream v2.1.0 upgrade | Complete | [Plan](bubbletea-v2.1.0-update.md) |
| Program Status Protocol | Complete | Local shim; see shard issues |
| Example parity | Complete | `spec/parity/`, `spec/*_parity_spec.cr` |
| Lint baseline | Complete | `make lint` — 0 findings |
| Test-ledger audit | Not started | 28 baseline rows (see **Next up** #1) |

### Last known state (2026-10-19)

- Last parity feature: v2.1.0 update
  ([plan](bubbletea-v2.1.0-update.md))
- `make format` — pass
- `make lint` — pass (19 files, 0 findings)
- `make test` — 159 examples, 0 failures
- `make check-go-{port-inventory,source-parity,test-parity}` — pass
- `scripts/check_{port,source,test}_parity.sh` over `plans/inventory/` — pass
  (613 port items, 573 source items, 40 tests)
- `make parity-specs` — 4 examples, 0 failures

## Feature Roadmap

### Core Runtime (Complete)

- [x] **Program lifecycle** — `NewProgram`, `Program#Start`, `Program#Run`, `Program#Quit`, `Program#Wait`
  - Source: `tea.go` → `src/tea.cr`
  - Tests: `tea_test.go` → `spec/tea_spec.cr` (15 tests)

- [x] **Command system** — `Batch`, `Sequence`, `Every`, `Tick`, `RequestWindowSize`
  - Source: `commands.go` → `src/tea/commands.cr`
  - Tests: `commands_test.go` → `spec/commands_spec.cr` (4 tests)

- [x] **Program options** — `WithInput`, `WithOutput`, `WithAltScreen`, `WithMouseCellMotion`, `WithMouseAllMotion`, `WithReportFocus`, `WithFilter`
  - Source: `options.go` → `src/tea/options.cr`
  - Tests: `options_test.go` → `spec/options_spec.cr`

- [x] **External command execution** — `Exec`, `ExecProcess`
  - Source: `exec.go` → `src/tea/exec.cr`
  - Tests: `exec_test.go` → `spec/exec_spec.cr`

### Terminal I/O (Complete)

- [x] **TTY setup and restore** — Raw mode, input handling, signals
  - Source: `tty.go`, `tty_unix.go`, `input.go` → `src/tea/tty.cr`
  - Signals: `signals_unix.go`, `signals_windows.go` → `src/tea.cr` (via Crystal `Signal` module)
  - Termios: delegated to `ultraviolet` shard — **intentional divergence**

- [x] **Rendering pipeline** — `Renderer` interface, `CursedRenderer`, `NilRenderer`
  - Source: `renderer.go`, `cursed_renderer.go`, `nil_renderer.go` → `src/tea/renderer.cr`, `src/tea/cursed_renderer.cr`, `src/tea/nil_renderer.cr`

- [x] **Screen control** — `EnterAltScreen`, `ExitAltScreen`, `ClearScreen`, `ClearScrollArea`
  - Source: `screen.go` → `src/tea/screen.cr`
  - Tests: `screen_test.go` → `spec/screen_spec.cr`

### Input Handling (Complete)

- [x] **Key types and formatting** — Key type system, key combos, formatting helpers
  - Source: `key.go` → `src/tea/key.cr`

- [x] **Mouse events** — MouseEvent type, mouse button constants, formatting
  - Source: `mouse.go` → `src/tea/mouse.cr`

- [x] **Clipboard** — Read/Set/ReadPrimary/SetPrimary clipboard via OSC 52
  - Source: `clipboard.go` → `src/tea/clipboard.cr`
  - Tests: `spec/clipboard_spec.cr`

### Messages (Complete)

- [x] **Focus/Blur** — FocusMsg, BlurMsg
  - Source: `focus.go` → `src/tea/messages.cr`

- [x] **Keyboard enhancement** — EnableBracketedPaste, EnableReportFocus
  - Source: `keyboard.go` → `src/tea/messages.cr`

- [x] **Paste events** — PasteMsg, PasteStart, PasteEnd
  - Source: `paste.go` → `src/tea/messages.cr`

- [x] **Raw message** — RawMsg for unsupported sequences
  - Source: `raw.go` → `src/tea/messages.cr`

- [x] **Terminal capability queries** — Background/Foreground/Cursor color, cursor position
  - Source: `color.go`, `cursor.go`, `termcap.go`, `xterm.go` → `src/tea/messages.cr`

- [x] **Environment** — EnvMsg
  - Source: `environ.go` → `src/tea.cr`

- [x] **Color profile** — ANSI256/TrueColor handling
  - Source: `profile.go` → `src/tea.cr`

- [x] **Key modifiers** — ModCtrl, ModAlt, ModShift, ModMeta
  - Source: `mod.go` → `src/tea.cr`

### Logging (Complete)

- [x] **Log to file** — `LogToFile` option, log output redirection
  - Source: `logging.go` → `src/tea/logging.cr`
  - Tests: `logging_test.go` → `spec/logging_spec.cr`

### Example Parity (Complete)

- [x] **simple** — Basic bubbletea app
- [x] **pager** — Terminal pager with highlight parity
- [x] **lipgloss colors** — Color rendering parity
- [x] **control sequences** — V2 control sequence parity
- [x] Examples live in `bubbletea-examples/` submodule, specs in `spec/parity/`

### Upstream v2.0.8 Upgrade (Complete)

Upstream changes between v2.0.6 → v2.0.8: 2 files, +6/-4 lines (functional).

- [x] **Data race fix** — `cursedRenderer.onMouse` mutex-protected `lastView` access
  - Source: `cursed_renderer.go` → `src/tea/cursed_renderer.cr`
  - Upstream commits: `c60f0c5` (PR #1691)

- [x] **Nil input guard in RestoreTerminal** — skip `initInputReader` when `input` is nil
  - Source: `tea.go` → `src/tea.cr`
  - Upstream commits: `074596e` (PR #1680)

- [x] **Extended keyboard enhancements** — `SupportsAlternateKeys`, `SupportsAllKeysAsEscapeCodes`, `SupportsAssociatedText` methods on `KeyboardEnhancementsMsg`
  - Source: `keyboard.go` → `src/tea/messages.cr`
  - Upstream commits: `05df5ae`

- [x] **Conditional tab stops + keyboard_enhancements_flags helper** — Conditional tab stops based on `hardTabs`, extracted `keyboard_enhancements_flags` helper, tab stop restore on flush
  - Source: `cursed_renderer.go` → `src/tea/cursed_renderer.cr`
  - Upstream commits: `ac355fe`, `f25595a`

- [x] **TTY stdin terminal check + mapNl optimization** — Check `tty?` before opening TTY; conditional mapNl on non-Windows with no PTY input
  - Source: `tea.go` → `src/tea.cr`
  - Upstream commits: `66b7abd`

- [x] **Signal channel leak fix** — `ensure Signal::CONT.reset` in `suspend_process` prevents channel leak on resume
  - Source: `tty_unix.go` → `src/tea/tty.cr`
  - Upstream commits: `729f05c`

- [x] **UV→KeyboardEnhancements flag mapping fix** — Corrected `convert_uv_enhancements` to use per-flag `contains?` checks matching Go ANSI constants
  - Source: `tea.go` → `src/tea.cr`

### Upstream v2.0.9 Upgrade (Complete)

Detailed plan: [plans/bubbletea-v2.0.9-update.md](bubbletea-v2.0.9-update.md).
Patch release; 12 commits, functional changes in `cursed_renderer.go` plus
small fixes in `tea.go`, `key.go`, and `mouse.go`.

- [x] **Kitty keyboard stack restore** — push flags on activation, pop on
      stop/screen switch, update flags in place when only flags change
  - Source: `cursed_renderer.go` → `src/tea/cursed_renderer.cr`
  - Upstream commit: `0d3e281` (PR #1750)
- [x] **No-input renderer guard** — `no_input=` suppresses all keyboard
      enhancement output and queries so terminal responses cannot leak
  - Source: `tea.go` (`setNoInput`) → `src/tea.cr`, `src/tea/cursed_renderer.cr`
- [x] **`pendingErase`** — `resize`/`clear_screen` force a full redraw and
      `flush` cannot early-return
  - Source: `cursed_renderer.go` → `src/tea/cursed_renderer.cr`
  - Upstream commit: `faf4dcf` (PR #1755)
- [x] **`ProgressBarState#string` out-of-range** — returns `"Unknown"`
      instead of panicking
  - Source: `tea.go` → `src/tea.cr`
  - Upstream commit: `930e18c` (PR #1748)
- [x] **Media/mouse constants** — `KeyMediaRecord` and `MouseButton11`
      correctly alias the ultraviolet constants (already correct here)
  - Source: `key.go`, `mouse.go`
  - Upstream commits: `dc4b017` (#1757), `1862dfb` (#1754)
- [x] **Renderer reset deadlock fix** — `close` now uses an unlocked reset
      helper instead of re-entering the non-reentrant mutex (found by the new
      renderer tests)
- [x] **Parity fixture updated** — kitty sequences in
      `spec/parity/v2_control_sequences_spec.cr` now match the v2.0.9 goldens
      (`[=1;1u` → `[>1u`, `[=0;1u` → `[<1u`)

### Upstream v2.0.10 Upgrade (Complete)

Detailed plan: [plans/bubbletea-v2.0.10-update.md](bubbletea-v2.0.10-update.md).
Patch release; one behavioral commit plus a Go toolchain bump.

- [x] **Skip queries without input** — `execute_query` drops every terminal
      query that expects a reply when input is disabled (background,
      foreground and cursor color, clipboard reads, terminal version,
      termcap, cursor position) plus the startup synchronized-output /
      unicode-core probe
  - Source: `tea.go` (`executeQuery`) → `src/tea.cr`
  - Upstream commit: `8b10e22` (PR #1801, gum#1118)
- [x] **`RequestCursorPosition` command** — was only a direct print helper;
      now a program command that flows through the event loop and can be
      gated like the other queries
  - Source: `cursor.go` → `src/tea/messages.cr`
- [x] **Setters and `RawMsg` unchanged** — they do not expect replies
- [x] **Go 1.26 bump** — no Crystal impact
  - Upstream commit: `657aaae` (PR #1807)

### Upstream v2.1.0 Upgrade (Complete)

Detailed plan: [plans/bubbletea-v2.1.0-update.md](bubbletea-v2.1.0-update.md).
Minor release adding OSC 7501 program status, dimension fallback, and a signal
shutdown fix.

- [x] **Program Status Protocol (OSC 7501)** — types, `View#program_status`,
      renderer reporting (including clear-on-id-change and leave-on-close),
      support query and reply translation
  - Source: `programstatus.go` → `src/tea/program_status.cr`
  - Upstream commit: `41bc626` (PR #1841)
  - Local shim: `ansi`/`ultraviolet` lack the protocol (shard issues 1)
- [x] **Fallback dimensions** — `COLUMNS`/`LINES` from the program (or process)
      environment, then 80x24; non-tty outputs keep their configured size
  - Source: `tty.go` → `src/tea/tty.cr`, `src/tea.cr`
  - Upstream commit: `96d69d2` (PR #1836)
- [x] **Signal shutdown guard** — skip delivery once shutdown started; Crystal
      traps use detached fibers, so the Go goroutine deadlock is structurally
      absent (divergence documented)
  - Source: `tea.go` → `src/tea.cr`
  - Upstream commit: `ff51ba4` (PR #1806)
- [x] **Documentation fixes** — no code change
  - Upstream commit: `33f6a40` (PR #1833)

## Inventory Summary

| Manifest | Ported/Mapped | Missing/Skipped | Total |
|----------|:------------:|:---------------:|:-----:|
| `go_port_inventory.tsv` | 347 | 265 (+1 skipped) | 613 |
| `go_source_parity.tsv` | 336 | 237 | 573 |
| `go_test_parity.tsv` | 11 | 28 (+1 skipped) | 40 |

- "Missing" items in port_inventory are mostly test/examples/tutorials — not API-level targets.
- Source parity "missing" items are test APIs, example files, and tutorial code that don't have direct Crystal source equivalents.
- The 28 `missing` rows in `go_test_parity.tsv` are the untouched auto-generated
  baseline (see **Next up** #1); the audited `v2.0.8`–`v2.1.0` tests are marked
  `ported`, except the Go-specific signal test (`skipped`).

## Known Divergences

| Go Source | Crystal Treatment | Rationale |
|-----------|-------------------|-----------|
| `signals_unix.go`, `signals_windows.go` | Absorbed into `src/tea.cr` via Crystal `Signal` module | Crystal's signal handling is idiomatic and equivalent |
| `termios_bsd.go`, `termios_other.go`, `termios_unix.go`, `termios_windows.go` | Delegated to `ultraviolet` shard | Ultraviolet provides equivalent terminal raw-mode and size APIs |
| `tty_windows.go` | Not ported (Crystal's Windows TTY is OS-level) | Handled by ultraviolet on Windows |
| `programstatus.go` types/encoding | Local `src/tea/program_status.cr` | `ansi`/`ultraviolet` shards lack OSC 7501; see `shards_issues/{ansi,ultraviolet}.1.md` |
| Go signal-goroutine shutdown fix | Guarded detached fibers in `src/tea.cr` | Crystal traps already run off-fiber; no blocking shutdown path to fix |

## Verification

```bash
# Quality gates
make format
make lint
make test

# Parity drift checks (coarse ledgers in docs/)
make check-go-port-inventory
make check-go-source-parity
make check-go-test-parity

# Per-symbol ledger checks (stricter, plans/inventory/)
./scripts/check_port_inventory.sh . plans/inventory/go_port_inventory.tsv vendor/bubbletea go
./scripts/check_source_parity.sh . plans/inventory/go_source_parity.tsv vendor/bubbletea go
./scripts/check_test_parity.sh . plans/inventory/go_test_parity.tsv vendor/bubbletea go

# Example parity specs
make parity-specs

# Adversarial signoff
./scripts/verify_parity_adversarial.sh . vendor/bubbletea go 'crystal spec' 'go test ./...'
```

The per-symbol checks all pass; keep them green when touching the ledgers.
