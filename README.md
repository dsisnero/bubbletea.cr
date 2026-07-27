<p align="center">
  <strong>Crystal port of Go's Bubble Tea TUI framework</strong><br>
  The fun, functional and stateful way to build terminal apps.<br>
  A Crystal framework based on <a href="https://guide.elm-lang.org/architecture/">The Elm Architecture</a>.
</p>

<p align="center">
  <a href="docs/architecture.md">Architecture</a> &middot;
  <a href="docs/development.md">Development</a> &middot;
  <a href="docs/coding-guidelines.md">Guidelines</a> &middot;
  <a href="docs/testing.md">Testing</a> &middot;
  <a href="docs/pr-workflow.md">PR Workflow</a> &middot;
  <a href="docs/porting-parity.md">Porting Parity</a> &middot;
  <a href="docs/upgrade_guide_v2.md">Upgrade Guide v2</a>
</p>

Bubble Tea is well-suited for simple and complex terminal applications, either
inline, full-window, or a mix of both. This is a direct, behavior-preserving
port of [github.com/charmbracelet/bubbletea][upstream] to Crystal, tracking the
upstream v2 API.

Key features:

- **Elm Architecture**: Model-Update-View pattern for terminal UIs
- **High-performance renderer**: Cell-based diffing, color downsampling, cursor management
- **Event system**: Keyboard, mouse, window resize, focus/blur, paste, and custom events
- **Command system**: Side effects wrapped in `Cmd` objects (batch, sequence, tick, every)
- **Clipboard support**: Read and set system clipboard via OSC 52
- **External command execution**: Run subprocesses with terminal release/restore
- **Alt screen support**: Full-window and inline modes

---

## Tutorial

Bubble Tea is based on the functional design paradigms of [The Elm
Architecture][elm]. It's a delightful way to build terminal applications.

### The Model

A Bubble Tea program is built around a **model** that describes the application
state and three methods on that model:

- **init** — returns an initial command for the application to run
- **update** — handles incoming events and updates the model
- **view** — renders the UI based on the model's state

Let's build a shopping list. Start by defining our model:

```crystal
require "bubbletea"

# The model stores our application state.
# It includes Tea::Model and implements init, update, and view.
class ShopModel
  include Tea::Model

  @choices : Array(String)
  @cursor : Int32
  @selected : Set(Int32)

  def initialize
    @choices = ["Buy carrots", "Buy celery", "Buy kohlrabi"]
    @cursor = 0
    @selected = Set(Int32).new
  end
```

### Init

`init` can return a `Cmd` that performs initial I/O. For now we don't need any:

```crystal
  def init : Tea::Cmd?
    nil
  end
```

### Update

The update method is called when "things happen." Its job is to look at what
has happened and return an updated model, optionally with a command.

Messages (`Msg`) are the result of some I/O — a keypress, timer tick, or
response from a server.

```crystal
  def update(msg : Tea::Msg) : Tuple(Tea::Model, Tea::Cmd?)
    case msg
    when Tea::KeyPressMsg
      case msg.to_s
      when "ctrl+c", "q"
        return {self, Tea.quit}
      when "up", "k"
        @cursor -= 1 if @cursor > 0
      when "down", "j"
        @cursor += 1 if @cursor < @choices.size - 1
      when "enter", " "
        if @selected.includes?(@cursor)
          @selected.delete(@cursor)
        else
          @selected.add(@cursor)
        end
      end
    end

    {self, nil}
  end
```

### View

The view method renders the UI. It builds a `Tea::View` describing the entire
screen content and terminal features (alt screen, mouse mode, cursor, etc.).

```crystal
  def view : Tea::View
    s = "What should we buy at the market?\n\n"

    @choices.each_with_index do |choice, i|
      cursor = i == @cursor ? ">" : " "
      checked = @selected.includes?(i) ? "x" : " "
      s += "#{cursor} [#{checked}] #{choice}\n"
    end

    s += "\nPress q to quit.\n"
    Tea::View.new(s)
  end
end
```

### Running the Program

Create a program with your initial model and run it:

```crystal
model = ShopModel.new
program = Tea.new_program(model)
_result, err = program.run
if err
  puts "Error: #{err}"
  exit(1)
end
```

Save this as `shop.cr` and run:

```bash
crystal shop.cr
```

Press the up/down arrows to move the cursor, space to toggle items, and `q` to
quit.

---

## Installation

Add to your `shard.yml`:

```yaml
dependencies:
  bubbletea:
    github: dsisnero/bubbletea
```

Then:

```bash
shards install
```

---

## Components

This port tracks the upstream [charmbracelet/bubbletea][upstream] runtime.
Common UI widgets (text inputs, viewports, spinners, tables, etc.) are in
the companion [charmbracelet/bubbles][bubbles] library, vendored at
`vendor/bubbles` (v2.1.1) — porting in progress.

---

## Debugging

### Logging to a file

Since Bubble Tea occupies the terminal, log to a file for debugging:

```crystal
if ENV["DEBUG"]?
  Tea.log_to_file("debug.log", "DEBUG")
end
```

Watch in real time with `tail -f debug.log` in another terminal.

---

## Documentation

| Document | Purpose |
|----------|---------|
| [Architecture](docs/architecture.md) | System design, data flow, package responsibilities |
| [Development](docs/development.md) | Prerequisites, setup, daily workflow |
| [Coding Guidelines](docs/coding-guidelines.md) | Code style, error handling, naming conventions |
| [Testing](docs/testing.md) | Test commands, conventions, patterns |
| [PR Workflow](docs/pr-workflow.md) | Commits, PRs, branch naming, review process |
| [Porting Parity](docs/porting-parity.md) | Upstream source tracking and parity verification |
| [Upgrade Guide v2](docs/upgrade_guide_v2.md) | Migration from v1 to v2 (Crystal-specific) |

## Libraries used with this port

- [Lip Gloss][lipgloss] — Style, format and layout tools (Crystal port)
- [Bubbles][bubbles] — Common UI components (port in progress)
- [Harmonica][harmonica] — Spring animation library (Crystal port)
- [Ultraviolet][ultraviolet] — Terminal I/O, ANSI parsing, event system

[upstream]: https://github.com/charmbracelet/bubbletea
[bubbles]: https://github.com/charmbracelet/bubbles
[lipgloss]: https://github.com/dsisnero/lipgloss
[harmonica]: https://github.com/dsisnero/harmonica
[ultraviolet]: https://github.com/dsisnero/ultraviolet

## Development

```bash
make install   # Install dependencies
make test      # Run specs
make format    # Format Crystal code
make lint      # Run Crystal linter
```

See [Development Guide](docs/development.md) for full setup.

## Upstream Parity

This port tracks upstream `github.com/charmbracelet/bubbletea` at **v2.0.8**
(revision `fc707bb`). See [Porting Parity](docs/porting-parity.md) for the
current inventory and drift checks.

## Contributing

See [PR Workflow](docs/pr-workflow.md) for commit conventions and review
process.

## License

[MIT](LICENSE)

---

Part of the Crystal port of [Charm](https://charm.sh) tools.
