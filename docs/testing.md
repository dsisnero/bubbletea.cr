# Testing

## Running Tests

```bash
make test                    # Run all specs
crystal spec spec/tea_spec.cr  # Run specific spec file
make parity-specs            # Run example parity tests
```

## Test Conventions

- **Test files**: `*_spec.cr` in `spec/` directory
- **Test organization**: Group related tests in `describe` blocks
- **Example parity tests**: `*_parity_spec.cr` for comparing with Go examples
- **Pending tests**: Use `pending` for missing functionality

## Writing Tests

1. **Port Go tests exactly**: Maintain same test logic and assertions
2. **Use Crystal idioms**: Convert Go test tables to Crystal `it` blocks
3. **Preserve edge cases**: Include all edge cases from Go tests
4. **Mark incomplete**: Use `pending` for tests that can't run yet

Example parity test pattern:
```crystal
describe "Example parity" do
  it "matches Go behavior" do
    # Test logic that should match Go exactly
    pending "Missing feature X" unless implemented?
  end
end
```

## Coverage

- Run all tests before submitting changes
- Ensure parity tests pass when functionality is complete
- Use `pending` rather than skipping tests entirely