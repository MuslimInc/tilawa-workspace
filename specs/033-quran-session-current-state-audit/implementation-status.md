# Implementation Status — Quran Sessions

**Audit:** 2026-06-23  
**Legend:** ✅ Done | 🟡 Partial | 🔴 Missing | ⚠️ Risky | ⏸️ Postponed | ❌ Remove from Free Beta

---

## Layer summary

| Area | Status | % | Key files |
|------|--------|---|-----------|
| **Flutter — student screens** | 🟡 | 62% | `packages/quran_sessions/lib/src/presentation/screens/` |
| **Flutter — teacher screens** | 🟡 | 58% | `teacher_dashboard_screen.dart`, `weekly_availability_screen.dart` |
| **Flutter — routing** | ✅ | 85% | `quran_sessions_routes.dart`, `quran_sessions_nav.dart` |
| **Flutter — feature flags** | ✅ | 90% | `quran_sessions_feature_flags.dart`, `app_launch_config.dart` |
| **Flutter — DI (Firebase)** | ✅ | 88% | `quran_sessions_firebase_module.dart` |
| **Flutter — DI (MVP fake)** | ✅ | 95% | `quran_sessions_mvp_module.dart` |
| **Package — domain** | ✅ | 90% | `packages/quran_sessions/lib/src/domain/` |
| **Package — data interfaces** | ✅ | 85% | DTOs, mappers, repository impls in package |
| **Package — BLoCs/Cubits** | 🟡 | 75% | Join handler stub; reschedule partial |
| **App — Firestore data sources** | ✅ | 80% | `apps/tilawa/.../data/firebase/` |
| **Backend — callables** | 🟡 | 78% | `functions/src/quranSessions/` |
| **Backend — scheduled jobs** | 🟡 | 70% | `sessionReminders.ts`, `expirePendingReservations.ts` |
| **Firestore rules** | ✅ | 88% | `firestore.rules` L98–289 |
| **Firestore indexes** | ✅ | 85% | `firestore.indexes.json` |
| **Admin panel** | 🟡 | 42% | `apps/tilawa_admin/.../quran-sessions/` |
| **Localization** | 🟡 | 50% | `packages/quran_sessions/l10n/` |
| **Payments** | ⏸️ | 10% | Deferred post-Beta |

---

## Flutter app (`apps/tilawa/lib/features/quran_sessions/`)

| Component | Status | Evidence |
|-----------|--------|----------|
| Firebase auth session | ✅ | `firebase_auth_session_provider.dart` |
| User profile Firestore | ✅ | `firestore_user_profile_repository.dart` |
| Teacher Firestore repo | ✅ | `firestore_teacher_repository.dart` |
| Booking Firestore + CF | ✅ | `firestore_booking_repository.dart` → `createSessionBooking` |
| Session aggregate gateway | ✅ | `firebase_session_aggregate_repository.dart` |
| Session command/mutation gateways | ✅ | `firebase_session_command_gateway.dart`, `firebase_session_mutation_gateway.dart` |
| Market config Firestore | ✅ | `firestore_market_config_repository.dart` |
| Session policy Firestore | ✅ | `firestore_session_policy_repository.dart` |
| Teacher application Firestore | ✅ | `firestore_teacher_application_repository.dart` |
| Availability + schedule Firestore | ✅ | `firestore_availability_repository.dart`, `firestore_schedule_repository.dart` |
| Audit repository | ✅ | `firebase_audit_repository.dart` |
| Notification gateway (read outbox) | ✅ | `firebase_session_notification_gateway.dart` |
| Backend mode switch | ✅ | `quran_sessions_backend_config.dart` — `fake` \| `firebase` |
| Analytics callbacks | ✅ | `quran_sessions_analytics.dart` |
| Router integration | ✅ | `quran_sessions_nav.dart` in `app_router.dart` |
| Feature flags resolver | ✅ | `quran_sessions_feature_flags.dart` |
| Disabled payment provider | ⏸️ | `disabled_payment_provider.dart` |

---

## Package (`packages/quran_sessions/`)

| Component | Status | Evidence |
|-----------|--------|----------|
| Public barrel | ✅ | `lib/quran_sessions.dart` |
| Domain entities (session, booking, profile, teacher) | ✅ | `lib/src/domain/entities/` |
| Session lifecycle status enum | ✅ | `session_lifecycle_status.dart` |
| Legacy status bridge | ⚠️ | `legacy_status_lifecycle_mapper.dart` — dual-field era |
| Use cases (40+) | ✅ | `lib/src/domain/usecases/` |
| ValidateBookingEligibilityUseCase | ✅ code / 🔴 tests | `validate_booking_eligibility_usecase.dart` |
| CreateSessionBookingUseCase | ✅ | `create_session_booking_usecase.dart` |
| Cancel/reschedule/no-show/compensation use cases | ✅ | Via server gateways |
| BLoCs: Booking, MySessions, TeacherList, etc. | 🟡 | `MySessionsBloc` join empty |
| SessionDetailBloc | 🟡 | Load only; no actions |
| RescheduleBloc | 🟡 | Screen exists; E2E unverified |
| AvailabilityCubit | ✅ | Tests in `availability_cubit_test.dart` |
| Screens (17 routes) | 🟡 | See screen-inventory gaps |
| Package l10n AR + EN | 🟡 | `l10n/intl_ar.arb`, `intl_en.arb` |
| Failure UI localization | 🟡 | `quran_sessions_failure_ui.dart` |

---

## Backend (`functions/src/quranSessions/`)

| Callable / job | Status |
|--------------|--------|
| `createSessionBooking` | 🟡 — no `meeting_link` |
| `cancelSessionBooking` | ✅ |
| `requestSessionReschedule` | ✅ |
| `confirmSessionReschedule` | ✅ |
| `markSessionNoShow` | ✅ |
| `completeSession` | ✅ |
| `issueSessionCompensation` | ✅ |
| `approveSessionRefund` | ⏸️ paid phase |
| `openSessionDispute` / `resolveSessionDispute` | ✅ CF / 🔴 mobile+admin UI |
| `reportSessionConcern` / `resolveSessionReport` | ✅ CF / 🔴 mobile+admin UI |
| `deliverSessionNotification` | 🟡 — trigger exists; E2E unverified |
| `sessionReminders` | 🟡 |
| `expirePendingReservations` | ✅ |
| `reviewTeacherApplication` (root) | ✅ `functions/src/reviewTeacherApplication.ts` |
| `moderateTeacherProfile` | ✅ |
| `moderateQuranSessionsUser` | ✅ |
| `syncTeacherProfileVisibility` | ✅ |

---

## Admin (`apps/tilawa_admin/`)

| Screen | Status | File |
|--------|--------|------|
| Teacher applications list | ✅ | `teacher-applications.component.ts` |
| Application detail + approve/reject | ✅ | `teacher-application-detail.component.ts` |
| Teachers list | ✅ | `teachers.component.ts` |
| Users list | ✅ | `quran-sessions-users.component.ts` |
| Sessions list | ✅ | `sessions.component.ts` |
| Session detail + CF actions | 🟡 | `session-detail.component.ts` — cancel/no-show/complete/compensation |
| Reports queue | 🔴 | Not in sidebar |
| Disputes queue | 🔴 | Gateway exists; no UI route |
| Policy editor | 🔴 | — |
| Financial ledger UI | ⏸️ | Paid phase |

---

## P0 / Free Beta user story mapping (US-001 – US-072)

Focus: **P0** stories from `specs/032-quran-session-delivery-plan/user-stories.md`.  
Status reflects **code today**, not story intent.

### E-01 Student (US-001 – US-018)

| ID | Title | Status | Implemented | Missing / gap | Tests | Blocker | Action |
|----|-------|--------|-------------|---------------|-------|---------|--------|
| US-001 | Sessions home profile gate | ✅ | `home_sessions_entry_card.dart`, `quran_sessions_nav.dart` | — | Partial app tests | — | QA on staging |
| US-002 | Browse teacher list | 🟡 | `teacher_list_screen.dart`, `FirestoreTeacherDataSource` | Needs seeded teachers | `teacher_list_bloc_test.dart` | US-034 supply | Seed EG teachers |
| US-003 | Teacher profile + availability | ✅ | `teacher_profile_screen.dart` | Reviews list deferred | `teacher_profile_bloc_test.dart` | — | — |
| US-004 | Profile completion + market | ✅ | `profile_completion_screen.dart` | — | `profile_completion_bloc_test.dart` ✅ | — | — |
| US-005 | Booking eligibility inline | ✅ | `booking_screen.dart`, `ValidateBookingEligibilityUseCase` | — | BookingBloc only; **no use case tests** | US-061 | Add eligibility tests |
| US-006 | Book free session | 🟡 | `BookingBloc`, `FirestoreBookingDataSource`, CF | Flag off; staging E2E | `create_session_booking_usecase_test.dart` | US-058, US-034 | Enable staging flag |
| US-007 | My sessions list | ✅ | `my_sessions_screen.dart` | — | `my_sessions_bloc_test.dart` | — | — |
| US-008 | Join via meeting link | 🔴 | Entity field `meetingLink` | CF doesn't set link; join stub | None for join | US-052 | Implement join + link |
| US-009 | Booking confirmation push | 🟡 | Outbox enqueue in CF | Device E2E unverified | `notificationOutboxService.test.ts` | US-055 | Staging FCM test |
| US-010 | Cancel with reason | 🟡 | `cancel_session_sheet.dart`, `CancelSessionViaServerUseCase` | Min reason 3 not 20 chars; server path | `cancel_session_usecase_test.dart` | — | Align validation + wire policy window UI |
| US-011 | Reschedule request | 🟡 | `reschedule_session_screen.dart`, `RescheduleBloc` | E2E to CF unverified | `reschedule_session_usecase_test.dart` | — | Staging E2E |
| US-012 | Submit review | ✅ | `MySessionsBloc` review | Public review list deferred | In bloc test | — | — |
| US-013 | Session reminder push | 🟡 | `sessionReminders.ts` | Device E2E | `sessionReminders.test.ts` | US-055 | Staging job test |
| US-014 | Session detail + actions | 🟡 | `session_detail_screen.dart` | No join/cancel/reschedule/report | None | US-008 | Complete S-08 |
| US-015 | Report safety concern | 🔴 | CF `reportSessionConcern` | Mobile modal S-12 | `sessionReports.integration.test.ts` | US-040 admin UI | Build report UI |
| US-016 | Open dispute | 🟡 | CF `openSessionDispute` | Mobile modal S-13 | Lifecycle tests | US-041 | Build dispute UI |
| US-017 | Filter teachers | ⏸️ | `TeacherListBloc` filter params | Chip UI | Bloc filter events untested widget | Production | Postpone Beta |
| US-018 | English l10n | ⏸️ | Package EN ARB | App-level migration incomplete | — | Production | Postpone Beta |

### E-02 Teacher (US-019 – US-032)

| ID | Title | Status | Implemented | Missing | Tests | Blocker | Action |
|----|-------|--------|-------------|---------|-------|---------|--------|
| US-019 | Start teacher application | 🟡 | `teacher_application_screen.dart` | `teacherApplicationEnabled` false | `teacher_application_bloc_test.dart` | US-058 flag | Enable on staging |
| US-020 | Submit application | ✅ | `SubmitTeacherApplicationUseCase`, CF | — | `submit_teacher_application_usecase_test.dart` | — | — |
| US-021 | Application status | ✅ | `teacher_application_status_screen.dart` | — | Partial | — | — |
| US-022 | Complete public profile | ✅ | `complete_teacher_public_profile_screen.dart` | — | `complete_teacher_profile_usecase_test.dart` | — | — |
| US-023 | Weekly availability | ✅ | `weekly_availability_screen.dart` | — | `save_weekly_schedule_usecase_test.dart`, slot generator tests | — | — |
| US-024 | Vacation/overrides | ✅ | `availability_override_sheet.dart`, vacation dialogs | — | `vacation_override_validator_test.dart` | — | — |
| US-025 | Teacher dashboard | ✅ | `teacher_dashboard_screen.dart`, `_TeacherDashboardGate` | — | `teacher_dashboard_bloc_test.dart` | — | Roadmap stale on `teacher_1` |
| US-026 | New booking notification | 🟡 | Outbox on create | Teacher device E2E | CF unit tests | US-055 | FCM E2E |
| US-027 | Toggle slot availability | ✅ | `TeacherDashboardBloc` `AvailabilitySlotEdited` | — | Widget tests | — | — |
| US-028 | Teacher cancel + compensation | 🟡 | `cancelSessionBooking` CF | Mobile teacher cancel UX on detail | `cancel_session_usecase_test.dart` | US-014 | Wire teacher cancel UI |
| US-029 | Confirm reschedule | 🟡 | `confirmSessionReschedule` CF | Teacher action UI on detail | CF partial | — | Session detail actions |
| US-030 | Mark student no-show | 🟡 | `markSessionNoShow` CF, `MarkNoShowUseCase` | T-09 UI missing | `mark_no_show_usecase_test.dart` | — | Add no-show CTA |
| US-031 | Teacher join meeting link | 🔴 | Same as US-008 | No link; no join UI | — | US-052 | Same as US-008 |
| US-032 | Teacher reschedule request | ⏸️ | Use cases exist | P2; UI partial | — | — | Postpone |

### E-03 Admin (US-033 – US-044)

| ID | Title | Status | Implemented | Missing | Tests | Blocker | Action |
|----|-------|--------|-------------|---------|-------|---------|--------|
| US-033 | Review applications | ✅ | Admin components + `reviewTeacherApplication` | — | `review-teacher-application.usecase.spec.ts` | — | — |
| US-034 | Seed teacher supply | 🔴 | Domain ready | Ops seed script / data | — | Ops | Run seed on staging |
| US-035 | Suspend/revoke teacher | 🟡 | Use cases + `moderateTeacherProfile` CF | Admin suspend UI thin | Partial | — | Expose in teachers detail |
| US-036 | Block student | 🟡 | `moderateQuranSessionsUser` CF | Admin UX | `usersModeration.rules.test.ts` | — | — |
| US-037 | List sessions | ✅ | `sessions.component.ts` | — | — | — | — |
| US-038 | Session detail timeline | ✅ | `session-detail.component.ts` | — | — | — | — |
| US-039 | Admin session actions | 🟡 | Cancel/no-show/complete in admin detail | Force reschedule partial | — | — | Complete action panel |
| US-040 | Reports queue | 🔴 | CF `reportSessionConcern` | A-10 route/UI | Integration test | US-015 mobile | Build admin reports |
| US-041 | Disputes queue | 🔴 | CF dispute callables | A-11 route/UI | Integration test | US-016 mobile | Build admin disputes |
| US-042 | Manual compensation | 🟡 | `issueSessionCompensation` CF | Admin UI partial | — | — | — |
| US-043 | Bookings read-only | 🟡 | Firestore rules allow participant read | Admin bookings view? | — | — | Optional admin view |
| US-044 | Moderate users list | ✅ | `quran-sessions-users.component.ts` | — | — | — | — |

### E-04 Backend (US-045 – US-060)

| ID | Title | Status | Implemented | Missing | Tests | Blocker | Action |
|----|-------|--------|-------------|---------|-------|---------|--------|
| US-045 | Real auth UID | ✅ | `requireQuranSessionsUserId` | — | — | — | Update stale roadmap |
| US-046 | Profile Firestore | ✅ | `FirestoreUserProfileDataSource` | — | `user_profile_mapper_test.dart` | — | — |
| US-047 | Deny client booking writes | ✅ | `firestore.rules` L191–206 | Dedicated rules tests sparse | Partial | — | Add rules tests |
| US-048 | Configurable policies | ✅ | `FirestoreSessionPolicyDataSource` | — | Policy unit tests | — | — |
| US-049 | Slot generation + integrity | ✅ | `slot_generator.dart`, `booking_integrity_validator` | — | Extensive tests | — | — |
| US-050 | createSessionBooking E2E | 🟡 | CF complete | `meeting_link`; staging smoke | `createSessionBooking.integration.test.ts` | US-052 | Add link + smoke |
| US-051 | Session/booking read repos | ✅ | Firestore repos | — | `firestore_repositories_test.dart` | — | — |
| US-052 | Meeting link on create | 🔴 | — | CF omits field | None | — | **P0 implement** |
| US-053 | cancelSessionBooking | ✅ | `cancelSessionBooking.ts` | — | Partial integration | — | — |
| US-054 | Reschedule callables | ✅ | request + confirm TS | Mobile E2E | Use case tests | — | E2E |
| US-055 | FCM delivery | 🟡 | `deliverSessionNotification.ts` | Device proof | Unit tests | — | Staging device |
| US-056 | Financial ledger manual_pending | ✅ | `financialLedgerService.ts` | PSP off | `paymentAndIdempotency.test.ts` | Paid | Beta OK as manual |
| US-057 | Scheduled jobs | 🟡 | reminders + expire | System no-show job? | `sessionReminders.test.ts` | — | Verify cron deploy |
| US-058 | Feature flags | ✅ | `app_launch_config.dart` | Defaults conservative | `quran_sessions_feature_flags_test.dart` | — | Staging overrides |
| US-059 | Market config Firestore | ✅ | `FirestoreMarketConfigDataSource` | — | `market_config_repository_impl_test.dart` | — | — |
| US-060 | Backfill scripts | 🟡 | `functions/scripts/backfillBookingSessionConsistency.ts` | Dry-run evidence | Manual | Ops | Run on staging |

### E-05 Release & Quality (US-061 – US-072)

| ID | Title | Status | Implemented | Missing | Tests | Blocker | Action |
|----|-------|--------|-------------|---------|-------|---------|--------|
| US-061 | Eligibility test suite | 🔴 | Use case exists | Dedicated test file | 0 | — | **P0** |
| US-062 | Widget tests booking/detail | 🔴 | — | Both widget tests | 0 | — | Sprint 5 |
| US-063 | CF + rules CI gate | 🟡 | Tests exist | CI enforcement unverified | 15 TS test files | — | Verify CI config |
| US-064 | ProfileCompletionBloc tests | ✅ | — | — | `profile_completion_bloc_test.dart` (652 lines) | — | Close roadmap gap |
| US-065 | Staging smoke 10/10 | 🔴 | Checklist in specs | No evidence in repo | Manual | All P0 product | Sprint 7 |
| US-066 | Performance sanity | 🟡 | `availability_operations_perf_test.dart` | Load test | Partial | — | — |
| US-067 | Production backfill | ⏸️ | Scripts | Not run | Manual | Pre-live | Sprint 7 |
| US-068 | Play internal track | 🔴 | Plan doc | Not executed | — | US-065 | Sprint 8 |
| US-069 | Closed testing | 🔴 | Plan doc | Not executed | — | — | Sprint 8 |
| US-070 | Staged rollout | 🔴 | Plan doc | Not executed | — | — | Sprint 8 |
| US-071 | Sentry/alerting | 🟡 | Sentry MCP in workspace | Quran-specific alerts? | — | — | Configure |
| US-072 | Rollback drill | 🔴 | `rollback-plan.md` | Not executed | — | — | Sprint 7 |

### Paid stories (US-P01 – P08)

| ID | Status | Notes |
|----|--------|-------|
| US-P01–P08 | ⏸️ Postponed | Correct per delivery plan; `PAYMENT_PROVIDER_ENABLED` false |

---

## Duplicated / should remove from Free Beta

| Item | Recommendation |
|------|----------------|
| US-017 filter UI | ⏸️ Move to Production (P2 in stories) |
| US-018 English l10n full migration | ⏸️ Production; package EN exists for core screens |
| US-032 teacher-initiated reschedule | ⏸️ P2 — defer |
| In-app Agora/WebRTC | ❌ Remove from Beta scope (already deferred ADR) |
| Guardian linking flow | ❌ Remove from Beta (block-only via eligibility OK) |
| Fake MVP module for production builds | Keep for dev; production uses Firebase module |

---

## Inconsistencies flagged

| Issue | Location |
|-------|----------|
| `status` + `lifecycleStatus` dual write | CF `createSessionBooking.ts`, entities |
| Cancel reason min 3 (UI) vs ≥20 (stories) | `cancel_session_sheet.dart:110` |
| Roadmap says `student_mvp` / no ProfileCompletion tests | Contradicts `quran_sessions_user.dart`, `profile_completion_bloc_test.dart` |
| Roadmap says teacher dashboard hardcoded `teacher_1` | `_TeacherDashboardGate` uses auth UID |
| `mySessions` route constant vs screen-inventory `/sessions/mine` | `QuranSessionsRoutes.mySessions = '/sessions/my'` |
| `enforceAppCheck: false` on all session CFs | Security gap vs production checklist |
