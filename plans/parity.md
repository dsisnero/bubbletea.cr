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

**Recently completed:** the `bubbletea-examples` refresh. Every parity golden is
now generated from the pinned Go sources by `bubbletea-examples/goldens` — a
small Go module with one harness per example — the submodule builds against this
repository's `HEAD`, and its suite reports 82 examples, 0 failures, 14 pending.
Three real bugs surfaced on the way and are fixed here:

- `Program#run` recreated its `msgs`/`cmds` channels, so anything sent between
  `new_program` and `run` was dropped. Go delivers those messages; the event
  loop now keeps the channels `initialize` builds, with a regression spec.
- `start_renderer` slept `interval` and then did the flush work inside the loop,
  so repaints drifted to ~22-25ms where Go's `time.Ticker` holds 16.7ms, which
  changed how many frames `paginator` and `spinner` emit. The renderer now
  tracks a deadline and drops missed ticks.
- `spec/pipe_no_input_parity_spec.cr` ran `examples/pipe.cr`, a path that does
  not exist, so it only passed its exit-code assertion.

The `bubbles` port was also fixed where the examples exposed it: `humanize_bytes`
divided by 1024 and printed `KB` where Go's `go-humanize` is 1000-based
(`131kB`), which was the whole `file_picker` difference. Its `Textarea#prompt_view`
returned the raw prompt when no prompt func was set, dropping
`computedPrompt()`; Go applies it either way (`vendor/bubbles` v2.1.1
`textarea.go:1462-1475`). That missing style made the renderer rewrite gutter
cells Go skips, which was the entire `dynamic-textarea` gap; pinning
`dsisnero/bubbles` main (`c933ae5`) closes it.

Earlier in the same stretch the raw-OSC program-status fallback was deleted, the
support query was split from the reply (`RequestProgramStatusSupportMsg`), and
the v2 control-sequence fixture was re-derived from Go.

**Current focus:** close the open parity items below; **`v2.1.0` is not tagged
yet** and must not be until they are done. Everything landed so far is verified
and pushed: the library gates are green, the 58 example goldens are generated
from the pinned Go sources, and the submodule suite is 82 examples,
0 failures, 13 pending. `program-status` and `dynamic-textarea` are both ported
with green goldens.

**Next up (in order):**

1. **Port the six approximation examples properly** — `clickable`, `doom_fire`,
   `list_fancy`, `split_editors`, `textinputs` and `tui_daemon_combo` are not
   missing a capture harness; they are *approximations* of the Go example, so
   there is nothing faithful to capture. Line counts against the pin:

   | example | Crystal | Go | main gaps |
   | --- | --- | --- | --- |
   | `textinputs` | 72 | 196 | textinput widgets, lipgloss chrome |
   | `tui_daemon_combo` | 67 | 139 | daemon/combo composition |
   | `split_editors` | 78 | 235 | two textareas, focus handling, lipgloss |
   | `clickable` | 277 | 446 | lipgloss rounded borders/colors/padding, `ksuid`, random words (Crystal draws ASCII `+--+`) |
   | `doom_fire` | 116 | 133 | palette/rand + tick pacing |
   | `list_fancy` | 317 | 476 | list delegate/pagination styling |

   Order the work smallest-first and take one example per commit: rewrite the
   example against `vendor/bubbletea` at the pin, then a harness in
   `goldens/<name>/`, then a golden from `python3 goldens/generate.py <name>`,
   then flip the spec to `it`. `doom_fire` and `list_fancy` also need the RNG
   convention below.

   **Do this first (shared prerequisite):** `doom_fire`, `list_fancy` and the
   already-pending `list_fancy_h_a` all put RNG output in the frame, so parity
   needs Crystal to replay Go's `math/rand` v1 stream (`rngSource`: 607-word
   lagged Fibonacci seeded via `seedrand`), not just a seeded `Random`. Land one
   shared helper in the specs and prove it against the existing `list_fancy_h_a`
   golden before porting the two RNG examples. `generate.py` now forces
   `GODEBUG=randseednop=0`, so the Go side is reproducible regardless of the
   caller. Nothing else blocks the six rewrites; `lib/bubbletea` in the
   submodule is verified identical to this repository's `src/`, so specs run
   against `HEAD`.

2. **Port the last upstream example** — `glamour` needs the `glamour` shard,
   which has no Crystal port, so it is blocked until that exists.
3. **Close the documented `pending` specs** — the exact 13 today:
   - six above (approximations);
   - `focus_blur` (`ultraviolet` has no IRM cell-insert fallback),
     `set_terminal_color` (Go clears with EL0; this port moves right, erases,
     steps back) and `space` (high-volume styled block redraw stream drifts in
     the renderer/lipgloss path) — all three are upstream renderer work, and each
     records that the visible frame is identical;
   - `paginator` and `textarea`, which capture a scheduling-dependent frame
     count and need a normalized comparison instead of byte equality (shared
     helper — `textarea`'s example is a faithful port otherwise);
   - `list_fancy H->a`, which needs the same RNG convention as item 1;
   - `spec/canvas_spec.cr`, the teatest-based spec: it needs
     `-Dpreview_mt -Dexecution_context` *and* the `teatest` dev shard, which is
     not declared. The golden-based `spec/canvas_parity_spec.cr` already passes,
     so this one is optional coverage — do not confuse the two.
   `file_picker` and `dynamic_textarea` are green: `bubbles` now humanises sizes
   on the same 1000 base as Go's `go-humanize`, and applies `Textarea`'s prompt
   style the way upstream does. Note `file_picker`'s golden embeds the size of
   the fixture's `a_dir`, which the filesystem reports (exFAT says 131kB, APFS
   says ~96B), so the fixture needs a normalization before the suite can run on
   another volume.
4. **Only then tag `v2.1.0`** — from this repository run `make format`,
   `make lint`, `make test`, `make check-parity`, `make parity-specs`, and
   `make build-examples`; in `bubbletea-examples`, with `lib/bubbletea` pinned
   to this repository's `HEAD`, run `crystal spec`.
5. **Re-derive the control-sequence fixture if either pin moves** —
   `spec/parity/v2_control_sequences_spec.cr` was verified against
   `vendor/bubbletea` `f9df43c` with ultraviolet `6b8d4ba` and `8ecbcf0`; the
   spec records the recipe.

### Known shard bugs (fixed outside this repository)

`lib/` is patched and released separately, so these are recorded here rather
than fixed in place. Both were found while porting `textinputs`.

- **`ultraviolet` renderer, `NoTTY` profile: styled spaces are not blank.** A
  space cell carrying an SGR reverse attribute is kept as non-blank, so the row
  is painted one cell wider than Go's, which trims it. Repro:
  `crystal spec spec/textinputs_parity_spec.cr` in `bubbletea-examples` — the
  golden has `> hi` where this port emits `> hi `. The example is not at fault:
  its view is Go's token for token (37 tokens, identical cells and styles).
- **`lipgloss`/`colorprofile` colour encoding.** The port emits true colour
  (`38;2;88;88;88`) where Go emits the indexed form (`38;5;240`) for the same
  colour. Invisible under `NoTTY` captures, but it changes bytes wherever a
  colour profile is active.

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
| Program Status Protocol | Complete | OSC 7501 types/encoder from `ansi`, replies typed by `ultraviolet` |
| Example parity | 63 of 64 files, 57 faithful | 63 examples have a Crystal file and `glamour` is blocked on its shard; of those, six (`clickable`, `doom_fire`, `list_fancy`, `split_editors`, `textinputs`, `tui_daemon_combo`) are still approximations that need a real port. Goldens are generated from the pinned Go sources by `bubbletea-examples/goldens`, with `vendor/bubbles` replaced in — see Next up |
| Lint baseline | Complete | `make lint` — 0 findings |
| Test-ledger audit | Complete | 37 ported, 3 skipped, 0 missing |

### Last known state (2026-11-24)

- Dependencies: `ultraviolet` `1.1.6` (root and submodule; `Terminal` is a
  facade over `TerminalScreen`, which Bubble Tea does not use — its renderer is
  built the way `vendor/bubbletea` `cursed_renderer.go` `reset()` builds it, so
  patch releases need no renderer change), `ansi` refreshed to `4625557` (the
  stale `aa47d48` lock predated `Ansi.each_grapheme_cluster` and failed to
  compile), `bubbles` pinned to `c933ae5` on `main` (see below).
- `make format` — pass (target now scoped to `src spec`; the submodule's `lib/`
  made the previous unscoped run check vendored shards)
- `make lint` — pass (18 files, 0 findings)
- `make test` — pass (160 examples, 0 failures)
- `make check-parity` — pass (PARITY_DISCOVERY_BACKEND=regex)
- `make parity-specs` — pass (4 examples, 0 failures)
- `make build-examples` — pass after a forced rebuild (36 examples compile
  against this `src/`; the 25 that need the `bubbles` shard are skipped by
  design)
- `bubbletea-examples` `crystal spec` (with `lib/bubbletea` pinned to this
  repository's `HEAD`) — pass, 82 examples, 13 pending, 0 failures
- Ledgers: port 372 `ported` / 1 `partial` / 240 `skipped` (example programs
  live in the submodule); source 336 `mapped` / 237 `skipped`; tests
  36 `ported` / 1 `partial` / 3 `skipped`
- The fixture in `spec/parity/v2_control_sequences_spec.cr` is re-derived from
  Go and verified against the pinned sources; the example goldens are likewise
  produced by `bubbletea-examples/goldens`.
- Golden rule worth keeping: a golden must be reproducible by its own harness.
  `prevent_quit`'s was not — it matched bubbles v2.0.0, not the pin — because
  the resolver served the registry's `bubbles` instead of `vendor/bubbles`.
  `goldens/go.mod` now replaces both pinned Go modules, and
  `python3 goldens/generate.py <name>` run twice is the cheapest staleness
  check.

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
      support query and reply translation. `RequestProgramStatusSupportMsg`
      mirrors Go's unexported `programStatusSupportMsg`, so the query and the
      terminal's reply are distinct messages.
  - Source: `programstatus.go` → `src/tea/program_status.cr`
  - Upstream commit: `41bc626` (PR #1841)
  - Types/encoder: `ansi` shard; reply detection: `ultraviolet`'s
    `ProgramStatusSupportEvent`
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
| `go_port_inventory.tsv` | 373 | 237 (+3 skipped) | 613 |
| `go_source_parity.tsv` | 336 | 237 | 573 |
| `go_test_parity.tsv` | 37 | 0 (+3 skipped) | 40 |

- "Missing" items in port_inventory are mostly test/examples/tutorials — not API-level targets.
- Source parity "missing" items are test APIs, example files, and tutorial code that don't have direct Crystal source equivalents.
- `go_test_parity.tsv` has no `missing` rows. Three are `skipped`: the
  Go-goroutine-specific signal test and the two upstream example tests that are
  commented out/skipped. The rest are `ported` with a Crystal spec reference.

## Known Divergences

| Go Source | Crystal Treatment | Rationale |
|-----------|-------------------|-----------|
| `signals_unix.go`, `signals_windows.go` | Absorbed into `src/tea.cr` via Crystal `Signal` module | Crystal's signal handling is idiomatic and equivalent |
| `termios_bsd.go`, `termios_other.go`, `termios_unix.go`, `termios_windows.go` | Delegated to `ultraviolet` shard | Ultraviolet provides equivalent terminal raw-mode and size APIs |
| `tty_windows.go` | Not ported (Crystal's Windows TTY is OS-level) | Handled by ultraviolet on Windows |
| `logging.go` default-logger wiring | `log_to_file` opens the file; `log_to_file_with` configures a caller-supplied `LogOptionsSetter` | Crystal has no settable process-wide logger, so Go's `log.SetOutput` / `log.SetPrefix` have no global target; callers wire their own logger |
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

# Per-symbol ledger checks (stricter, plans/inventory/); these forward to the
# installed cross-language-crystal-parity skill
make check-port-inventory
make check-source-parity
make check-test-parity
make check-parity
make verify-parity-skill

# Example parity specs
make parity-specs

# Adversarial signoff
./scripts/verify_parity_adversarial.sh . vendor/bubbletea go 'crystal spec' 'go test ./...'
```

The per-symbol checks all pass; keep them green when touching the ledgers.

### Ledger composition

The port ledger tracks 613 upstream symbols and the source ledger 573 API items.
Everything outside `examples/` and `tutorials/` is `ported` (372) or `partial`
(1 — `LogToFile`, whose Go default-logger wiring has no Crystal target) or
`skipped` with a rationale (3 — the two upstream example tests that are
commented out and one signal test whose Go goroutine deadlock does not exist in
Crystal). The 237 symbols under `examples/` and `tutorials/` are `skipped` here
because those programs live in the `bubbletea-examples` submodule, where their
Go golden parity is tracked; this shard ships the library, not the example
programs.

The test ledger (40 rows) is 36 `ported`, 1 `partial` (`TestLogToFile`, see the
logging divergence) and 3 `skipped`, with no `missing` rows.
