---
upstream_repo: "github.com/charmbracelet/bubbletea"
pinned_revision: "f9df43c4f2c021d8740a2628d59cd810a862eb98"
import_mode: "submodule"
upstream_submodule_path: "vendor/bubbletea"
---

# Porting Parity

Status and next work live in [plans/parity.md](../plans/parity.md); this page
explains the upstream tracking model.

## Upstream Source of Truth

- **Repository**: `github.com/charmbracelet/bubbletea`
- **Pinned revision**: `f9df43c4f2c021d8740a2628d59cd810a862eb98` (`v2.1.0`)
- **Import mode**: `submodule`
- **Upstream path**: `vendor/bubbletea`

## Parity Scope

| Upstream Module/Path | Crystal Target | Status | Notes |
|----------------------|----------------|--------|-------|
| `tea/` | `src/tea/` | Complete | Core runtime ported |
| `options.go` | `src/tea/options.cr` | Complete | Runtime options |
| `commands/` | `src/tea/commands.cr` | Complete | Command system |
| `exec/` | `src/tea/exec.cr` | Complete | External command execution |
| `renderer/` | `src/tea/renderer.cr` | Complete | Terminal rendering |

## Behavior Checklist

- [x] Public API surface mapped
- [x] Constants and types ported
- [x] Error semantics matched
- [x] Edge cases mirrored
- [x] Fixtures/goldens verified

## Test Parity

| Upstream Test/Fixture | Crystal Spec | Status | Notes |
|------------------------|--------------|--------|-------|
| `tea/*_test.go` | `spec/tea_spec.cr` | Complete | Core tests ported |
| `options/*_test.go` | `spec/options_spec.cr` | Complete | Options tests |
| `commands/*_test.go` | `spec/commands_spec.cr` | Complete | Command tests |
| `exec/*_test.go` | `spec/exec_spec.cr` | Complete | Exec tests |
| Examples | `bubbletea-examples/spec/*_parity_spec.cr` | Complete | Example parity tests |

## Known Deviations

- `Bubbletea.exec_process` now mirrors `Tea.exec_process(command, args, callback)`.
- Example parity captures remain optional because they depend on generated files
  under `temp/parity/`.

## Verification Commands

```bash
# Crystal quality gates
crystal tool format --check src spec
ameba src spec
crystal spec

# Parity verification
make check-parity        # per-symbol ledgers (canonical skill scripts)
make check-go-port-inventory   # coarse docs/ ledgers
make check-go-source-parity
make check-go-test-parity
make verify-parity-skill
make parity-specs
```

The per-symbol checks live in `plans/inventory/` and forward to the installed
`cross-language-crystal-parity` skill; `docs/go_*.tsv` is the coarse ledger.
