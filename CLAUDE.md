# bubbletea.cr

> **How to resume:** read `plans/parity.md` first and use its **Where we are**
> block (current focus + ordered "Next up"), then run `make format`,
> `make lint`, and `make test`. Details: [docs/resuming.md](docs/resuming.md).
> Do not re-derive state from git.

Crystal port of Go's [Bubble Tea](https://github.com/charmbracelet/bubbletea)
TUI framework, vendored at `vendor/bubbletea` (release `v2.1.0`, commit
`f9df43c4f2c021d8740a2628d59cd810a862eb98`). Example apps and their parity
specs live in the `bubbletea-examples` submodule; `vendor/bubbles` (`v2.1.1`)
is the widget upstream for future ports.

## Commands

```bash
make install                 # shards install (deps under ./temp/cache)
make update                  # shards update
make format                  # crystal tool format --check
make lint                    # ameba --fix then ameba
make test                    # crystal spec
make clean                   # wipe ./temp contents
make build-examples          # build bubbletea-examples into ./temp/examples
make check-port-inventory    # per-symbol ledger: plans/inventory/go_port_inventory.tsv
make check-source-parity     # per-symbol ledger: plans/inventory/go_source_parity.tsv
make check-test-parity       # per-symbol ledger: plans/inventory/go_test_parity.tsv
make check-parity            # all per-symbol + coarse ledger checks
make verify-parity-skill     # confirm the installed parity skill + parser backend
make check-go-port-inventory # coarse ledger: docs/go_port_inventory.tsv
make check-go-source-parity  # coarse ledger: docs/go_source_parity.tsv
make check-go-test-parity    # coarse ledger: docs/go_test_parity.tsv
make parity-specs            # run parity specs with local caches
make parity-shell            # print the parity environment setup command
```

`make build-examples` compiles the `bubbletea-examples` sources against this
repository's `src/` and `lib/` into `./temp/examples`, so it does not need the
submodule's own (currently stale) lockfile. Examples that require `bubbles`
are skipped because that shard is a separate port and not a dependency here.

## Docs

- [Resuming work](docs/resuming.md)
- [Architecture](docs/architecture.md)
- [Development](docs/development.md)
- [Coding Guidelines](docs/coding-guidelines.md)
- [Testing](docs/testing.md)
- [PR Workflow](docs/pr-workflow.md)
- [Porting Parity](docs/porting-parity.md)
- [Upgrade Guide v2](docs/upgrade_guide_v2.md)

## Principles

1. Upstream Go behavior is the source of truth; `vendor/bubbletea` wins over
   local preference.
2. Port behavior, not style: Crystal idioms must not change Go semantics.
3. Port upstream tests early and never weaken assertions.
4. Track per-symbol parity in `plans/inventory/`; track status in
   `plans/parity.md`.
5. Commit one completed feature at a time.

## Parity tooling

The active cross-language parity skill is
`${HOME}/.agents/skills/crystal_forge/skills/cross-language-crystal-parity`.
`./scripts/` holds **only thin forwarding wrappers** (`check_port_inventory.sh`,
`check_source_parity.sh`, `check_test_parity.sh`, the `generate_*` entrypoints,
and the shared `parity_skill.sh` resolver) that `exec` that skill's current
scripts. There is no local copy of `check_*.rb`, `generate_*.rb`, or
`parity_inventory_lib.rb`, so updating the skill updates the gate; set
`PARITY_SKILL_DIR` when the skill lives elsewhere. The `*_go_*.sh` names are
`go`-pinned wrappers over the same forwarders.

The curated ledgers (`plans/inventory/go_*.tsv`) use `regex` discovery
vocabulary and `make` exports `PORT_PARSER=regex`, so the gates match the ledger
policy. Keep that mode until a reviewed manifest and ID migration changes it.
Before relying on discovery, run:

```bash
make verify-parity-skill   # verify_skill_install.sh . go regex
make check-parity          # PORT_PARSER=regex wrappers -> canonical scripts
```

Check `PARITY_DISCOVERY_BACKEND` in the gate output and, when manifests are
regenerated, `backend` in their `.metadata.json` files. A requested parser mode
does not prove tree-sitter ran; this repository's authoritative gate is `regex`.
The coarse `docs/go_*.tsv` ledgers are checked separately by the tracked
`bin/check_go_*.sh` scripts (`make check-go-*`), which only assert that upstream
paths and `Complete` Crystal paths exist.

## Session continuity (read this first)

`plans/parity.md` is the single source of truth for where we are. At the start
of every session:

1. Read `plans/parity.md` and use its **Where we are** block to find the
   current focus, the ordered "Next up" list, and per-area chunk status. Do not
   re-derive state from git history.
2. Skim `git log --oneline -10` and `git status` to confirm the working tree.
3. Confirm `make check-parity` forwards to the installed skill scripts and
   reports `PARITY_DISCOVERY_BACKEND=regex`, then run `make format`,
   `make lint`, `make test`, and `make check-parity` before changes to confirm a
   clean baseline.

See [docs/resuming.md](docs/resuming.md) for the full resume checklist.

### Keeping `plans/parity.md` resumable

- `plans/parity.md` starts with a **Where we are** block (`Current focus`,
  `Next up`, chunk status by area). Keep it accurate after every feature.
- Work items are feature-sized (roughly one branch/commit). Per-symbol state
  lives in `plans/inventory/go_*.tsv`, not in the plan.
- The ledgers are **current-state** artifacts of the pinned baseline (each says
  so in its leading `# baseline=` comment). Re-base them when the target release
  changes; never append across versions. Per-release history belongs in
  `plans/bubbletea-v<NN>-update.md`.
- If the plan grows too large, split it into `plans/<area>.md`, link each from
  `plans/parity.md`, and mark each split file complete/in-progress plus the
  file being worked on next.

### Definition of done for every feature (required)

A feature is complete only when all of the following are true, and all of it
must be committed as **one** atomic commit before starting the next feature:

1. the API surface is implemented;
2. upstream tests (or equivalent characterization specs) exist and pass;
3. gates pass: `make format`, `make lint`, `make test`, and `make check-parity`;
4. parity ledger rows for the feature are updated
   (`plans/inventory/go_port_inventory.tsv`) and `make check-port-inventory`
   passes — the canonical skill script checks every row against the pinned tree
   *and* that each `crystal_refs` file still exists, which is the half that rots
   when this repo's own files move;
5. `plans/parity.md` status is updated and the **Where we are** block refreshed
   (current focus + next up);
6. any intentional divergence is documented (in `plans/parity.md` and/or the
   commit message).

### Commit message

```text
port: <feature name>

- what changed (files/areas)
- upstream tests ported
- divergences, if any
- gates: make format / make lint / make test results

Upstream: charmbracelet/bubbletea v2.1.0
(f9df43c4f2c021d8740a2628d59cd810a862eb98)
```

Use `port:` for parity work. Non-porting changes (docs, tooling, CI) use
`<type>(<scope>): <description>` as described in
[docs/pr-workflow.md](docs/pr-workflow.md).

## External Dependencies

- **Upstream Go repository**: `vendor/bubbletea` submodule must be at the
  pinned commit.
  - Verification: `git submodule status`
  - Update: `git submodule update --init --remote vendor/bubbletea`
- **Example apps**: `bubbletea-examples` submodule.
- **Widget upstream**: `vendor/bubbles` at `v2.1.1`.

## Conventions

- Use Crystal idioms without changing Go semantics
- Port test logic exactly from Go tests
- Mark missing functionality as `pending` in specs
- Follow Go test patterns for coverage and edge cases
- Use `./temp` for temporary files and caches
- Never commit temporary files to git

## Debugging

When something breaks, check parity with upstream Go code first. Compare
behavior with `vendor/bubbletea` at the pinned commit.
