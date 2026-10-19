# bubbletea.v2 — v2.0.8 → v2.0.9 Update Plan

**Upstream:** `github.com/charmbracelet/bubbletea`  
**Current pinned:** `fc707bb` (v2.0.8)  
**Target:** `73b6d91` (v2.0.9, released 2026-08-19)  
**Submodule:** `vendor/bubbletea`  
**Parent plan:** [plans/parity.md](parity.md)

---

## Release scope

`v2.0.9` is a patch release: 12 commits, 27 files. Functional changes are
concentrated in `cursed_renderer.go`, with one small fix each in `tea.go`,
`key.go`, and `mouse.go`; the rest is docs/CI/golden churn.

| Upstream commit | Change | Crystal target |
| --------------- | ------ | -------------- |
| `0d3e281` (#1750) | Restore Kitty keyboard stack on stop/start and screen switches; add `setNoInput`, skip keyboard sequences when input is disabled | `src/tea/cursed_renderer.cr`, `src/tea.cr` |
| `faf4dcf` (#1755) | `pendingErase` flag: `resize`/`clearScreen` force a full redraw and `flush` cannot early-return | `src/tea/cursed_renderer.cr` |
| `930e18c` (#1748) | `ProgressBarState.String()` returns `"Unknown"` for out-of-range values instead of panicking | `src/tea.cr` |
| `dc4b017` (#1757) | `KeyMediaRecord` maps to `uv.KeyMediaRecord` | `src/tea/key.cr` (already aliased) |
| `1862dfb` (#1754) | `MouseButton11` maps to `uv.MouseButton11` | `src/tea/mouse.cr` (already aliased) |
| `af9a33e`, `6fb1f47`, `d40db14`, docs/CI | Comments, tutorial links, example typo, dependabot/workflow | No code change |
| testdata `*.golden` | Kitty sequences change from `[=1;1u`/`[=0;1u` to `[>1u`/`[<1u` | Covered by renderer implementation |

### Kitty keyboard stack (main change)

Go now pushes an entry on activation (`ansi.PushKittyKeyboard(flags)`), pops on
deactivation (`ansi.PopKittyKeyboard(1)`), and updates flags in place
(`ansi.KittyKeyboard(flags, 1)`) only when the flags change without a screen
switch. `setNoInput(true)` suppresses all keyboard-enhancement output,
including the protocol reset on close, so a late terminal response cannot leak
into the shell.

### New upstream tests

| Go test | Crystal spec |
| ------- | ------------ |
| `cursed_renderer_test.go::TestCursedRenderer_restoresKittyKeyboardStack` | `spec/cursed_renderer_spec.cr` |
| `cursed_renderer_test.go::TestCursedRenderer_updatesKittyKeyboardFlagsInPlace` | `spec/cursed_renderer_spec.cr` |
| `tea_test.go::TestProgressBarStateStringOutOfRange` | `spec/screen_spec.cr` |

Additional characterization coverage (beyond upstream): no keyboard sequences
are emitted when `no_input` is enabled.

---

## Plan

### Phase 1: Update submodule

- [x] Checkout `vendor/bubbletea` at v2.0.9 (`73b6d91`)

### Phase 2: Tests first (red)

- [x] `spec/cursed_renderer_spec.cr`: kitty stack restore, in-place flag
      update, no-input behavior
- [x] `spec/screen_spec.cr`: out-of-range `ProgressBarState#string`
- [x] Confirm red: both renderer tests fail on missing API/sequences; progress
      test returns `-1`/`5`/`100` instead of `Unknown`

### Phase 3: Port implementation

- [x] `@pending_erase` + `@no_input` state and `no_input=`
- [x] `reset_keyboard_enhancements` helper (`ResetModifyOtherKeys` + pop when a
      view exists; no-op when `no_input`)
- [x] `start`: skip keyboard setup when `no_input`, push flags instead of
      set-mode
- [x] `close`: skip keyboard reset when `no_input`, pop instead of set-mode 0
- [x] `flush`: honor `pending_erase` in the no-change early return; skip
      keyboard block when `no_input`; push on first render/screen switch,
      update in place otherwise; reset via helper on screen switch
- [x] `resize`/`clear_screen`: set `pending_erase`
- [x] Wire `Program#init_renderer`: `cursed.no_input = @disable_input`
- [x] `ProgressBarState#string`: `"Unknown"` for out-of-range values
- [x] Fix `close`/`reset` deadlock (`reset_unlocked` under the held mutex)
- [x] Keep `last_view` across `reset` to match upstream
- [x] Confirm green

### Phase 4: Parity ledgers

- [x] Add the three test rows to `plans/inventory/go_port_inventory.tsv`
- [x] Add the three test rows to `plans/inventory/go_test_parity.tsv`
- [x] Confirm both strict ledger checks pass (589 items, 33 tests)

### Phase 5: Documentation and pins

- [x] Update pinned revision to `73b6d91` (v2.0.9) in `plans/parity.md`,
      `docs/porting-parity.md`, `README.md`, `CLAUDE.md`
- [x] Add the v2.0.9 roadmap section and link this file from `plans/parity.md`
- [x] Update the v2 control-sequence fixture to the v2.0.9 kitty sequences

### Phase 6: Verify

- [x] `make format`
- [x] `make lint` — 17 files, 0 findings
- [x] `make test` — 138 examples, 0 failures
- [x] `make parity-specs` — 4 examples, 0 failures
- [x] `make check-go-port-inventory`
- [x] `make check-go-source-parity`
- [x] `make check-go-test-parity`
- [x] `scripts/check_{port,source,test}_parity.sh`

---

## Later releases (not in scope)

`v2.0.10` (2026-09-24) and `v2.1.0` (2026-10-08) are also available. They are
tracked as follow-up updates once this patch is complete.
