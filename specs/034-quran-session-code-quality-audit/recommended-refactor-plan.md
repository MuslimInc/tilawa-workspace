# Recommended Refactor Plan — Quran Sessions

**Audit date:** 2026-06-23  
**Aligned with:** `specs/032-quran-session-delivery-plan/`, `specs/033-quran-session-current-state-audit/`

Phases ordered by **Free Beta shipping** first. Estimates assume 1–2 engineers.

---

## Phase 1 — Beta blockers (Sprint 5)

**Goal:** Student/teacher can complete book → see session → tap join → external meeting opens.

### Issues

| ID | Issue |
|----|-------|
| R-01 | Empty `_onJoinRequested` |
| R-02 | CF missing `meeting_link` |
| R-03 | `CallProvider` not registered |
| R-04 | Session detail missing join |
| R-05 | Fake/CF session shape parity |
| R-06 | Eligibility use case tests |

### Files (primary touch)

| Area | Files |
|------|-------|
| CF | `functions/src/quranSessions/createSessionBooking.ts` |
| App DI | `apps/tilawa/lib/features/quran_sessions/di/quran_sessions_firebase_module.dart` |
| Package bloc | `packages/quran_sessions/lib/src/presentation/blocs/my_sessions/my_sessions_bloc.dart` |
| Package screens | `session_detail_screen.dart`, `session_card.dart` (optional link preview) |
| Package boundary | `external_meeting_call_provider.dart` (already done — wire only) |
| Tests | `my_sessions_bloc_test.dart`, new `validate_booking_eligibility_usecase_test.dart`, CF create booking test |

### Tests to add/pass

1. `ValidateBookingEligibilityUseCase` — profile incomplete, market disabled, teacher unverified, active booking limit.
2. `MySessionsBloc` — `SessionJoinRequested` invokes `CallProvider.joinSession`.
3. CF — assert `meeting_link` / `meetingLink` non-null on session doc after free create.
4. Widget — `SessionDetailScreen` shows join when link present.

### Risk

| Risk | Mitigation |
|------|------------|
| Teacher has no meeting URL source | Define rule: teacher profile `externalMeetingUrl` or generated Meet link stub for Beta |
| `url_launcher` platform quirks | Test on Android + iOS staging |
| Breaking idempotent re-booking | Existing idempotency tests |

### Exit criteria

- [ ] Staging: create booking → Firestore session doc has meeting URL field populated.
- [ ] App: My Sessions join opens browser/app with URL.
- [ ] App: Session detail join matches My Sessions behavior.
- [ ] `flutter test` — new eligibility + join tests green.
- [ ] `functions` unit test for meeting field green.

---

## Phase 2 — UX, safety, testability (Sprint 6)

**Goal:** Trustworthy errors, localized detail, safety entry points, smaller blast radius on dashboard.

### Issues

| ID | Issue |
|----|-------|
| R-07 | Join widget tests |
| R-08 | Review failure state |
| R-09 | Split dashboard BLoC concerns |
| R-11 | Timeline l10n |
| R-13 | Hide debug panel |
| R-14 | Strict lifecycle parse |
| R-23 | Report/dispute mobile UI (product) |

### Files

| Area | Files |
|------|-------|
| Blocs | `my_sessions_bloc.dart`, extract from `teacher_dashboard_bloc.dart` |
| Screens | `session_detail_screen.dart`, `teacher_application_status_screen.dart` |
| Mappers | `session_firestore_mapper.dart` |
| New | `report_session_screen.dart` (minimal), wire to existing CF |
| l10n | `intl_en.arb`, `intl_ar.arb` — timeline action keys |

### Tests

- Widget: timeline localized strings.
- Bloc: review failure emits toast state.
- Mapper: unknown lifecycle → failure not `scheduled`.

### Risk

| Risk | Mitigation |
|------|------------|
| Dashboard split breaks undo timer | Characterization tests before split |
| Report UI scope creep | Single form, 3 categories max |

### Exit criteria

- [ ] No raw `event.action.name` in session detail.
- [ ] Review failure shows error toast.
- [ ] `TeacherDashboardBloc` < 500 LOC or split documented.
- [ ] Report flow callable from session detail (staging).

---

## Phase 3 — Design system consistency (Sprint 7)

**Goal:** Sessions UI matches booking/availability Tilawa patterns.

### Issues

| ID | Issue |
|----|-------|
| R-19–R-21 | Raw buttons, Card, spacing |
| R-17 | Specialization constant |
| R-18 | Admin filter component |

### Files

| Area | Files |
|------|-------|
| Widgets | `session_card.dart`, `my_sessions_screen.dart`, `cancel_session_sheet.dart` |
| Constants | new `teacher_specializations.dart` |
| Admin | new `AdminFilterBarComponent` |

### Tests

- Golden: `session_card` light/dark (optional).
- Visual QA checklist on staging.

### Risk

Low — cosmetic.

### Exit criteria

- [ ] Sessions list uses `TilawaCard` + `TilawaButton`.
- [ ] Padding via `theme.tokens.spacing.*`.
- [ ] Admin sessions + applications share filter bar.

---

## Phase 4 — Paid / production prep (Post–Beta)

**Goal:** Safe paid path without YAGNI leakage into Free Beta UX.

### Issues

| ID | Issue |
|----|-------|
| R-12 | Cancel pricing from entity |
| R-22 | Ledger UI |
| R-24 | App Check |
| R-25–R-26 | Legacy field removal plan; lifecycle codegen |
| R-16 | Consolidate fake backend to test-only |

### Files

| Area | Files |
|------|-------|
| Payment | `disabled_payment_provider.dart` → real provider module |
| CF | `financialLedgerService.ts`, admin ledger views |
| Flags | `quran_sessions_feature_flags.dart` |
| Tooling | lifecycle schema/codegen spike |

### Tests

- Paid booking E2E on staging (PSP sandbox).
- Refund CF integration.
- Contract tests Dart eligibility ⊂ server eligibility.

### Risk

| Risk | Mitigation |
|------|------------|
| PCI scope | Keep card data off app |
| Ledger inconsistency | Single write path in CF |

### Exit criteria

- [ ] Paid booking blocked in Free Beta flavor; enabled in paid flavor.
- [ ] Admin financial queue operational.
- [ ] App Check enforced on production callables.
- [ ] Lifecycle single source of truth documented or generated.

---

## Phase overview

| Phase | Sprint | Focus | Beta blocker? |
|-------|--------|-------|---------------|
| 1 | 5 | Join + meeting_link + tests | **Yes** |
| 2 | 6 | Errors, l10n, safety UI, bloc split | Partial |
| 3 | 7 | UI Kit alignment | No |
| 4 | Post-Beta | Paid + production hardening | No |
