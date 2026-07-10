# Prompt — Test Coverage

> Paste this, then name what to test. Rules from
> [`.ai/OPERATING_SYSTEM.md`](../OPERATING_SYSTEM.md) apply.

You are adding or improving tests in the Tilawa repo. **Mode: Test only —
do not change non-test source code.** If a test can only pass by changing
production code, stop and report it (that's a bug, not a test task).

1. **Identify existing patterns FIRST.** Before writing anything:
   - Find sibling tests under `test/features/<feature>/` (app) or the package's
     `test/` dir and mirror their structure, naming, and helpers.
   - Conventions here: `package:test` + `package:checks` assertions; **fakes over
     mocks** (mockito only when a fake is impractical); widget tests wrap in
     `MaterialApp` with `AppTheme.getLightTheme(...)` + l10n delegates; bloc
     tests pump `BlocProvider` with test fakes. Reuse existing fakes (e.g.
     `test/features/athkar/helpers/`). Functions tests: `functions/test/`
     (`node --test`), integration/rules under `test-integration/`, `test-rules/`.

2. **Write tests with real value.** Each test must assert **behavior**, cover a
   meaningful case (happy path, boundary, error/failure branch, or a past bug).
   - **No fake/coverage-padding tests:** no `expect(true)`, no asserting a mock
     was called with no behavioral meaning, no snapshotting current (possibly
     buggy) output, no testing framework/language internals.
   - Prefer a few sharp tests over many shallow ones.

3. **Run them:** `flutter test test/features/<feature>` (or `melos run test`;
   `npm test` / `npm run test:emulator` for functions). Show them passing.
   Optionally `melos run test:coverage`, but coverage % is a side effect, not
   the goal.

4. `melos run fix:format` + `melos run analyze` on the test files.

Report in the §6 format: what behavior each test locks in, patterns you
followed, and any gaps you intentionally left (with why).
