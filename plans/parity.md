---
upstream_repo: "github.com/charmbracelet/bubbletea"
pinned_revision: "fc707bb7ea0161405bb6c653ec93f6a9c6a72fe1"
import_mode: "submodule"
upstream_submodule_path: "vendor/bubbletea"
language: go
crystal_target: "src/"
inventory_dir: "plans/inventory/"
---

# Porting Parity — bubbletea.cr

## Source of Truth

- **Upstream**: `github.com/charmbracelet/bubbletea` at `v2.0.8`
- **Revision**: `fc707bb7ea0161405bb6c653ec93f6a9c6a72fe1`
- **Path**: `vendor/bubbletea`

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

## Inventory Summary

| Manifest | Ported/Mapped | Missing/Skipped | Total |
|----------|:------------:|:---------------:|:-----:|
| `go_port_inventory.tsv` | 322 | 262 | 584 |
| `go_source_parity.tsv` | 322 | 234 | 556 |
| `go_test_parity.tsv` | 26 | 2 | 28 |

- "Missing" items in port_inventory are mostly test/examples/tutorials — not API-level targets.
- Source parity "missing" items are test APIs, example files, and tutorial code that don't have direct Crystal source equivalents.

## Known Divergences

| Go Source | Crystal Treatment | Rationale |
|-----------|-------------------|-----------|
| `signals_unix.go`, `signals_windows.go` | Absorbed into `src/tea.cr` via Crystal `Signal` module | Crystal's signal handling is idiomatic and equivalent |
| `termios_bsd.go`, `termios_other.go`, `termios_unix.go`, `termios_windows.go` | Delegated to `ultraviolet` shard | Ultraviolet provides equivalent terminal raw-mode and size APIs |
| `tty_windows.go` | Not ported (Crystal's Windows TTY is OS-level) | Handled by ultraviolet on Windows |

## Verification

```bash
# Quality gates
crystal tool format --check src spec
ameba src spec
crystal spec

# Parity drift checks
./scripts/check_port_inventory.sh . plans/inventory/go_port_inventory.tsv vendor/bubbletea go
./scripts/check_source_parity.sh . plans/inventory/go_source_parity.tsv vendor/bubbletea go
./scripts/check_test_parity.sh . plans/inventory/go_test_parity.tsv vendor/bubbletea go

# Adversarial signoff
./scripts/verify_parity_adversarial.sh . vendor/bubbletea go 'crystal spec' 'go test ./...'
```
