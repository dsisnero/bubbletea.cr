# Agent Instructions

This project uses **bd** (beads) for issue tracking. Run `bd onboard` to get started.

## Quick Reference

```bash
bd ready              # Find available work
bd show <id>          # View issue details
bd update <id> --status in_progress  # Claim work
bd close <id>         # Complete work
bd sync               # Sync with git
```

## Landing the Plane (Session Completion)

**When ending a work session**, you MUST complete ALL steps below. Work is NOT complete until `git push` succeeds.

**MANDATORY WORKFLOW:**

1. **File issues for remaining work** - Create issues for anything that needs follow-up
2. **Run quality gates** (if code changed) - Tests, linters, builds
3. **Update issue status** - Close finished work, update in-progress items
4. **PUSH TO REMOTE** - This is MANDATORY:
   ```bash
   git pull --rebase
   bd sync
   git push
   git status  # MUST show "up to date with origin"
   ```
5. **Clean up** - Clear stashes, prune remote branches
6. **Verify** - All changes committed AND pushed
7. **Hand off** - Provide context for next session

**CRITICAL RULES:**
- Work is NOT complete until `git push` succeeds
- NEVER stop before pushing - that leaves work stranded locally
- NEVER say "ready to push when you are" - YOU must push
- If push fails, resolve and retry until it succeeds

## Crystal Development Guidelines

This is a Crystal port of the Go code from `./vendor/`. Follow Crystal idioms and best practices:

- Use Crystal's built-in formatter: `crystal tool format`
- Use ameba for linting: `ameba --fix` then `ameba` to verify
- Prefer Crystal's standard library over custom implementations
- Use Crystal's type system effectively (avoid unnecessary `as` casts)
- Follow Crystal naming conventions (snake_case for methods/variables, CamelCase for classes)
- Write specs for new functionality using Crystal's built-in spec framework

### Test Porting Guidelines

When porting Go tests to Crystal specs:

1. **Port test logic exactly** - Don't adjust test assertions or expected values
2. **Use Crystal idioms for structure** - Convert Go test tables to Crystal `it` blocks
3. **Mark missing functionality as pending** - Use `pending` for tests that can't run yet
4. **Follow Go test patterns** - Maintain the same test coverage and edge cases
5. **Verify against Go implementation** - Ensure Crystal behavior matches Go exactly

Example: If a Go test expects compressed data of specific size, replicate that check in Crystal even if Crystal's compression produces slightly different output.

## File System Guidelines

- Use `./temp` directory for temporary files created during testing or development
- Never commit temporary files to git (they are already in `.gitignore`)
- Clean up temporary files after use (the `make clean` rule removes `./temp` contents)

