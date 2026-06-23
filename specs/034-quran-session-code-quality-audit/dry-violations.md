# DRY Violations — Quran Sessions

**Audit date:** 2026-06-23

Note **when NOT to abstract** — duplication that should stay.

---

## Real duplication (should consolidate)

| Issue | Files | Location | Duplication | Suggested fix | Severity | Beta blocker |
|-------|-------|----------|-------------|---------------|----------|--------------|
| Teacher specialization chip list | `teacher_application_screen.dart` L323–330; `complete_teacher_public_profile_screen.dart` L36+ | Same string IDs | Copy-paste list | `teacher_specializations.dart` const list | **P1** | N |
| Lifecycle parse logic | `session_firestore_mapper.dart` L11–19; `legacy_status_lifecycle_mapper.dart`; CF `sessionLifecycleService.ts` | 3 representations | Drift risk | Single Dart mapper + CF owns write enum | **P1** | N |
| Admin filter UI | `sessions.component.html` L7–63; `teacher-applications.component.html` L7–30 | Grid + Apply button | Copy-paste Tailwind | `AdminFilterBarComponent` | **P2** | N |
| Admin loading/error empty states | sessions + teacher-applications HTML | L67–72, L33–38 | Same 3-branch template | `AdminListStateComponent` | **P2** | N |
| Status chip usage | Admin sessions + applications tables | `<app-status-chip>` | OK pattern — not a violation | — | — | — |
| Date/time formatting in cards | `session_card.dart` L34–35; screens | `DateFormat` setup | Extract `formatSessionStart(context, dt)` | **P2** | N |
| `registerUseCases` / `registerBlocs` | `quran_sessions_mvp_module.dart`; `quran_sessions_module.dart` | MVP calls lifecycle; Firebase calls module | Intentional split — document in README | **P2** | N |
| Firestore datetime read | `session_firestore_mapper.dart` L4–8; `firestore_exception_mapper.dart` L33 | Similar parsers | `firestore_converters.dart` in app data | **P2** | N |
| Cancel sheet entry | Student `my_sessions_screen.dart` L175; teacher dashboard (via screen) | Same `showCancelSessionSheet` | **Already DRY** ✓ | — | — | — |
| Friday review banner | `teacher_dashboard_screen.dart`; `friday_review_reminder_banner.dart` | Widget extracted | **Already DRY** ✓ | — | — | — |

---

## Cross-layer duplication (Dart ↔ TypeScript)

| Knowledge | Dart | TypeScript | Risk |
|-----------|------|------------|------|
| Lifecycle transitions | `session_transition_table.dart` | `sessionLifecycleGuard.ts` | Must stay in sync — tests on both sides mitigate |
| Legacy status mapping | `legacy_status_lifecycle_mapper.dart` | `legacyStatusForLifecycle()` | Dual-read period — acceptable for Beta |
| Booking eligibility rules | `validate_booking_eligibility_usecase.dart` | `bookingEligibilityService.ts` | **Intentional** server authority; client is UX gate only |
| Pricing types | Entity enums | CF request union | Codegen or shared OpenAPI post-beta |

---

## When NOT to abstract (keep duplicated)

| Case | Reason |
|------|--------|
| Fake MVP repos vs Firestore repos | Different backends; shared interface already (`TeacherRepository`, etc.) — **do not** merge implementations |
| `BookingBloc` vs CF eligibility | Client pre-check for UX; server is source of truth — **keep both** |
| Package l10n vs app l10n | Feature module owns `quran_sessions` strings — **correct boundary** |
| `TeacherDashboardBloc` slot logic vs `AvailabilityCubit` | Dashboard quick-block vs full weekly editor — different UX contexts until proven same |
| Agora/WebRTC stub providers | Future swap targets — don't unify with `ExternalMeetingCallProvider` |
| Admin table columns per entity | Different columns — only abstract filter chrome, not tables |

---

## Summary

| Severity | Actionable duplicates |
|----------|----------------------|
| P1 | 2 |
| P2 | 5 |
| **Total** | **7** |
