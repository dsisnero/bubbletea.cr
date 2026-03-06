# PR Workflow

## Commit Conventions

Format: `<type>(<scope>): <description>`

**Types**: feat, fix, docs, refactor, test, chore, perf

### Examples

- `feat(tea): add mouse event handling`
- `fix(renderer): correct cursor positioning`
- `docs(README): update installation instructions`
- `test(parity): add stopwatch example tests`
- `chore(deps): update ameba to v1.0.0`

## Branch Naming

Format: `<type>/<issue-number>-<short-kebab-description>`

### Examples

- `feat/42-add-mouse-support`
- `fix/87-cursor-position-bug`
- `docs/15-update-readme`

## PR Checklist

- [ ] Code follows project guidelines (see [Coding Guidelines](coding-guidelines.md))
- [ ] Tests added/updated (see [Testing](testing.md))
- [ ] Documentation updated (if applicable)
- [ ] CHANGELOG.md updated for user-facing changes
- [ ] Lint/format checks pass (`make format && make lint`)
- [ ] All tests pass (`make test`)
- [ ] Parity verified with upstream Go code

## Review Process

1. **Self-review**: Run `make format`, `make lint`, `make test` before requesting review
2. **Parity check**: Ensure behavior matches upstream Go implementation
3. **Documentation**: Update relevant docs for API changes
4. **Changelog**: Add user-facing changes to CHANGELOG.md
5. **Submit**: Create PR with clear description of changes and testing performed