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

## Final validation record (Phase 7)

**2026-07-10** — after all implementation phases (T001–T039, T041–T044):

| Gate | Command | Result |
|---|---|---|
| Admin unit/component tests | `apps/tilawa_admin: npx ng test --watch=false` | PASS — 43 files, 203 tests |
| Admin production build | `apps/tilawa_admin: npx ng build` | PASS |
| Functions build | `functions: npm run build` (tsc) | PASS |
| Functions unit tests | `functions: npm test` | PASS — 428 tests |
| Functions integration tests | `functions: npm run test:integration` | PASS — 96 tests |
| Firestore rules tests | `functions: npm run test:rules` | PASS — 57 tests |
| Write-boundary audit (T042) | grep for `setDoc/updateDoc/addDoc/deleteDoc/writeBatch/runTransaction` under `apps/tilawa_admin/src/app/features/quran-sessions/` | PASS — zero direct Firestore writes; all mutations via callables/`SESSION_MODERATION_GATEWAY` |

### Performance / read-write impact

- Each resolution is **one callable mutation** followed by **one targeted
  detail refresh** (`loadDetail`); queue pages are not reloaded and no
  collection listeners were added.
- Dispute detail refresh reuses the existing detail read path (dispute doc +
  one booking read + one bounded `getByIds` user lookup) — unchanged from
  the pre-existing read model.
- No new indexes, no global scans, no unbounded queries; pagination
  contracts untouched (verified by the browse-list facade cursor/sort tests).
- Backend adds no reads: resolution callables and their audit writes existed
  before Spec 039; only tests and admin UI were added.

### Known risks

1. **T040 (App Check staging soak) is not executed** — production enforcement
   stays blocked until the § 3a evidence table in
   `docs/quran-sessions/production-readiness-checklist.md` is complete; the
   owner field is still unassigned.
2. **Manual device QA (T045) pending** — Arabic/RTL, narrow-width, and
   failure/retry passes on the two new detail action panels need a human run
   against non-production data before the Hosting deploy.
3. Dispute refund/compensation records are `manual_pending` — operators must
   still execute the financial follow-up outside the panel (pre-existing
   behavior, now reachable from the UI).

### Rollback outcome

- Admin UI: redeploy the prior Hosting artifact — no schema or data
  migration was introduced by Spec 039 (verified: since the spec baseline
  commit 37e24a748, zero changes to `firestore.rules` or
  `firestore.indexes.json`).
- Callables: no production callable contract changed by Spec 039 — the
  entire `functions/src` diff since the spec baseline is a 6-line
  documentation comment in `sessionCallableOptions.ts` — so no callable
  rollback is needed.
- App Check: enforcement default remains off; the config-only rollback is
  documented in the readiness checklist § 3a and the ops runbook.

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

