# Implementation Plan: Quran Learning Packages

**Branch**: `042-quran-learning-packages` | **Date**: 2026-07-11 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `specs/042-quran-learning-packages/spec.md`

## Summary

Extend the existing Quran Sessions vertical into an Egypt-first, prepaid eight-session private package. Reuse current market gating, verified tutors, availability, booking lifecycle, manual off-app payment, admin callable boundary, notifications, video delivery, and moderation. Add a package order and entitlement aggregate, immutable credit ledger, compatibility meeting, learning plan/reporting, guardian views, and package operations. Keep recurring billing, groups, recording, PSP production payments, and global markets behind later feature gates.

## Technical Context

**Language/Version**: Dart 3.11 / Flutter 3.41; TypeScript 5.7 on Node 22 Cloud Functions; Angular 21.2 / TypeScript 5.9 admin.  
**Primary Dependencies**: flutter_bloc, get_it, go_router, dartz_plus, Firebase Auth/Firestore/Functions/FCM/App Check, AngularFire, existing Tilawa UI Kit and localization.  
**Storage**: Cloud Firestore with server-owned mutations and bounded client reads.  
**Testing**: package:test, flutter_test, package:checks, Node test runner, Firebase emulator/rules tests, Angular Vitest/component tests, manual device and staging E2E.  
**Target Platform**: Android-first Tilawa mobile app, responsive Angular admin, Firebase backend; Egypt production market initially.  
**Project Type**: Flutter mobile + shared Dart package + Firebase backend + Angular admin.  
**Performance Goals**: O(1) package/credit mutation by document id; teacher/package lists bounded and paginated; no new frame-jank path; user-visible mutations refresh authoritatively; 100 concurrent final-credit attempts remain correct.  
**Constraints**: Egypt-only, EGP, eight 30-minute sessions, 35-day validity, 12-hour protected cancellation, one teacher, manual payment/renewal, no child recording, no direct operational Firestore writes, no global scans, no production enablement without staging evidence and explicit GO.  
**Scale/Scope**: launch target 10,000 registered learners, 1,000 active packages, 100 concurrent booking attempts, closed pilot of at least 100 paid sessions; nine stories with only US1–US7 eligible for the Egypt release and US8–US9 gated later.

## Constitution Check

*GATE reviewed before research and after design: PASS.*

- **Clean Architecture**: package entities, failures, repositories, and use cases live in `packages/quran_sessions`; Firebase implementations remain in the host app; privileged mutations remain Cloud Functions; admin uses facade/use-case/gateway layers.
- **Reactive state/routing**: package, trial, progress, and guardian workflows use explicit BLoC/Cubit states and typed GoRouter routes. Widgets retain ephemeral state only.
- **UI Kit/localization**: reuse Tilawa cards, status surfaces, buttons, sheets, skeletons, tokens, Flex spacing, and `context.l10n`; add shared UI only when broadly reusable.
- **Performance**: atomic transaction documents and denormalized bounded summaries avoid ledger scans in UI; pagination is mandatory; package list/profile work receives rebuild and frame-budget review.
- **Observability**: structured events correlate order, package, booking, credit movement, and admin action without lesson content or child/payment secrets.
- **Safe delivery**: additive collections/contracts, market kill switches, manual payment default, backwards-compatible individual booking, staging deployment, reconciliation, and rollback before production.
- **Testing**: domain, mapper, BLoC, widget, callable, integration, rules, authorization-negative, concurrency, idempotency, RTL/accessibility, and manual device tests are required.
- **Post-design re-check**: PASS; no waiver or constitutional violation is required.

## Architecture Decisions

1. **Model a prepaid package, not a recurring subscription.** Renewal creates another entitlement period. No billing engine, dunning, or proration enters the MVP.
2. **Use an entitlement aggregate plus immutable ledger.** The package document holds authoritative counters and version; every movement has a deterministic key. Transactions update counters, movement, and booking link atomically.
3. **Keep booking lifecycle authoritative.** Package credit is an additional pricing/entitlement source; existing slot locks and lifecycle transitions remain the source of scheduling truth.
4. **Separate order from entitlement.** Pending manual payment creates an order only. Confirmation creates the entitlement once; rejection never creates credit.
5. **Snapshot commercial terms.** Price, currency, duration, validity, cancellation policy, payment instructions version, and teacher are immutable for a purchased period.
6. **Reuse guardian and child-age policy.** Extend the existing profile boundary; do not create a separate child identity system.
7. **Make progress a package-owned learning record.** Lesson reports reference existing sessions and expose a safe projection separately from internal moderation data.
8. **Keep groups as a new aggregate.** Do not weaken the current `group_booking_not_supported` guard until cohort capacity, attendance, privacy, and shared delivery pass their own gate.
9. **Keep global expansion configuration-gated.** Every market owns catalog, currency, payment, legal, localization, teacher eligibility, and rollout evidence.

## Data and Transaction Boundaries

- `quran_package_plans/{planId}`: market-scoped plan controlled by admin callable.
- `quran_package_orders/{orderId}`: order and payment snapshot; server writes only.
- `quran_student_packages/{packageId}`: entitlement, counters, lifecycle, teacher/student/guardian references.
- `quran_student_packages/{packageId}/credit_movements/{movementId}`: immutable movement ledger.
- `quran_compatibility_meetings/{meetingId}`: bounded trial and recommendation.
- `quran_learning_plans/{packageId}`: baseline/goal/summary.
- `quran_lesson_reports/{sessionId}`: structured session outcome plus safe projection.
- Existing bookings/sessions gain optional `packageId`, `packagePlanId`, and `packageCreditMovementId`; pay-per-session behavior remains unchanged when absent.
- Admin audit events continue through the existing operational audit pattern.

## Security and Privacy

- Auth and valid session epoch are required for participant calls; granular admin claims are required for payment and adjustment calls.
- Client writes to plan/order/package/credit/learning-report operational collections are denied.
- Participant reads are limited to learner, verified guardian, assigned teacher, and authorized admin projections.
- Child contact details, payment proof, private teacher notes, and moderation data do not enter public profiles, analytics, FCM payloads, or client-readable reports.
- App Check promotion follows staged evidence; it is not silently enabled by source defaults.
- No child video recording or archive is introduced.

## Delivery Phases

### Phase A — Foundation and Package Sale

Plan/order/package schemas, config, manual payment, admin queue, activation, rules, idempotency, metrics, and kill switches.

### Phase B — Credit-Aware Booking

Atomic reserve/consume/restore, lifecycle compensation, balance/activity UI, concurrency tests, expiry and reconciliation.

### Phase C — Trust and Learning Outcomes

Verified tutor discovery/profile, compatibility meeting, learning plan, lesson report, homework, summary, guardian oversight.

### Phase D — Renewal and Egypt Release

Manual renewal, expiry clarity, staging E2E, App Check, legal/privacy, operational readiness, pilot, rollback, and staged production rollout.

### Phase E — Separately Gated Expansion

Small cohorts, then new markets/languages/payment methods, then institutional programs. Each requires a new GO decision.

## Performance and Cost Analysis

- Order activation is one transaction over the order, package, initial audit/movement, and notification outbox references: O(1).
- Credit booking/cancellation is O(1) by package and booking ids. UI never recomputes balance by scanning the ledger.
- Activity and admin queues use cursor pagination and bounded page sizes.
- Teacher discovery retains existing indexed market/profile queries; new filters require explicit index review before deploy.
- Progress screens read one plan plus bounded recent reports; end summaries are stored projections rather than repeated full-history reductions.
- No listener is added to an unbounded collection. Expected incremental cost is a small constant number of reads/writes per package operation.

## Rollout and Rollback

- Flags: global Quran Sessions, booking, Egypt market, package sales, package booking, compatibility meeting, guardian surfaces, and later cohorts.
- Start with internal accounts, then a closed curated cohort, then 5%/25%/100% Egypt rollout only after gates pass.
- Rollback disables package sales first, then package booking if integrity is at risk; historical data remains readable.
- Reconciliation compares package counters, movement ledger, and linked bookings. Any mismatch blocks promotion.
- Existing free/pay-per-session behavior remains available according to its own flags and is not migrated automatically.

## Project Structure

### Documentation

```text
specs/042-quran-learning-packages/
├── spec.md
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   └── package-callable-contracts.md
├── checklists/requirements.md
└── tasks.md
```

### Source Code

```text
packages/quran_sessions/
├── lib/src/domain/{entities,failures,repositories,usecases}/
├── lib/src/presentation/{blocs,screens,widgets}/
├── l10n/
└── test/{domain,presentation}/

apps/tilawa/lib/features/quran_sessions/
├── data/firebase/
├── di/
└── router/

functions/
├── src/quranSessions/{packages,learning}/
├── test/quranSessions/
├── test-integration/
└── test-rules/

apps/tilawa_admin/
├── src/app/core/{domain,data,application}/
├── src/app/features/quran-sessions/{package-plans,package-orders,student-packages}/
└── l10n/

firestore.rules
firestore.indexes.json
docs/quran_sessions/
```

**Structure Decision**: Extend the established Quran Sessions package/host/backend/admin boundaries. Backend package code is grouped below `functions/src/quranSessions/packages/` and learning outcomes below `learning/` to avoid growing existing lifecycle files into mixed-responsibility modules.

## Complexity Tracking

No constitutional violation or waiver is required. New aggregates are justified because a prepaid entitlement and a group cohort have lifecycle and accounting invariants that cannot be safely represented as fields on an individual booking.

