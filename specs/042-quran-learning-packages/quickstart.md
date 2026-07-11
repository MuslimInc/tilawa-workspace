# Quickstart Validation: Quran Learning Packages

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

