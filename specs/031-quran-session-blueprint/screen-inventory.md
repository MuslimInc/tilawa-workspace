# Screen Inventory — Quran Sessions

**Product:** MeMuslim / أنا مسلم  
**Legend:** ✅ exists · `[Partial]` incomplete wiring · `[Planned]` not built · `[Paid]` paid phase · `[Admin]` tilawa_admin

---

## Student screens (mobile)

| ID | Screen | Route | File | Status | Beta |
|----|--------|-------|------|--------|------|
| S-01 | Home entry card | `/` (home) | `home_sessions_entry_card.dart` | ✅ | ✅ |
| S-02 | Sessions hub | `/sessions` | `quran_sessions_home_screen.dart` | ✅ | ✅ |
| S-03 | Teacher list | `/sessions/teachers` | `teacher_list_screen.dart` | ✅ | ✅ |
| S-04 | Teacher profile | `/sessions/teachers/:teacherId` | `teacher_profile_screen.dart` | ✅ | ✅ |
| S-05 | Profile completion | `/sessions/profile/complete` | `profile_completion_screen.dart` | ✅ | ✅ |
| S-06 | Booking | `/sessions/book/:teacherId` | `booking_screen.dart` | ✅ gated | ✅ |
| S-07 | My sessions | `/sessions/mine` | `my_sessions_screen.dart` | ✅ | ✅ |
| S-08 | Session detail | `/sessions/session/:sessionId` | `session_detail_screen.dart` | `[Partial]` | ✅ |
| S-09 | Reschedule | `/sessions/session/:id/reschedule` | `reschedule_session_screen.dart` | `[Partial]` | ✅ |
| S-10 | Cancel sheet | modal | `cancel_session_sheet.dart` | `[Partial]` | ✅ |
| S-11 | Review submission | modal | inline MySessions / detail | ✅ | ✅ |
| S-12 | Report concern | modal | — | `[Planned]` | ✅ |
| S-13 | Open dispute | modal | — | `[Planned]` | ✅ |
| S-14 | Payment checkout | `/sessions/book/.../pay` | — | `[Paid]` | ❌ |
| S-15 | Guardian linking | `/sessions/guardian` | — | `[Planned]` | ❌ |
| S-16 | Compensation history | `/sessions/wallet` | — | `[Planned]` | ❌ |
| S-17 | Filter bar (teachers) | overlay on S-03 | — | `[Planned]` | Should |
| S-18 | Teacher search | on S-03 | — | `[Planned]` | ❌ |

### S-08 gaps (session detail)

- [ ] Display `meetingLink` + join CTA
- [ ] Show lifecycle status with policy copy
- [ ] Report + dispute entry points
- [ ] Reschedule CTA when policy allows

---

## Teacher screens (mobile)

| ID | Screen | Route | File | Status | Beta |
|----|--------|-------|------|--------|------|
| T-01 | Application form | `/sessions/teacher/apply` | `teacher_application_screen.dart` | ✅ | ✅ |
| T-02 | Application status | `/sessions/teacher/status` | `teacher_application_status_screen.dart` | ✅ | ✅ |
| T-03 | Complete public profile | `/sessions/teacher/profile/complete` | `complete_teacher_public_profile_screen.dart` | ✅ | ✅ |
| T-04 | Weekly availability | `/sessions/teacher/availability` | `weekly_availability_screen.dart` | ✅ | ✅ |
| T-05 | Availability overrides | sheets | `availability_override_sheet.dart`, vacation dialogs | ✅ | ✅ |
| T-06 | Teacher dashboard | `/sessions/teacher/dashboard` | `teacher_dashboard_screen.dart` | ✅ | ✅ |
| T-07 | Session detail (teacher) | shared S-08 | `session_detail_screen.dart` | `[Partial]` | ✅ |
| T-08 | Cancel / reschedule | shared sheets | `[Partial]` | ✅ |
| T-09 | Mark student no-show | on T-07 | — | `[Planned]` | ✅ |
| T-10 | Earnings | `/sessions/teacher/earnings` | — | `[Paid]` | ❌ |
| T-11 | Review history | `/sessions/teacher/reviews` | — | `[Planned]` | ❌ |
| T-12 | Pricing editor | `/sessions/teacher/pricing` | — | `[Paid]` | ❌ |
| T-13 | Payout settings | — | — | `[Paid]` | ❌ |

### Settings integration

| ID | Screen | Location | Status |
|----|--------|----------|--------|
| T-14 | Teacher capability section | Settings | ✅ `settings_widgets.dart` |

---

## Admin screens (tilawa_admin)

| ID | Screen | Route | File | Status |
|----|--------|-------|------|--------|
| A-01 | Sidebar entry | — | `sidebar.component.html` | ✅ |
| A-02 | Teacher applications list | `/quran-sessions/applications` | `teacher-applications.component` | ✅ |
| A-03 | Application detail | `.../applications/:id` | `teacher-application-detail.component` | ✅ |
| A-04 | Teachers list | `/quran-sessions/teachers` | `teachers.component` | ✅ |
| A-05 | Teacher detail | `[Partial]` inline | — | `[Partial]` |
| A-06 | Users list | `/quran-sessions/users` | `quran-sessions-users.component` | ✅ |
| A-07 | Sessions list | `/quran-sessions/sessions` | `sessions.component` | ✅ |
| A-08 | Session detail | `.../sessions/:id` | `session-detail.component` | ✅ |
| A-09 | Session actions panel | on A-08 | `session-detail.component.html` | `[Partial]` |
| A-10 | Reports queue | `/quran-sessions/reports` | — | `[Planned]` |
| A-11 | Disputes queue | `/quran-sessions/disputes` | — | `[Planned]` |
| A-12 | Financial ledger | `/quran-sessions/ledger` | — | `[Paid]` |
| A-13 | Platform policy editor | `/quran-sessions/policy` | — | `[Planned]` |
| A-14 | Metrics dashboard | `/quran-sessions/metrics` | — | `[Planned]` |
| A-15 | Audit export | on A-08 | — | `[Planned]` |

---

## Shared / system UI

| Component | File | Used by |
|-----------|------|---------|
| Teacher card | `teacher_card.dart` | S-02, S-03 |
| Session card | `session_card.dart` | S-07, T-06 |
| Date grouped slot picker | `date_grouped_slot_picker.dart` | S-06 |
| Verified teacher badge | ui_kit | S-04 |
| Student empty state | `quran_sessions_student_empty_state.dart` | S-02 |
| Friday review reminder | `friday_review_reminder_banner.dart` | S-07 |
| Failure UI | `quran_sessions_failure_ui.dart` | all |

---

## Navigation map

```mermaid
flowchart TD
  HOME[Home S-01] --> HUB[S-02 Sessions Hub]
  HUB --> LIST[S-03 Teachers]
  HUB --> MINE[S-07 My Sessions]
  HUB --> APPLY[T-01 Apply]
  LIST --> PROF[S-04 Profile]
  PROF --> BOOK[S-06 Booking]
  BOOK --> MINE
  MINE --> DET[S-08 Detail]
  DET --> RESCH[S-09 Reschedule]
  SETTINGS[Settings T-14] --> APPLY
  SETTINGS --> DASH[T-06 Dashboard]
  DASH --> AVAIL[T-04 Availability]
  APPROVED --> T-03 Complete Profile
  T-03 --> DASH
```

---

## Screen → use case mapping

| Screen | Primary use cases |
|--------|-------------------|
| S-06 Booking | ValidateBookingEligibility, GetTeacherAvailability, CreateSessionBooking |
| S-07 My Sessions | GetStudentSessions, CancelSession, SubmitReview |
| S-08 Detail | GetSessionTimeline, join call, cancel, report |
| T-01 Apply | SubmitTeacherApplication, SaveDraft |
| T-04 Availability | GetWeeklySchedule, save schedule, overrides |
| T-06 Dashboard | GetTeacherSessions, GetTeacherAvailability |
| A-08 Session detail | read repos + CF actions via facade |

---

## Localization status

| Area | Status |
|------|--------|
| Package l10n | `packages/quran_sessions/l10n/` — AR + EN partial |
| App ARB integration | `[Partial]` — many hardcoded strings per roadmap |
| Admin | English primary |

**Beta requirement:** Move user-visible strings to ARB before public Beta.

---

## Accessibility checklist (all screens)

- [ ] Semantic labels on join/cancel/book CTAs
- [ ] Dynamic type support via theme tokens
- [ ] Contrast on status badges (scheduled vs cancelled)
- [ ] Screen reader order on booking slot picker
- [ ] RTL audit for sessions routes

---

## Beta minimum screen set

Must ship for Free Beta:

S-01 through S-11 (except S-12–S-13 can be fast-follow if admin can receive reports via support email temporarily — **not recommended**).

T-01 through T-08.

A-02 through A-09.

**Blockers:** S-08 meeting link, S-10 cancel reason, A-09 action panel wired to CFs.
