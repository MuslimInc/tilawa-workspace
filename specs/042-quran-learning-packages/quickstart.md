# Quickstart Validation: Quran Learning Packages

## Implementation Baseline — 2026-07-11

Phase 1 stopped before package code because the existing Functions unit suite
is not green on the feature branch baseline:

```text
npm test → 436 tests; 428 pass; 8 fail
```

The failures are outside the package feature:

- Six legacy FCM-token tests build user-document-only Firestore fakes, while
  multi-device login now defaults on and the production token service reads the
  `users/{uid}/devices` subcollection.
- Two legacy session-epoch tests expect stale/missing epochs to fail, while
  multi-device login now defaults on and intentionally bypasses epoch checks.

No package implementation files existed when this baseline ran. Continue Phase
1 only after the owning auth/device work either makes those tests explicitly
select legacy mode or confirms another intended baseline. Do not weaken package
tests or production behavior to compensate for this unrelated failure.

## Foundation Implemented — 2026-07-11 (Phase 2 pure-logic core)

The verifiable, framework-free core of Phase 2 is implemented and green. No
Firestore-transactional, callable, rules, screen, or admin code is written yet;
those require emulator/device/staging verification and are intentionally left
for a session where those harnesses can run.

Delivered and tested:

- **Dart domain** (`packages/quran_sessions`): package/order/entitlement/movement
  entities + value objects with the credit conservation invariant
  (`quran_learning_package.dart`); separate sealed `QuranPackageFailure` family;
  read repository + server-only command gateway contracts; DTOs and
  fail-closed mappers that reject corrupt/inconsistent documents. Exported via
  the package barrel.
- **Functions** (`functions/src/quranSessions/packages`): shared `packageTypes.ts`;
  pure atomic `packageCreditService.ts`
  (issue/reserve/consume/restore/expire/adjust) with deterministic movement ids
  and enforced conservation invariant; `packageAuth.ts` granular admin claims,
  market eligibility, guardian-on-behalf resolution, and role-safe reads;
  `packageLifecycleCreditAdapter.ts` — deterministic policy mapping every
  session terminal status to a credit op (consume/restore/none) with the 12h
  cutoff rule for student cancellations (T033/T039).
- **US1 sale path (Dart, testable slice)**: order use cases
  (`quran_package_order_usecases.dart`, T020) and `PackageOrderBloc` with
  disclosure → submit → pending-payment → resolved states (T025), verified with
  a fake gateway. (Checkout screen/routing T026–T027 and the callables
  themselves remain — they need the emulator/device.)

Test evidence:

```text
packages/quran_sessions: flutter test (new files) → 34 pass, 0 fail; dart analyze lib → no issues
functions:              node --test package suites → 49 pass, 0 fail; tsc --noEmit → clean
```

Credit conservation invariant (enforced in both Dart and TS):

```text
issued + adjustPositive == available + reserved + consumed + expired + adjustNegative
```

`restoredCredits` is a monotonic tally (restore moves reserved → available), not
part of the sum. `consumed`/`expired` are terminal.

Not yet started (need emulator/device/staging + GO gates): T013 projections,
T016 rules, T017 indexes (field-name casing pending the write path), T018 rules
tests, T019 exports/DI, the US1/US2 callables and screens (T021–T024, T026–T032,
T034–T038), and all of US3–US6. The credit engine, lifecycle credit policy, and
US1 order BLoC that these will consume are done and tested.

## Preconditions

- Use Firebase emulators or the designated staging project, never production for initial validation.
- Create student, guardian, verified teacher, package-admin, support-admin, and unauthorized accounts.
- Seed active Egypt package plan, Egypt learner/teacher profiles, availability, manual payment instructions, and required feature flags.
- Keep production PSP/wallet sandbox disabled and child recording absent.

## Automated Verification

From workspace root after implementation:

```sh
melos run fix:format
melos run analyze
melos run test
```

From `functions/`:

```sh
npm run build
npm test
npm run test:integration
npm run test:rules
```

From `apps/tilawa_admin/`:

```sh
npm test
npm run build
```

## Critical E2E A — Purchase and Activate

1. Sign in as Egypt learner or linked guardian.
2. Filter verified teachers and open one eligible profile.
3. Complete a compatibility meeting and recommendation.
4. Review the package disclosure and submit an order.
5. Confirm that balance remains unavailable while payment is pending.
6. Confirm payment as package admin.
7. Verify one active package, eight credits, notifications, and audit.
8. Retry confirmation and verify no duplicate effect.

## Critical E2E B — Book, Cancel, and Reconcile

1. Book an eligible package slot; verify balance becomes seven/reservation state is correct.
2. Cancel before 12-hour cutoff; verify exactly one restoration.
3. Book again and simulate late learner cancellation; verify the credit remains consumed.
4. Simulate teacher cancellation/no-show; verify restoration and eligible extension.
5. Run concurrent final-credit requests; verify one success maximum.
6. Compare package counters, movement ledger, and linked bookings; expect zero mismatch.

## Critical E2E C — Learning and Guardian Safety

1. Activate a child package with verified guardian.
2. Create goal/baseline and complete a paid session.
3. Submit report with covered material, mistakes, homework, safe and private notes.
4. Verify learner/guardian sees safe projection only.
5. Verify unrelated user, revoked guardian, and wrong teacher receive denial.
6. Verify no child recording or private contact information is exposed.

## Admin and Negative Tests

- Lossless plan round-trip and stale-version rejection.
- Non-admin payment/credit/extension denial.
- Non-Egypt purchase denial.
- Expired order confirmation handling.
- Duplicate event/idempotency handling.
- Adjustment cannot create invalid counters.
- Package sales/booking kill switches preserve history.
- Bounded/paginated queues and activity.

## UI / Accessibility QA

- Arabic/English; RTL/LTR; compact/expanded width; light/dark; 200% text scale.
- Loading, empty, failure, retry, pending payment, active, exhausted, completed, expired, and suspended states.
- Screen-reader labels and focus order for purchase, balance, booking, report, and guardian views.
- No hard-coded user strings, colors, spacing, or dimensions.

## Release Evidence

- Record dated automated outputs, staging project/version, tester accounts/roles, device matrix, App Check results, payment aging, reconciliation, rollback duration, legal/privacy approvals, and named GO owners.
- Stop promotion on any P0 financial/credit/child-safety defect, reconciliation mismatch, unauthorized access, or rollback failure.
