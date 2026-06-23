# Tests Status — Quran Sessions

**Audit:** 2026-06-23  
**Method:** File inventory + source inspection (tests not executed this audit)

**Legend:** ✅ Adequate | 🟡 Partial | 🔴 Missing | ⚠️ Risky

---

## Inventory

| Layer | Count | Path |
|-------|-------|------|
| Package unit/widget | **88** | `packages/quran_sessions/test/` |
| App integration/unit | **7** | `apps/tilawa/test/features/quran_sessions/` |
| App settings (teacher capability) | **2** | `apps/tilawa/test/features/settings/...` |
| Admin Angular | **2** | `apps/tilawa_admin/.../*.spec.ts` |
| CF unit | **9** | `functions/test/quranSessions/` |
| CF integration | **4** | `functions/test-integration/` |
| Firestore rules | **1** (quran-adjacent) | `functions/test-rules/usersModeration.rules.test.ts` |

---

## BLoC / Cubit tests — package

| BLoC | Test file | Status |
|------|-----------|--------|
| `BookingBloc` | `presentation/blocs/booking_bloc_test.dart` | ✅ Eligibility gate, submit |
| `MySessionsBloc` | `presentation/blocs/my_sessions_bloc_test.dart` | 🟡 No join/CallProvider test |
| `ProfileCompletionBloc` | `presentation/blocs/profile_completion_bloc_test.dart` | ✅ 653 lines — **roadmap stale** |
| `TeacherApplicationBloc` | `presentation/blocs/teacher_application_bloc_test.dart` | ✅ Phone validation |
| `TeacherDashboardBloc` | `presentation/blocs/teacher_dashboard_bloc_test.dart` | ✅ |
| `TeacherListBloc` | `presentation/blocs/teacher_list_bloc_test.dart` | ✅ Pagination |
| `TeacherProfileBloc` | `presentation/blocs/teacher_profile_bloc_test.dart` | ✅ |
| `AvailabilityCubit` | `presentation/blocs/availability_cubit_test.dart` | ✅ |
| `SessionDetailBloc` | — | 🔴 No test file |
| `RescheduleBloc` | — | 🔴 No test file |

---

## Domain / use case tests — critical gaps

| Use case | Test file | Status | Classification |
|----------|-----------|--------|----------------|
| `ValidateBookingEligibilityUseCase` | **None** | 🔴 | **Must fix before Free Beta** (US-061) |
| `CompleteStudentProfileUseCase` | Partial via bloc test | 🟡 | Should fix |
| `CreateSessionBookingUseCase` / submit path | Via `BookingBloc` | 🟡 | |
| `CancelSessionUseCase` | `domain/usecases/cancel_session_usecase_test.dart` | ✅ | |
| `SubmitTeacherApplicationUseCase` | `domain/submit_teacher_application_usecase_test.dart` | ✅ | |
| `PhoneNormalizer` | `utils/phone_normalizer_test.dart` | ✅ ~60 cases | |

**Note:** `BookingBloc` imports `ValidateBookingEligibilityUseCase` but does not replace dedicated 12-case matrix from `031/test-matrix.md`.

---

## Policy / lifecycle tests — strong

| Area | Files | Status |
|------|-------|--------|
| Lifecycle guard | `domain/lifecycle/session_lifecycle_guard_test.dart`, `session_transition_table_test.dart` | ✅ |
| Cancellation policy | `domain/policies/cancellation_policy_test.dart`, `configurable_cancellation_policy_test.dart` | ✅ |
| Compensation policy | `configurable_compensation_policy_test.dart` | ✅ |
| Booking policy | `domain/policies/booking_policy_test.dart` | ✅ |
| Slot generator | `domain/services/slot_generator_test.dart` | ✅ |

---

## Widget / golden tests

| Screen / widget | Test | Status |
|-----------------|------|--------|
| Cancel sheet | `presentation/widgets/cancel_session_sheet_test.dart` | ✅ |
| Date grouped slot picker | `date_grouped_slot_picker_test.dart` | ✅ |
| Student empty state | `quran_sessions_student_empty_state_test.dart` | ✅ |
| Teacher cards (goldens) | `teacher_card_golden_test.dart`, etc. | ✅ |
| `BookingScreen` | — | 🔴 US-062 |
| `SessionDetailScreen` | — | 🔴 US-062 |
| `MySessionsScreen` | — | 🔴 |
| `ProfileCompletionScreen` | — | 🟡 Covered by bloc test only |

---

## App-layer tests (`apps/tilawa`)

| File | Covers |
|------|--------|
| `firestore_repositories_test.dart` | Repo wiring |
| `firestore_teacher_repository_test.dart` | Teacher queries |
| `firestore_teacher_profile_repository_test.dart` | Profile read |
| `session_firestore_mapper_test.dart` | DTO mapping |
| `firestore_exception_mapper_test.dart` | Error mapping |
| `quran_sessions_feature_flags_test.dart` | Flag resolution |
| `shared_preferences_friday_review_reminder_store_test.dart` | Friday review store |

---

## Backend tests

| Suite | Command | Status |
|-------|---------|--------|
| CF unit | `cd functions && npm test` | ✅ 9 quranSessions files |
| CF integration | `npm run test:integration` | 🟡 Requires emulator JDK 21+ |
| Rules | `npm run test:rules` | 🟡 Only users moderation for quran profile |
| Staging smoke script | `npm run quran-sessions:staging-smoke` | ⏸️ Manual |

---

## Top 10 missing tests (prioritized)

| # | Test | Story | Class |
|---|------|-------|-------|
| 1 | `validate_booking_eligibility_usecase_test.dart` (12+ cases) | US-061 | **Must fix** |
| 2 | `session_detail_screen_test.dart` — join CTA | US-062 | Should fix |
| 3 | `booking_screen_test.dart` — eligibility block | US-062 | Should fix |
| 4 | `MySessionsBloc` join → `CallProvider.open` | US-008 | **Must fix** |
| 5 | CF integration: create sets `meeting_link` | US-052 | **Must fix** |
| 6 | Firestore rules: booking/session participant read | US-047 | Should fix |
| 7 | E2E Maestro: profile → book → join | US-065 | Should fix |
| 8 | FCM delivery on staging device | US-055 | Should fix |
| 9 | Admin reports component spec | US-040 | Should fix (after UI built) |
| 10 | `RescheduleBloc` integration with gateway | US-054 | Can improve after Beta |

---

## QA Lead verdict

| Metric | Target (`032`) | Current |
|--------|----------------|---------|
| Lifecycle + policy coverage | ≥95% | ~85% package |
| P0 safety use case tested | 12 cases | **0** dedicated |
| Widget tests on critical paths | 2+ screens | **0** booking/detail |
| CI gates CF + rules | Green | 🟡 Not verified this audit |

**Overall test maturity:** 🟡 **62%** — strong on policies/scheduling; weak on eligibility unit + join E2E.
