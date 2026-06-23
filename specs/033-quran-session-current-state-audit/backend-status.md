# Backend Status — Cloud Functions & Jobs

**Root:** `functions/src/quranSessions/`  
**Exports:** `functions/src/index.ts`  
**Audit:** 2026-06-23

**Legend:** ✅ Done | 🟡 Partial | 🔴 Missing | ⚠️ Risky | ⏸️ Postponed

---

## Callable inventory

All HTTPS callables use `enforceAppCheck: false` (⚠️ **Should fix before Free Beta** for prod).

### Session lifecycle (`functions/src/quranSessions/`)

| Callable | File | Auth | Status | Notes |
|----------|------|------|--------|-------|
| **createSessionBooking** | `createSessionBooking.ts` | `requireAuthenticatedUid` (student) | 🟡 | Idempotency ✅; slot lock ✅; **no `meeting_link`** on session doc L177-190 |
| **cancelSessionBooking** | `cancelSessionBooking.ts` | Participant or `token.admin` | ✅ | Actor attribution; slot lock release |
| **requestSessionReschedule** | `requestSessionReschedule.ts` | Participant | ✅ | Writes `quran_reschedule_requests` |
| **confirmSessionReschedule** | `confirmSessionReschedule.ts` | Participant or admin | ✅ | Atomic slot swap |
| **markSessionNoShow** | `markSessionNoShow.ts` | Participant or admin | ✅ | Classification required for student/admin |
| **completeSession** | `completeSession.ts` | Participant or admin | ✅ | Teacher metrics update |
| **issueSessionCompensation** | `issueSessionCompensation.ts` | `requireAdmin` | ✅ | Beta: non-PSP ledger |
| **approveSessionRefund** | `approveSessionRefund.ts` | `requireAdmin` | ⏸️ | Paid Sessions — blocked in Beta |
| **openSessionDispute** | `sessionDisputeCallables.ts` | Participant or admin | ✅ | Lifecycle guard LG-05 |
| **resolveSessionDispute** | `sessionDisputeCallables.ts` | `requireAdmin` | ✅ | `manual_pending` ledger |
| **reportSessionConcern** | `sessionReportCallables.ts` | Authenticated | ✅ | Optional `bookingId` participant check |
| **resolveSessionReport** | `sessionReportCallables.ts` | `requireAdmin` | ✅ | No admin UI wired |

### Teacher & user moderation (outside `quranSessions/`)

| Callable | File | Auth | Status |
|----------|------|------|--------|
| **reviewTeacherApplication** | `reviewTeacherApplication.ts` | `token.admin` | ✅ |
| **moderateTeacherProfile** | `moderateTeacherProfile.ts` | `token.admin` | ✅ |
| **moderateQuranSessionsUser** | `moderateQuranSessionsUser.ts` | `token.admin` | ✅ |

### Scheduled jobs

| Job | File | Schedule | Status | Notes |
|-----|------|----------|--------|-------|
| **expirePendingReservations** | `expirePendingReservations.ts` | Every 5 min | ✅ | Beta no-op on free-only |
| **sessionReminders** | `sessionReminders.ts` | Every 1 hour | 🟡 | 24h/1h tiers; device E2E unverified |

### Firestore triggers

| Trigger | File | On | Status |
|---------|------|-----|--------|
| **deliverSessionNotification** | `deliverSessionNotification.ts` | `quran_session_notifications/{id}` create | 🟡 |
| **syncTeacherProfileVisibility** | `syncTeacherProfileVisibility.ts` | `quran_teacher_profiles/{id}` write | ✅ |

---

## Support modules (not exported)

| Module | Path | Purpose |
|--------|------|---------|
| `sessionAuth.ts` | Auth helpers | `requireAuthenticatedUid`, `requireAdmin`, `resolveActorRole` |
| `bookingEligibilityService.ts` | Server eligibility | Parity with `ValidateBookingEligibilityUseCase` |
| `idempotencyService.ts` | Dedupe | `quran_session_operations` |
| `aggregateWriteService.ts` | Audit events | `quran_session_events` |
| `financialLedgerService.ts` | Refunds/comp | `manual_pending` Beta |
| `notificationOutboxService.ts` | Outbox enqueue | On book/cancel/etc. |
| `metricsAggregationService.ts` | Denorm metrics | Teacher/student metrics |
| `paymentProviderStatus.ts` | Paid gate | `QURAN_SESSIONS_PAYMENT_PROVIDER_ENABLED` default false |
| `sessionLifecycleGuard.ts` | Transitions | Shared with domain |

---

## createSessionBooking — field audit

**Writes booking** (`quran_bookings`): `bookingId`, `studentId`, `teacherId`, `slotId`, `startsAt`, `endsAt`, `callType`, `pricingType`, `lifecycleStatus`, `status` (legacy), pricing fields.

**Writes session** (`quran_sessions`): same minus payment — **missing:** `meetingLink` / `meeting_link`, `studentNote` mirror.

**Post-transaction:** `enqueueSessionNotification` kind `bookingConfirmed` to teacher + student.

**Classification:** 🔴 **Must fix before Free Beta** (US-052).

---

## Payment gate

| Check | Status | File |
|-------|--------|------|
| Paid bookings blocked when PSP off | ✅ | `paymentProviderStatus.ts`, smoke #10 |
| `payment_provider_unavailable` error | ✅ | `createSessionBooking.ts` L74-80 |
| Client skips payment for free | ✅ | `BookingBloc` + `DisabledPaymentProvider` |

**Classification:** ✅ Good enough for Beta (free only).

---

## Idempotency & concurrency

| Check | Status | Evidence |
|-------|--------|----------|
| Idempotency key on create | ✅ | `runIdempotentOperation`, default key `studentId:slotId:startsAt` |
| Slot lock collection | ✅ | `quran_slot_locks` — `already-exists` on race |
| Integration test | ✅ | `test-integration/createSessionBooking.integration.test.ts` |

---

## Admin scripts

| Script | Path | Command |
|--------|------|---------|
| Seed market configs | `functions/scripts/seedMarketConfigs.ts` | `npm run seed:market-configs` |
| List pending applications | `functions/scripts/listPendingTeacherApplications.ts` | `npm run admin:list-pending-applications` |
| Review application (Admin SDK) | `functions/scripts/reviewTeacherApplicationAdmin.ts` | `npm run admin:review-teacher-application` |
| Backfill lifecycle | `functions/scripts/backfillLifecycleStatus.ts` | `npm run quran-sessions:backfill-lifecycle` |
| Backfill booking/session consistency | `functions/scripts/backfillBookingSessionConsistency.ts` | `npm run quran-sessions:backfill-booking-session-consistency` |
| Backfill teacher profiles | `functions/scripts/backfillTeacherProfiles.ts` | `npm run admin:backfill-teacher-profiles` |
| Staging smoke | `functions/scripts/stagingFreeBetaSmoke.ts` | `npm run quran-sessions:staging-smoke` |

---

## Backend test files

**Unit** (`functions/test/quranSessions/` — 9 files): `bookingEligibility.test.ts`, `sessionLifecycleGuard.test.ts`, `sessionLifecycleService.test.ts`, `idempotencyTransaction.test.ts`, `paymentAndIdempotency.test.ts`, `metricsAggregationService.test.ts`, `notificationOutboxService.test.ts`, `sessionReminders.test.ts`, `reportTypes.test.ts`.

**Integration** (`functions/test-integration/`): `createSessionBooking.integration.test.ts`, `idempotency.integration.test.ts`, `resolveSessionDispute.integration.test.ts`, `sessionReports.integration.test.ts`.

**Classification:** US-063 🟡 — run `npm run test:integration` + `npm run test:rules` in CI before deploy.

---

## P0 backend story status

| Story | Status | Gap |
|-------|--------|-----|
| US-047 | ✅ | CF-only writes |
| US-048 | 🟡 | Policies loaded; UI copy sometimes hardcoded |
| US-049 | ✅ | `BookingIntegrityValidator` in CF path |
| US-050 | 🟡 | Missing meeting link |
| US-051 | ✅ | Flutter Firestore repos |
| US-052 | 🔴 | No `meeting_link` write |
| US-053 | ✅ | Cancel callable |
| US-054 | ✅ | Reschedule callables (mobile E2E 🟡) |
| US-055 | 🟡 | Trigger exists; E2E unverified |
| US-056 | 🟡 | Ledger helpers; manual_pending |
| US-057 | 🟡 | Jobs coded; not proven in staging |
| US-060 | ⏸️ | Ops backfill scripts |
