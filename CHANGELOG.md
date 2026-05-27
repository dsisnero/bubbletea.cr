# Changelog

All notable user-facing changes to this project will be documented in this file.

Changes are grouped by release date and category. Only user-facing changes are included — internal refactors, test updates, and CI changes are omitted.

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