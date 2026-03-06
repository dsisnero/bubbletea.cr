<p align="center">
  <strong>Crystal port of Go's bubbletea TUI framework</strong><br>
  Terminal user interfaces based on The Elm Architecture
</p>

<p align="center">
  <a href="docs/architecture.md">Architecture</a> &middot;
  <a href="docs/development.md">Development</a> &middot;
  <a href="docs/coding-guidelines.md">Guidelines</a> &middot;
  <a href="docs/testing.md">Testing</a> &middot;
  <a href="docs/pr-workflow.md">PR Workflow</a> &middot;
  <a href="docs/porting-parity.md">Porting Parity</a>
</p>

---

Bubble Tea is a refreshing drink with layers of flavor; this framework layers
terminal UI components into elegant applications. Just as bubble tea combines
tea, milk, and tapioca pearls into a harmonious drink, this framework combines
models, updates, and views into cohesive terminal interfaces.

---

## Quick Start

1. Add to your `shard.yml`:

   ```yaml
   dependencies:
     bubbletea:
       github: dsisnero/bubbletea
   ```

2. Install:

   ```bash
   shards install
   ```

3. Use in your code:

   ```crystal
   require "bubbletea"

   # See bubbletea-examples/ for ported examples
   ```

## Features

- **Elm Architecture**: Model-Update-View pattern for terminal UIs
- **Exact Go parity**: Direct port maintaining identical behavior
- **Command system**: Side effects wrapped in `Cmd` objects
- **Event handling**: Keyboard, mouse, and custom events
- **Terminal rendering**: Efficient screen updates and cursor management

## Development

```bash
make install   # Install dependencies
make test      # Run specs
make format    # Format Crystal code
make lint      # Run Crystal linter
rumdl fmt docs/ *.md  # Format markdown documentation
```

See [Development Guide](docs/development.md) for full setup instructions.

## Documentation

| Document | Purpose |
|----------|---------|
| [Architecture](docs/architecture.md) | System design and data flow |
| [Development](docs/development.md) | Setup and daily workflow |
| [Coding Guidelines](docs/coding-guidelines.md) | Code style and conventions |
| [Testing](docs/testing.md) | Test commands and patterns |
| [PR Workflow](docs/pr-workflow.md) | Commits, PRs, and review process |
| [Porting Parity](docs/porting-parity.md) | Upstream source tracking |

## Contributing

1. Create an issue: `/forge-create-issue`
2. Implement: `/forge-implement-issue <number>`
3. Self-review: `/forge-reflect-pr`
4. Address feedback: `/forge-address-pr-feedback`
5. Update changelog: `/forge-update-changelog`
