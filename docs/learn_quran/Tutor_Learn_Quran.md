# Tutor (Teacher) — Learn Quran (Quran Sessions)

**Scope:** Free 1:1 **video-only** beta. Tutor entry (teacher application) and
all rollout gating are admin-controlled.

**Completion (evidence-based, scoped to the beta): ~85%**
**Verdict: READY (with non-blocking follow-ups)**

---

## Implemented features (verified in code + tests)

- **Admin-controlled tutor entry.** Teacher-application discoverability, entry,
  and the home "become a teacher" card are resolved from Firestore platform
  config (`teacherApplicationEnabled`, `teacherApplicationEntryEnabled`,
  `homeTeacherApplicationCardEnabled`, `teacherApplicationDiscoverability`) via
  `quran_sessions_feature_flags.dart`. **As of this change these are editable in
  the Admin Panel global-settings** (previously only readable / manual Firestore).
- Teacher application screen + status screen (draft → submit → pending/approved/
  rejected), country-aware phone validation (`PhoneNormalizer`).
- Teacher dashboard: upcoming/past sessions, availability overview, summary
  stats, offline/empty/loading states.
- Availability management: weekly schedule template, day interval editor, slot
  block/generate, vacation overrides (domain + UI).
- Booking lifecycle actions: approve / reject / cancel booking (tutor approval
  flow), no-show, compensation, reschedule (domain).
- Join session (external meeting) from dashboard; video-only session mode
  honored.

## Checklist

- [x] Tutor entry gated by admin config (no dart-define)
- [x] **Tutor-entry toggles editable in Admin global-settings** (this change)
- [x] Teacher application + status flow
- [x] Teacher dashboard (sessions + availability + stats)
- [x] Availability management (weekly schedule, slot edit, overrides)
- [x] Approve / reject / cancel booking (requiresTutorApproval mode)
- [x] Video-only session mode honored on tutor side
- [ ] Teacher earnings screen (out of scope — no paid beta)
- [ ] Real avatar upload (non-blocking)

## Remaining work (non-blocking)

- Earnings / payout UI — intentionally deferred (no paid booking in beta).
- Avatar upload; teacher review-history screen.

## Launch blockers

- None in tutor app code. Requires ≥1 verified teacher seeded with schedule +
  meeting link on the target backend (ops task).

## Manual QA checklist

- [ ] With `teacherApplicationEnabled=false` (admin) → no apply entry anywhere.
- [ ] Enable via admin → apply entry appears per `discoverability` setting.
- [ ] Submit application → status screen reflects pending; admin approve →
      teacher becomes bookable to students.
- [ ] Tutor sees upcoming session; approves a pending booking; student sees
      confirmation.
- [ ] Reject / cancel booking reflects on student side.
- [ ] Availability edits reflect in student slot picker.

## Automated test coverage

- `teacher_dashboard_bloc_test.dart`, `teacher_dashboard_*_test.dart` (many),
  `teacher_application_bloc_test.dart`, `submit_teacher_application_usecase_test.dart`,
  `phone_normalizer_test.dart`, availability/schedule policy + service tests.
- App-side: `teacher_application_access_cubit_test.dart`,
  `teacher_capability_cubit_test.dart` (**passing**).
- Covered by the `packages/quran_sessions` full suite: **1205 passed / 2 skipped**.
