# bubbles.1 — viewport `parseMatches` desyncs on any non-ASCII content, so highlights land nowhere

| | |
| --- | --- |
| **Shard** | `dsisnero/bubbles` (Crystal port of `charmbracelet/bubbles`) |
| **Tested at** | `main` = `20ec13a7edae1175570b7f4b273a81995c4c627f` |
| **Upstream pin** | `vendor/bubbles` **v2.2.2** (`0c1a491`) |
| **Severity** | High — search highlighting is silently wrong for any file that isn't pure ASCII |
| **Status** | Open |
| **Blocker for** | `bubbletea.cr` example parity: `examples/pager` (`spec/pager_parity_spec.cr`) |

## Summary

`Bubbles::Viewport.parse_matches` returns a wrong — usually empty — `HighlightInfo`
whenever the viewport content contains a multi-byte character *before* a match.
The parsed result is what `highlight_lines` turns into `Lipgloss::Range`s, so a
non-empty result becomes empty and **the highlight is never drawn**. When it is
non-empty it is misplaced (wrong line, wrong columns).

Go highlights correctly for every case below, so this is a port bug, not an
upstream behaviour change.

Only the *first* multi-byte character matters: pure-ASCII content (with or
without newlines) works.

## Reproduction

Minimal, Crystal only — no Go needed:

```crystal
# in bubbletea-examples, where lib/bubbles is installed
require "../spec/spec_helper"
require "bubbles"

content = "l’2 artichoke"      # U+2019 RIGHT SINGLE QUOTATION MARK
style   = Lipgloss::Style.new.background(Lipgloss.color("34"))

enc = content.to_slice
idx = (0..enc.size - 9).find { |i| enc[i, 9] == "artichoke".to_slice }.not_nil!

hi = Bubbles::Viewport.parse_matches(content, [[idx, idx + 9]] of Array(Int32))
pp hi.map(&.lines)                                    # actual:   [{}]
pp Lipgloss.style_ranges(content,
  Bubbles::Viewport.make_highlight_ranges(hi, 0, style))   # actual:   no escapes

# ASCII control: "l2 artichoke" (bytes 3..12) gives {0 => {3, 12}} and styles correctly.
```

Expected in the failing case: `[{0 => {4, 13}}]`, which then styles `artichoke`.
The match is at bytes `6..15`; graphemes are `l`=0, `’`=1, `2`=2, ` `=3, so the
match starts at grapheme 4.

### Case matrix

Width 40, height 3, one highlight range, byte offsets from `strings.Index(content, "artichoke")`.
Crystal column from the port; Go column from the pinned `vendor/bubbles` v2.2.2.

| # | content | Go | Crystal |
| --- | --- | --- | --- |
| 1 | `l’2 artichoke` | highlighted | **not highlighted** |
| 2 | `line1\nl2 artichoke` (ASCII) | highlighted | highlighted |
| 3 | `lin’e1\nl2 artichoke` | highlighted | **not highlighted** |
| 4 | `line1\nl’2 artichoke` | highlighted | **not highlighted** |
| 5 | `line1\nl’artichoke` | highlighted | **not highlighted** |
| 6 | `lin你e1\nl2 artichoke` (wide) | highlighted | **not highlighted** |

## Impact: `examples/pager`

The pager example highlights every `artichoke` in `artichoke.md` (which contains
`’`, `—`, `你好`, `─`). `spec/pager_parity_spec.cr` fails: the Go golden is 1795
bytes, the Crystal capture 1770 — the missing 25 bytes are the repaints of the
two highlighted words in the second frame.

View-level differential (state A = after `WindowSizeMsg{80,24}`, state B = after
`j`), comparing `View()`/`view` strings:

```text
Go     A: ... 6 │ ## Let’s talk about \x1b[38;5;238;48;5;34martichoke\x1b[m ...
Crystal A: ... 6 │ \e[38;2;68;68;68;48;2;0;175;0m#\e[m# Let’s talk about artich...
```

Crystal styles a single `#` at column 0 instead of the word.

`parse_matches` for the real file, compared with what the byte offsets mean
(0-based line, grapheme columns):

| match | bytes | expected | Crystal parse |
| --- | --- | --- | --- |
| 0 | 71..80 | line 5, `(20, 29)` | `{4=>{28,29}, 5=>{0,1}, 6=>{0,7}}` |
| 1 | 88..97 | line 7, `(5, 14)` | `{6=>{15,24}}` |
| 2 | 216..225 | line 8, `(55, 64)` | `{7=>{65,74}}` |
| 3 | 549..558 | line 16, `(5, 14)` | `{14=>{61,64}, 15=>{0,1}, 16=>{0,5}}` |
| 4 | 1471..1480 | line 62, `(17, 26)` | `{60=>{41,50}}` |
| 5 | 1579..1588 | line 67, `(39, 48)` | `{}` |

## Root cause

`lib/bubbles/src/bubbles/viewport/highlight.cr:40` `parse_matches` is a port of
`vendor/bubbles/viewport/highlight.go:19` `parseMatches`. The Go walker keeps
`rem` as a **byte** slice and does `rem = rem[n:]` (highlight.go:43), where `n`
is the byte length returned by `ansi.DecodeSequence`.

The Crystal port keeps `remaining` as a `String` and advances it with
`String#[]`, which slices by **character**:

```crystal
# highlight.cr:56-58
seq, width, n, new_state = Ansi.decode_sequence(remaining, state, nil)
state = new_state
remaining = remaining[n..]? || ""      # n is a byte count, [] indexes characters
```

while the loop bookkeeping counts bytes (`byte_pos += n`, highlight.cr:84, 114).
The two diverge on the first multi-byte rune, the `while byte_start > byte_pos`
walk consumes the wrong number of runes, and `highlight_info.lines` is written
with a range that is empty or on the wrong line.

A second divergence worth checking while you are in here: `grapheme_pos` is
advanced by display width (`grapheme_pos += Math.max(1, width)`,
highlight.cr:82/112) and the resulting columns are later fed to
`Lipgloss.style_ranges`, which indexes **cells**. Go has the same `max(1, width)`
expression, so verify the two agree for wide characters (case 6 above) once the
slice bug is fixed.

## Suggested fix

Walk bytes, not characters — keep an explicit offset into `content.to_slice` and
slice by bytes, e.g.

```crystal
bytes = content.to_slice
pos = 0
next_sequence = -> do
  return nil if pos >= bytes.size
  seq, width, n, new_state = Ansi.decode_sequence(bytes[pos, bytes.size - pos], state, nil)
  state = new_state
  pos += n
  {seq, width, n}
end
```

and use `pos` in place of both `remaining`-relative slicing and the manual
`byte_pos += n` so the two cannot drift apart again.

## Regression test to add

The minimal repro above is a good spec: one multi-byte character before the
match must still produce `{0 => {colstart, colend}}`, plus the ASCII control so
the spec proves it is the multi-byte case that is handled. Cases 3, 5 and 6 from
the matrix cover the newline interaction, the "multi-byte immediately before the
match" edge and wide characters.

## Verification

After the fix in `bubbletea-examples` (with `shards` pointed at the new build):

```bash
cd bubbletea-examples
crystal spec spec/pager_parity_spec.cr        # must pass: 1795-byte golden
crystal spec                                   # 82 examples, 0 failures
```

`spec/pager_parity_spec.cr` is the guard: its golden is generated from
`vendor/bubbletea/examples/pager` and `vendor/bubbles` v2.2.2, so it will catch a
regression in this path.
