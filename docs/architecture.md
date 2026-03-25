# Architecture

Crystal port of Go's bubbletea TUI framework, implementing The Elm Architecture
for terminal user interfaces.

## Project Structure

```text
bubbletea.cr/
├── src/                    # Crystal source code
│   ├── bubbletea.cr       # Main library entry point
│   ├── tea.cr            # Core Tea implementation
│   └── tea/              # Tea module components
├── spec/                  # Crystal specifications
├── vendor/bubbletea/      # Upstream Go source (submodule)
├── bubbletea-examples/    # Example applications (submodule)
├── lib/                   # Crystal shard dependencies
└── temp/                  # Temporary files for testing
```

## Data Flow

1. **Model**: Application state defined by user
2. **Update**: Pure function `(Model, Msg) -> (Model, Cmd)`
3. **View**: Pure function `Model -> String` (terminal output)
4. **Commands**: Side effects wrapped in `Cmd` objects
5. **Messages**: Events from user input, timers, or external sources

The runtime (`Tea`) manages the event loop, executing commands, collecting
messages, and calling update/view functions.

## Package/Module Responsibilities

| Module | Responsibility |
|--------|----------------|
| `Tea` | Main runtime, event loop, command execution |
| `Tea::Program` | Program lifecycle and state management |
| `Tea::Renderer` | Terminal output and screen management |
| `Tea::Options` | Runtime configuration and flags |
| `Tea::Cmd` | Command system for side effects |
| `Tea::Msg` | Message system for events |

<!-- TODO: Add diagrams if helpful -->
