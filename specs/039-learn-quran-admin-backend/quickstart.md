# Quickstart: Validate Learn Quran Admin and Backend Completion

## Local quality gate

```sh
cd apps/tilawa_admin
npm test
npm run build
```

```sh
cd functions
npm run build
npm test
npm run test:emulator
```

## Recorded baseline outcomes

**2026-07-10** — after Phase 1–2 and the US1 batch (T001–T003, T005–T021):

| Gate | Command | Result |
|---|---|---|
| Admin unit/component tests | `apps/tilawa_admin: npx ng test --watch=false` | PASS — 39 files, 177 tests |
| Admin production build | `apps/tilawa_admin: npx ng build` | PASS |
| Functions unit tests | `functions: npm test` | PASS — 427 tests |
| Functions integration tests | `functions: npm run test:integration` | PASS — 92 tests (Firestore emulator) |

The previously failing `TilawaUsersFacade` admin baseline (missing
`localStorage` setup in `I18nService`) is fixed; no unrelated failures remain.

## Admin configuration smoke test

1. Sign in as an administrator and load Global Settings.
2. Use a non-production policy whose age threshold is not 14.
3. Change an unrelated global flag, save, reload, and verify the threshold is
   unchanged.
4. Open Market Pricing and verify video-only is fixed, not an editable market
   choice.
5. Submit an invalid policy value and verify no saved value changes.

## Report and dispute smoke test

1. Use isolated non-production data for an open report and an open dispute.
2. Move the report to under review, then resolve/dismiss with a reason.
3. Resolve the dispute with an allowed outcome and a reason.
4. Verify authoritative terminal state, resolver, timestamp, audit data, and at
   most one financial record where applicable.
5. Retry each terminal action and repeat as a non-administrator; verify no
   duplicate effect and an authorization failure respectively.

## App Check staging evidence

1. Record a named owner and current enforcement state.
2. Enable attestation in staging only.
3. Exercise authenticated pricing, booking, report, dispute, and admin
   resolution flows from attested clients; record successes/rejections.
4. Exercise one non-attested request and verify observable rejection without
   sensitive payload logging.
5. If a critical flow fails, restore the recorded enforcement state and record
   the rollback result. Do not promote until all evidence is complete.

### Staging evidence status

**2026-07-10** — gate prepared, execution pending ops:

- Evidence table (E1–E7), success criteria, owner field, and rollback
  rehearsal record live in
  `docs/quran-sessions/production-readiness-checklist.md` § 3a; the operator
  runbook is in `docs/quran_sessions_admin_ops_checklist.md`.
- Current enforcement state verified off by default at module load
  (`functions/test/quranSessions/sessionCallableOptions.test.ts`).
- ⬜ Owner assignment, staging soak phases 0–3, E1–E7 results, and the
  rollback rehearsal require a staging deploy and calendar time — **not
  executed**; production enforcement remains blocked until § 3a is complete.

