---
upstream_repo: "github.com/charmbracelet/bubbletea"
pinned_revision: "07a69fbcf1e3649a797a929d724f94170d6affc3"
import_mode: "submodule"
upstream_submodule_path: "vendor/bubbletea"
---

# Porting Parity

## Upstream Source of Truth

- **Repository**: `github.com/charmbracelet/bubbletea`
- **Pinned revision**: `07a69fbcf1e3649a797a929d724f94170d6affc3`
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
make check-go-port-inventory
make check-go-source-parity
make check-go-test-parity
make parity-specs
```
