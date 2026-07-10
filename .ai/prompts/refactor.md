# Prompt — Refactor

> Paste this, then describe the refactor. Rules from
> [`.ai/OPERATING_SYSTEM.md`](../OPERATING_SYSTEM.md) apply.

You are refactoring code in the Tilawa repo. **Mode: Implement.** Risk depends
on the area (High for auth/payment/booking/routing/state/functions).

The single hard rule: **behavior must not change.** This is a pure refactor.

Do:
- Improve structure/readability/reuse while keeping **identical** observable
  behavior, public APIs, and outputs.
- Keep the diff focused and mechanical where possible.
- Follow existing architecture (flutter_bloc, get_it, GoRouter, `Either`);
  don't introduce new patterns.

Do NOT:
- **Fix bugs.** If you find one, stop and report it — do not fix it in this
  change. (Fixing it hides behavior change inside a refactor.)
- **Redesign** APIs, data models, or UI. Refactor ≠ redesign.
- Change dependencies, build config, or test expectations.
- Modify tests except mechanical updates forced by a rename you were asked to
  do — and call those out explicitly.
- Rename public/package APIs unless that rename **is** the requested task.

Verify behavior is preserved:
- `melos run fix:format` and `melos run analyze` (clean).
- `melos run test` (or the affected feature tests) — the **same** tests that
  passed before must still pass, unchanged. If a test needed changing, that is a
  red flag: stop and explain.
- For state-management refactors: `melos run bloc:lint`.

Report in the §6 format. Explicitly state: "No behavior change" and how the
unchanged passing tests prove it. List any bugs found under follow-ups.
