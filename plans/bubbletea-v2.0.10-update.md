# bubbletea.v2 — v2.0.9 → v2.0.10 Update Plan

**Upstream:** `github.com/charmbracelet/bubbletea`  
**Current pinned:** `73b6d91` (v2.0.9)  
**Target:** `d5bfd5c` (v2.0.10, released 2026-09-24)  
**Submodule:** `vendor/bubbletea`  
**Parent plan:** [plans/parity.md](parity.md)

---

## Release scope

`v2.0.10` contains two commits after the previous tag: a query-skipping fix and
a Go toolchain bump. Only the query fix changes behavior.

| Upstream commit | Change | Crystal target |
| --------------- | ------ | -------------- |
| `8b10e22` (#1801) | Skip every terminal query that expects a reply when input is disabled, so replies cannot leak into the shell (gum#1118) | `src/tea.cr` |
| `657aaae` (#1807) | Bump `go` directive to 1.26.0 | No Crystal impact |
| docs (`clipboard.go`, `color.go`, `cursor.go`, `termcap.go`, `xterm.go`, `options.go`) | Document that query commands need `WithInput` to read the reply | Comments only |

### Queries gated behind input

| Upstream message | Sequence | Crystal call site |
| ---------------- | -------- | ---------------- |
| `readClipboardMsg` | `RequestSystemClipboard` | `ReadClipboardMsg` |
| `readPrimaryClipboardMsg` | `RequestPrimaryClipboard` | `ReadPrimaryClipboardMsg` |
| `backgroundColorMsg` | `RequestBackgroundColor` | `RequestBackgroundColorMsg` |
| `foregroundColorMsg` | `RequestForegroundColor` | `RequestForegroundColorMsg` |
| `cursorColorMsg` | `RequestCursorColor` | `RequestCursorColorMsg` |
| `terminalVersion` | `RequestNameVersion` | `TerminalVersionRequestMsg` |
| `requestCapabilityMsg` | `RequestTermcap` | `RequestCapabilityMsg` |
| `requestCursorPosMsg` | `RequestCursorPositionReport` | `RequestCursorPositionMsg` |
| startup probe | `RequestModeSynchronizedOutput` + `RequestModeUnicodeCore` | `Program#run` |

The setter commands (`SetClipboardMsg`, `SetPrimaryClipboardMsg`) and `RawMsg`
are not gated: they do not expect a reply.

### Parity gap closed

Crystal had no `Tea.request_cursor_position` program command; only
`Screen.request_cursor_position`, which prints `\e[6n` directly. This update
adds the `RequestCursorPositionMsg` command so the upstream query test can be
ported as-is, and points the inventory row at `src/tea/messages.cr`.

### New upstream tests

| Go test | Crystal spec |
| ------- | ------------ |
| `tea_test.go::TestTeaNoCapabilityQueryWithoutInput` | `spec/terminal_queries_spec.cr` |
| `tea_test.go::TestTeaNoTerminalQueriesWithoutInput` | `spec/terminal_queries_spec.cr` |

The Crystal spec covers both branches (input enabled/disabled) for the startup
probe and for all eight input-dependent commands.

---

## Plan

### Phase 1: Update submodule

- [x] Checkout `vendor/bubbletea` at v2.0.10 (`d5bfd5c`)

### Phase 2: Tests first (red)

- [x] Port both upstream tests to `spec/terminal_queries_spec.cr`
- [x] Confirm red: disabled-input cases emit the queries; startup probe leaks
- [x] Confirm `Tea.request_cursor_position` is missing (compile red) before
      adding it

### Phase 3: Port implementation

- [x] Add `execute_query` (no-op when `@disable_input`)
- [x] Route the eight query messages and the startup probe through it
- [x] Add `RequestCursorPositionMsg` + `Tea.request_cursor_position`
- [x] Keep setters and `RawMsg` on plain `execute`
- [x] Confirm green

### Phase 4: Parity ledgers

- [x] Add the two test rows to `plans/inventory/go_port_inventory.tsv`
- [x] Add the two test rows to `plans/inventory/go_test_parity.tsv`
- [x] Point the `RequestCursorPosition` rows at `src/tea/messages.cr`
- [x] Confirm both strict ledger checks pass (591 items, 35 tests)

### Phase 5: Documentation and pins

- [x] Update pinned revision to `d5bfd5c` (v2.0.10) in `plans/parity.md`,
      `docs/porting-parity.md`, `README.md`, `CLAUDE.md`
- [x] Add the v2.0.10 roadmap section and link this file from `plans/parity.md`

### Phase 6: Verify

- [x] `make format`
- [x] `make lint` — 17 files, 0 findings
- [x] `make test` — 142 examples, 0 failures
- [x] `make parity-specs` — 4 examples, 0 failures
- [x] `make check-go-port-inventory`
- [x] `make check-go-source-parity`
- [x] `make check-go-test-parity`
- [x] `scripts/check_{port,source,test}_parity.sh`

---

## Later releases (not in scope)

`v2.1.0` (2026-10-08) adds program status rendering, signal tests, and tty
coverage. It is the next planned update after this patch.
