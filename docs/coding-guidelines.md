# Coding Guidelines

## Code Style

- **Formatter**: Use Crystal's built-in formatter: `crystal tool format`
- **Linter**: Follow ameba rules (configured in `.ameba.yml`)
- **Line length**: 80 characters maximum
- **Indentation**: 2 spaces (Crystal standard)

## Error Handling

- Use Crystal's exception system for unrecoverable errors
- Return `Result` types (`T | Error`) for recoverable errors
- Match Go error semantics when porting - preserve exact error conditions
- Document error cases in method documentation

## Naming Conventions

- **Files**: `snake_case.cr`
- **Classes/Modules**: `CamelCase`
- **Methods/Variables**: `snake_case`
- **Constants**: `SCREAMING_SNAKE_CASE`
- **Private methods**: Prefix with underscore `_private_method`

## Documentation

- Document public API methods with Crystal doc comments (`#`)
- Include examples for complex methods
- Document porting decisions when they deviate from Go idioms
- Update documentation when changing public API

<!-- TODO: Add examples from the codebase -->