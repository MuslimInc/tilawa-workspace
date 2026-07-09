# Known pre-existing test failures

Failures that already exist on the branch, unrelated to the change currently in
review. Tracked here so they are not attributed to the wrong change and are not
treated as regressions during verification.

## `profile_completion_bloc_test.dart` — 3 `load` failures

**Package:** `packages/quran_sessions`
**Tests:**
- `load emits [Loading, Editing] on success`
- `load loaded state carries the configured minimum student age`
- `load loaded state includes countries from repository`

**Status:** Pre-existing on `feature/learn-quran`. **Not** related to the booking
screen performance work (parallel loads / pricing-quote cold-start). None of the
booking change's files touch profile completion, and these tests fail identically
in isolation before and after that change.

**Root cause:** `ProfileCompletionBloc.load` now emits progressively — first
`ProfileCompletionEditing` with the country list, then a second
`ProfileCompletionEditing` once the cities for the default country resolve. The
tests still assert a single `Editing` state, so `blocTest` reports the second
emit as "longer than expected". This is a stale-test issue in the profile
completion feature, not a product defect.

**Fix (separate change):** update the three `blocTest` expectations to the
two-`Editing` progressive sequence (or assert final state via `verify`), the same
way the booking bloc tests were updated for progressive loading. Owner: profile
completion feature; do not bundle with the booking performance change.
