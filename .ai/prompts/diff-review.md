# Prompt — Diff Review

> Paste this to review staged/uncommitted changes. Rules from
> [`.ai/OPERATING_SYSTEM.md`](../OPERATING_SYSTEM.md) apply.

You are reviewing the current diff in the Tilawa repo. **Mode: Diff review only.
Do NOT edit any file — report findings only.**

1. Look at the actual changes:
   ```sh
   git status
   git diff            # unstaged
   git diff --staged   # staged
   ```
   Consider both together as the proposed change.

2. **Report findings grouped by severity** (Blocker / Should-fix / Nit), each
   with `file:line` and a concrete fix. Cover:

   - **Unrelated changes** — anything not tied to a single coherent task:
     drive-by edits, stray reformatting, import re-sorting, debug prints,
     commented-out code, accidental file additions.
   - **Risky changes** — auth, payment, booking (`quran_sessions`), routing,
     delete-account, state management, offline, `firestore.rules`,
     `firestore.indexes.json`, Cloud Functions (`functions/`), build/flavor/CI.
     Flag new Firestore collections lacking matching rules.
   - **Correctness/architecture** — layer violations (`BuildContext` below
     presentation, throwing across boundaries instead of `Either`), get_it/bloc
     misuse, hard-coded colors/sizes/strings instead of tokens + `context.l10n`.
   - **Missing tests** — new behavior or fixed bugs without a test; weakened or
     deleted existing tests.
   - **Manual QA needs** — screens/flows a human must click through (light/dark,
     RTL/LTR, loading/empty/error), and which risk level applies.

3. **Verdict:** one of
   `SAFE TO ACCEPT` / `ACCEPT AFTER FIXES` / `NEEDS REWORK`,
   plus the top 1–3 things to address first, and the checks the author should
   run before merge (`melos run analyze`, `melos run test`, functions
   `npm run test:emulator`).

Do not run formatters or apply fixes — just review.
