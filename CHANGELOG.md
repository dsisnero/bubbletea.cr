# Changelog

All notable user-facing changes to this project will be documented in this file.

Changes are grouped by release date and category. Only user-facing changes are included — internal refactors, test updates, and CI changes are omitted.

## [2.0.10] — 2026-10-19 — Upstream parity (v2.0.10)

Upstream Go bubbletea v2.0.9 → v2.0.10 (1 behavioral fix; Go 1.26 bump).

### Added

- `Tea.request_cursor_position` / `RequestCursorPositionMsg` — cursor position
  query now flows through the event loop instead of only the direct-print
  `Screen.request_cursor_position` helper

### Fixed

- Terminal queries are skipped when input is disabled, so replies can no longer
  leak into the shell after exit (upstream PR #1801, gum#1118). Covers clipboard
  reads, background/foreground/cursor color, terminal version, termcap, cursor
  position, and the startup synchronized-output probe.

## [2.0.9] — 2026-10-19 — Upstream parity (v2.0.9)

Upstream Go bubbletea v2.0.8 → v2.0.9 (12 commits; renderer fixes).

### Added

- `CursedRenderer#no_input=` — suppresses keyboard enhancement output and
  queries when input is disabled, so terminal responses cannot leak into the
  shell

### Changed

- `CursedRenderer` — pushes/pops the Kitty keyboard stack on start/stop and
  screen switches, and updates flags in place when only the flags change
  (upstream PR #1750)
- `ProgressBarState#string` — returns `"Unknown"` for out-of-range values
  instead of a raw number (upstream PR #1748)
- `CursedRenderer#reset` — keeps the last view so stop/start can re-push the
  keyboard stack entry

### Fixed

- `CursedRenderer#close` — no longer deadlocks by re-entering the non-reentrant
  renderer mutex
- `CursedRenderer#resize` / `#clear_screen` — a pending erase forces a full
  redraw (upstream PR #1755)

## [2.0.8] — 2026-07-27 — Upstream parity (v2.0.8)

Upstream Go bubbletea v2.0.6 → v2.0.8 (2 files, +6/-4 lines).

### Added

- `vendor/bubbles` submodule at charmbracelet/bubbles v2.1.1

### Fixed

- `CursedRenderer#on_mouse` — mutex-protect `@last_view` access to prevent data race (upstream PR #1691)
- `Program#restore_terminal` — skip `init_input_reader` when input is nil, matching upstream guard (upstream PR #1680)

## [2.0.6] — 2026-05-27 — Upstream parity (v2.0.6)

Upstream Go bubbletea v2.0.0 → v2.0.6 (4 files, +82/-17 lines).

### Added

- `KeyboardEnhancementsMsg#supports_alternate_keys?` — reports alternate key support
- `KeyboardEnhancementsMsg#supports_all_keys_as_escape_codes?` — reports all-keys-as-escapes support
- `KeyboardEnhancementsMsg#supports_associated_text?` — reports associated text support
- `CursedRenderer#keyboard_enhancements_flags` — flag-to-ANSI bitmask helper

### Changed

- `CursedRenderer#set_optimizations` — conditional tab stops based on `hard_tabs`
- `CursedRenderer#reset` — conditional tab stops based on `hard_tabs`
- `CursedRenderer#flush` — restores tab stops when `starting` and `hard_tabs`
- `Program#Run` — checks `STDIN#tty?` before opening TTY (matching upstream)
- `Program#Run` — conditional `mapNl` optimization for non-Windows with no PTY
- `convert_uv_enhancements` — fixed per-flag mapping using `contains?` instead of incorrect `supports_key_disambiguation?`→`report_alternate_keys`

### Fixed

- `TTY#suspend_process` — `ensure Signal::CONT.reset` to prevent channel leak