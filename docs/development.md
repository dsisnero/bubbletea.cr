# Development

## Prerequisites

- **Crystal** >= 1.19.1
- **Go** (for parity testing with upstream)
- **Git** with submodule support
- **rumdl** (for markdown formatting): Install via Rust/Cargo: `cargo install rumdl`

## Setup

1. Clone repository with submodules:
   ```bash
   git clone --recurse-submodules https://github.com/dsisnero/bubbletea.cr
   cd bubbletea.cr
   ```

2. Install dependencies:
   ```bash
   make install
   ```

3. Verify installation:
   ```bash
   make test
   ```

## Start of session

Read [Resuming Work](resuming.md) first. Current focus and next work live in
[plans/parity.md](../plans/parity.md); upstream tracking details are in
[Porting Parity](porting-parity.md).

## Daily Workflow

1. **Start development session**:
   ```bash
   make install  # Ensure dependencies are current
   ```

2. **Run tests**:
   ```bash
   make test     # Run all specs
   ```

3. **Check formatting and linting**:
   ```bash
   make format   # Check code formatting
   make lint     # Run linter (fixes then verifies)
   ```

4. **Work on parity** (when porting Go features):
   ```bash
   make parity-specs  # Run example parity tests
   ```

## Available Commands

| Command | Purpose |
|---------|---------|
| `make install` | Install Crystal dependencies |
| `make update` | Update dependencies to latest versions |
| `make format` | Check code formatting with Crystal formatter |
| `make lint` | Run ameba linter (auto-fix then verify) |
| `make test` | Run all Crystal specs |
| `make clean` | Remove temporary files and build artifacts |
| `make build-examples` | Build submodule examples against local `src/` into `./temp/examples` (skips `bubbles` examples) |
| `make check-port-inventory` | Check the per-symbol port ledger (canonical parity skill) |
| `make check-source-parity` | Check the per-symbol source ledger (canonical parity skill) |
| `make check-test-parity` | Check the per-symbol test ledger (canonical parity skill) |
| `make check-parity` | Run every parity ledger check |
| `make verify-parity-skill` | Verify the installed parity skill and `regex` backend |
| `make check-go-port-inventory` | Check the coarse `docs/` Go port inventory |
| `make check-go-source-parity` | Check the coarse `docs/` Go source parity |
| `make check-go-test-parity` | Check the coarse `docs/` Go test parity |
| `make parity-specs` | Run example parity specs with local caches |
| `make parity-shell` | Print parity environment setup command |

The `check-parity` targets run thin wrappers in `./scripts/` that `exec` the
installed `cross-language-crystal-parity` skill (see **Parity tooling** in
`AGENTS.md`); nothing in this repo duplicates that implementation.