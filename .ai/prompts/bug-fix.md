# Prompt — Bug Fix

> Paste this, then describe the bug. Rules from
> [`.ai/OPERATING_SYSTEM.md`](../OPERATING_SYSTEM.md) apply.

You are fixing a bug in the Tilawa repo. **Mode: Implement. Assume the risk
level I give you; if the bug is in auth/payment/booking/routing/state/firestore,
treat it as High and confirm your plan before editing.**

Follow this order strictly:

1. **Reproduce & root-cause FIRST — do not edit yet.**
   - Read the relevant code paths and state the exact root cause in 1–3
     sentences (which line/condition, and why it produces the wrong behavior).
   - If you cannot pinpoint the cause, say so and ask — do not guess-patch.

2. **Write a failing test first** when practical (bloc/unit/widget test that
   reproduces the bug). Show it failing. If a test is impractical here, explain
   why and describe the manual repro instead.

3. **Fix at the root**, not the symptom. Smallest diff that addresses the cause.
   - No unrelated changes, renames, reformatting, or "improvements."
   - Do not modify or delete existing tests to make things pass.

4. **Verify:**
   - `melos run fix:format` and `melos run analyze`
   - The new test now passes: `flutter test test/features/<feature>`
     (or `melos run test`); functions bug → `npm test` / `npm run test:emulator`
   - Confirm the original repro is gone.

5. **Report** in the §6 format, including: root cause, the regression test added,
   what could break, and any manual QA.

Hard constraints: fix only this bug; if you spot other issues, list them under
"Out of scope / follow-ups" — do not fix them.
