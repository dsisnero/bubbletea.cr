# bubbletea.v2 — v2.0.6 → v2.0.8 Update Plan

**Upstream:** `github.com/charmbracelet/bubbletea`  
**Current pinned:** `fdcd0cf` (v2.0.6)  
**Target:** `fc707bb` (v2.0.8)  
**Submodule:** `vendor/bubbletea`

---

## Changes between v2.0.6 and v2.0.8

Only two functional code changes (plus test-only and CI/maintenance):

### 1. Data race fix — `cursed_renderer.go` `onMouse` (v2.0.7)

| Go diff | Crystal file |
|---------|-------------|
| Wrap `s.lastView.OnMouse` access in `s.mu.Lock()`/`s.mu.Unlock()` | `src/tea/cursed_renderer.cr` |

Go change:
```go
func (s *cursedRenderer) onMouse(m MouseMsg) Cmd {
    var onMouse func(MouseMsg) Cmd
    s.mu.Lock()
    if s.lastView != nil {
        onMouse = s.lastView.OnMouse
    }
    s.mu.Unlock()
    if onMouse != nil {
        return onMouse(m)
    }
    return nil
}
```

Crystal current (`src/tea/cursed_renderer.cr:656`):
```crystal
def on_mouse(msg : MouseMsg) : Cmd?
  if last = @last_view
    if on_mouse_handler = last.on_mouse
      return on_mouse_handler.call(msg)
    end
  end
  nil
end
```

**Fix:** Wrap `@last_view` access in `@mutex.synchronize`.

### 2. Skip input reader restore when input is nil (v2.0.8)

| Go diff | Crystal file |
|---------|-------------|
| Guard `initInputReader` behind `if p.input != nil` in `RestoreTerminal` | `src/tea.cr` `restore_terminal` |

Go change:
```go
func (p *Program) RestoreTerminal() error {
    if err := p.initTerminal(); err != nil {
        return err
    }
    if p.input != nil {
        if err := p.initInputReader(false); err != nil {
            return err
        }
    }
    p.startRenderer()
    ...
}
```

Crystal current (`src/tea.cr:991`):
```crystal
def restore_terminal : Exception?
  if err = init_terminal
    return err
  end
  err = init_input
  return err if err
  err = init_input_reader(true)   # <-- no nil guard
  return err if err
  start_renderer
  spawn { check_resize }
  nil
end
```

Note: `run` already has this guard (line 449). `restore_terminal` is missing it.

---

## Related: vendor/bubbles added

- `vendor/bubbles` submodule was added at `charmbracelet/bubbles` v2.1.1 (`d2b2217`)
- No Crystal port of bubbles components exists yet — that is a separate effort

---

## Plan

### Phase 1: Update submodule

- [x] Checkout vendor/bubbletea at v2.0.8 (`fc707bb`)

### Phase 2: Apply cursed_renderer data race fix [PR #1691]

- [x] Write test: `spec/tea_spec.cr` — `MouseRaceModel` concurrent mouse events
- [x] Apply `on_mouse` mutex locking in `src/tea/cursed_renderer.cr`
  - Go: `s.mu.Lock()` / `s.mu.Unlock()` around `s.lastView.OnMouse`
  - Crystal: `@mutex.synchronize { @last_view.try(&.on_mouse) }`

### Phase 3: Apply input reader nil guard fix [PR #1680]

- [x] Write test: `spec/exec_spec.cr` — `Exec with nil input`
- [x] Add `if @input` guard around `init_input_reader(true)` in `src/tea.cr` `restore_terminal`

### Phase 4: Verify

- [x] `make format`
- [x] `make lint` (pre-existing issues in bubbletea-examples submodule only)
- [x] `make test` — 134 examples, 0 failures
