# bubbletea

Crystal port of the [charmbracelet/bubbletea](https://github.com/charmbracelet/bubbletea) Go library, a framework for building terminal user interfaces based on The Elm Architecture.

This is a direct port of the Go implementation, maintaining exact logic and behavior, only differing in Crystal language idioms and standard library usage.

**Source**: The original Go source is available in the `vendor/` submodule at commit [13d882c](https://github.com/charmbracelet/bubbletea/tree/13d882c274bab620b178beac5cce81ed748900bb).

## Installation

1. Add the dependency to your `shard.yml`:

   ```yaml
   dependencies:
     bubbletea:
       github: dsisnero/bubbletea
   ```

2. Run `shards install`

## Usage

```crystal
require "bubbletea"

# See vendor/examples/ for ported examples
```

The API mirrors the Go bubbletea package. Refer to the [original documentation](https://github.com/charmbracelet/bubbletea) for usage patterns.

## Development

This project uses standard Crystal development tools:

```bash
make install   # Install dependencies
make format    # Check code formatting
make lint      # Run ameba linter
make test      # Run specs
make clean     # Clean temporary files
```

Run `bd ready` to find available work (issue tracking via beads).

## Contributing

1. Fork it (<https://github.com/dsisnero/bubbletea/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

**Porting Guidelines**: This is a direct port of Go code. All logic must match the Go implementation exactly. When adding new functionality, ensure it corresponds to upstream changes. Use the `vendor/` submodule as the source of truth.

## Contributors

- [Dominic Sisneros](https://github.com/dsisnero) - creator and maintainer
