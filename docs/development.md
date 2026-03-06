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
| `make build-examples` | Build example applications |
| `make check-go-port-inventory` | Check Go port inventory |
| `make check-go-source-parity` | Check Go source parity |
| `make check-go-test-parity` | Check Go test parity |
| `make parity-specs` | Run example parity specs with local caches |
| `make parity-shell` | Print parity environment setup command |