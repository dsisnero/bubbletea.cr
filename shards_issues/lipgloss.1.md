# lipgloss.1 — indexed colours are rendered as TrueColor, so SGR sequences don't match Go

| | |
| --- | --- |
| **Shard** | `dsisnero/lipgloss` (Crystal port of `charmbracelet/lipgloss`) |
| **Tested at** | `2.0.4` (as pinned in `bubbletea-examples/shard.lock`) |
| **Go reference** | `charm.land/lipgloss/v2 v2.1.1` (what `bubbletea-examples/goldens` resolves) |
| **Severity** | Medium — silently changes bytes wherever a colour profile is active; no visible effect under `NoTTY` captures |
| **Status** | Open |
| **Blocker for** | nothing currently green, but any future golden captured with a colour profile, and any terminal that supports 256 colours but not TrueColor |

## Summary

Go emits a colour in the space it was declared in: `lipgloss.Color("240")` renders
as the indexed SGR `\e[38;5;240m`, and only the *writer* (the
`colorprofile`/terminal layer) degrades it when the terminal cannot show it.

The Crystal port converts the colour to RGB inside `Style#render`, so the same
colour renders as `\e[38;2;88;88;88m`. The colour is visually equivalent, but the
bytes differ, so any byte-level comparison under a colour profile fails — and
`Spec`-level assertions on rendered sequences cannot match upstream.

## Reproduction

Crystal (`bubbletea-examples`, `lib/lipgloss` at `2.0.4`):

```crystal
require "lipgloss"

Lipgloss::Style.new.foreground(Lipgloss.color("240")).render("hi")
Lipgloss::Style.new.background(Lipgloss.color("34")).render("hi")
Lipgloss::Style.new.foreground(Lipgloss.color("#E7E1CC")).render("hi")
```

Go (`charm.land/lipgloss/v2 v2.1.1`):

```go
lipgloss.NewStyle().Foreground(lipgloss.Color("240")).Render("hi")
lipgloss.NewStyle().Background(lipgloss.Color("34")).Render("hi")
lipgloss.NewStyle().Foreground(lipgloss.Color("#E7E1CC")).Render("hi")
```

| style | Go | Crystal |
| --- | --- | --- |
| `Color("240")` fg | `\x1b[38;5;240mhi\x1b[m` | `\e[38;2;88;88;88mhi\e[m` |
| `Color("34")` bg | `\x1b[48;5;34mhi\x1b[m` | `\e[48;2;0;175;0mhi\e[m` |
| `Color("#E7E1CC")` fg | `\x1b[38;2;231;225;204mhi\x1b[m` | `\e[38;2;231;225;204mhi\e[m` (correct) |

The RGB values are right — the xterm index 240 really is `(88,88,88)` — the
encoding space is wrong.

## Root cause

`lib/lipgloss/src/style.cr:3194` `apply_color_profile` and its TrueColor branch at
`style.cr:3212`:

```crystal
      else # TrueColor
        # In TrueColor mode, convert everything to RGB for consistent rendering
        # This matches Go lipgloss behavior
        case color.type
        when Color::Type::RGB
          color
        else
          r, g, b = color.to_rgb
          Color.rgb(r, g, b)
        end
      end
```

The comment is not accurate: Go lipgloss does **not** rewrite the colour space in
`Render`. It renders the declared space and leaves downgrading to the output
layer — which is why `charmbracelet/bubbletea` output goes through a
`colorprofile.Writer`/ultraviolet renderer that converts per terminal.

Note the port already handles `ColorProfile::ANSI256` correctly (`style.cr:3201`:
`Color::Type::Indexed` is kept as-is). Only the TrueColor (default) branch
collapses the space.

## Suggested fix

In the TrueColor branch, keep the colour in its own space — index stays an index,
named stays named, RGB stays RGB:

```crystal
      when ColorProfile::TrueColor
        case color.type
        when Color::Type::RGB, Color::Type::Indexed, Color::Type::Named
          color
        end
```

Conversion should only happen when the profile genuinely cannot represent the
colour (`ASCII`, `ANSI`, and 256→16/true downsampling), which the earlier branches
already do. Terminals that only speak 256 colours are handled by the writer, as
in Go.

## Regression test to add

```crystal
Lipgloss::Style.new.foreground(Lipgloss.color("240")).render("hi")
  .should eq("\e[38;5;240mhi\e[m")
Lipgloss::Style.new.background(Lipgloss.color("34")).render("hi")
  .should eq("\e[48;5;34mhi\e[m")
# and the RGB input must stay TrueColor:
Lipgloss::Style.new.foreground(Lipgloss.color("#E7E1CC")).render("hi")
  .should eq("\e[38;2;231;225;204mhi\e[m")
```

## Impact

- No current `bubbletea-examples` golden changes: captures run under the `NoTTY`
  profile, which strips all SGR, so both encodings end up as plain text.
- It does change bytes for any capture taken with a colour profile
  (`Tea.with_color_profile(...)`) and for a real 256-colour terminal.
- It was found while porting `examples/textinputs`: the port's view strings were
  otherwise identical to Go's, token for token (37 tokens, same cells and styles),
  with only this encoding as the remaining difference.

## Verification

```bash
cd bubbletea-examples     # or the lipgloss repo's own spec suite
crystal spec              # must stay green: 82 examples, 0 failures
```

If you want a cross-check against Go rather than a hard-coded string, the three
`Render` calls above are enough — they come straight from `lipgloss.NewStyle()`
with no terminal involved.
