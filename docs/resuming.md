# Resuming Work

This is the first thing to read in a new session. It takes a few minutes to get
back to a known-good state.

## 1. Read where we are

- `plans/parity.md` — start at the **Where we are** block. It names the current
  focus, the ordered "Next up" list, per-area chunk status, the last commit, and
  the current gate results. Do not re-derive state from git history.
- `plans/inventory/go_port_inventory.tsv` — the per-symbol ledger (status +
  `crystal_refs`), keyed to the baseline in its leading `# baseline=` comment.
  Run `make check-port-inventory` before trusting it: it fails on a stale row
  and on a `crystal_refs` file that no longer exists. Use it to see what is left
  inside the current chunk:

  ```bash
  grep -v '^#' plans/inventory/go_port_inventory.tsv \
    | cut -f3 | sort | uniq -c
  ```

Two ledger layers exist and they answer different questions:

| Layer | Path | Checked by |
| ----- | ---- | ---------- |
| Coarse, curated | `docs/go_*.tsv` | `make check-go-*-parity` (`bin/check_go_*.sh`) |
| Per-symbol, authoritative | `plans/inventory/go_*.tsv` | `make check-port-inventory` / `check-source-parity` / `check-test-parity` |

The per-symbol checks are thin wrappers in `./scripts/` that `exec` the current
scripts of the installed `cross-language-crystal-parity` skill (see the
**Parity tooling** section of `AGENTS.md`); the repository keeps no copy of the
implementation.

## 2. Confirm the working tree

```bash
git log --oneline -10
git status
```

The last commit should be the previous feature (`port: ...`), committed
atomically. If the tree is dirty, finish or stash before starting.

## 3. Confirm a clean baseline

```bash
make format
make lint
make test
make verify-parity-skill
make check-parity
```

All five must pass before changing anything. `make check-parity` must report
`PARITY_DISCOVERY_BACKEND=regex` and forward to the installed skill scripts; if
it reports a missing canonical script, install the
`cross-language-crystal-parity` skill or set `PARITY_SKILL_DIR`. Any ledger
drift it reports should be compared with the **Where we are** block — recorded
upstream drift may be the next feature to fix.

## 4. Pick the next feature

Take the first item in the **Next up** list (or the next `[ ]` item in the
current phase). For each feature:

1. Read the upstream source under `vendor/bubbletea` and the nearest upstream
   tests.
2. Port the tests first (red → green); never weaken assertions.
3. Satisfy the **Definition of done** in `AGENTS.md` (API, tests, gates,
   inventory rows, `plans/parity.md` status + **Where we are** refresh,
   divergences).
4. Commit atomically with the `port: ...` message format from `AGENTS.md`.

## If the plan is split

When `plans/parity.md` grows too large it is split into `plans/<area>.md`
files. In that case every split file is linked from `plans/parity.md`, and
`plans/parity.md` marks each file complete/in-progress and names the file being
worked on plus the next file/phase to start.

## Environment notes

- Parity gates resolve the skill through `PARITY_SKILL_DIR` (default
  `${HOME}/.agents/skills/crystal_forge/skills/cross-language-crystal-parity`)
  and export `PORT_PARSER=regex`, matching the ledger policy. Override either
  variable only with a reviewed reason.
- Keep caches under `./temp/cache`; `make` exports `CRYSTAL_CACHE_DIR`,
  `SHARDS_CACHE_PATH`, `GOCACHE`, and `GOMODCACHE` there. Use
  `source ./scripts/parity_env.sh` (or `make parity-shell`) for the same
  environment in a bare shell.
- On exFAT or network volumes macOS writes AppleDouble `._*` sidecars. A
  `._foo_spec.cr` sidecar breaks spec discovery; delete them with
  `find . -name '._*' -delete`. If a git pack operation prints
  `non-monotonic index .../._pack-*.idx`, run
  `find .git -name '._*' -delete`.
- Submodules must be initialized (`git submodule update --init --recursive`)
  before parity checks, since they compare against `vendor/bubbletea`.
