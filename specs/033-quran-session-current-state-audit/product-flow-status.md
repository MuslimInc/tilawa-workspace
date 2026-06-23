# Product Flow Status — vs Blueprint

**Reference:** `specs/031-quran-session-blueprint/` (student-flow, teacher-flow, admin-flow, session-state-machine)  
**Legend:** ✅ Done | 🟡 Partial | 🔴 Missing | ⚠️ Risky | ⏸️ Postponed

---

## Flow matrix

| Flow | Blueprint | Current | Status | Gap |
|------|-----------|---------|--------|-----|
| Student discovery (home → hub) | S-01 → S-02 | `HomeSessionsEntryCard`, `QuranSessionsHomeScreen` | ✅ | Experimental badge present |
| Profile completion gate | Gate before browse/book | `ProfileCompletionScreen` + nav gates | ✅ | — |
| Teacher browsing | Paginated verified list | `TeacherListScreen` + Firestore | 🟡 | Empty without US-034 seed |
| Teacher profile | Bio, price, slots preview | `TeacherProfileScreen` | ✅ | Reviews list missing |
| Availability viewing | 14-day slots | `GetTeacherAvailabilityUseCase`, slot generator | ✅ | Client-side generation |
| Free booking | Slot + call type + confirm | `BookingScreen` + CF | 🟡 | **Flag off**; CF works |
| Paid booking gating | Block when PSP off | `assertPaidBookingAllowed` in CF | ✅ | UI checkout missing (correct) |
| My sessions | Upcoming/past, cancel, review | `MySessionsScreen` | 🟡 | Join broken |
| Session detail | Status, actions, timeline | `SessionDetailScreen` | 🟡 | No join/cancel/reschedule/report |
| Join audio/video | External link MVP | `ExternalMeetingCallProvider` | 🔴 | No link; join stub |
| Cancellation | Reason + policy windows | `cancel_session_sheet.dart` + CF | 🟡 | Reason length; detail entry |
| Reschedule | Request + confirm | Screen + CFs | 🟡 | E2E unverified |
| No-show | Teacher mark + system job | CF `markSessionNoShow` | 🟡 | No mobile T-09 UI |
| Reports | Student → admin queue | CF only | 🔴 | No S-12, no A-10 |
| Disputes | Post-completion dispute | CF only | 🔴 | No S-13, no A-11 |
| Ratings | Post-session review | `MySessionsBloc` submit review | ✅ | Public list deferred |
| Teacher application | Apply → pending | `TeacherApplicationScreen` | 🟡 | Flag off default |
| Admin approval | Review → profile | Admin UI + CF | ✅ | — |
| Teacher dashboard | Sessions + slots | `TeacherDashboardScreen` | ✅ | Auth-aware gate |
| Weekly availability | Recurring schedule | `WeeklyAvailabilityScreen` | ✅ | — |
| Vacation/overrides | Block days | Override sheets + dialogs | ✅ | — |
| Admin operations | Sessions, moderation | Partial admin panel | 🟡 | Reports/disputes missing |

---

## State machine alignment

**Canonical:** `SessionLifecycleStatus` in `packages/quran_sessions/lib/src/domain/entities/session_lifecycle_status.dart`  
**CF guard:** `functions/src/quranSessions/sessionLifecycleGuard.ts`  
**Domain guard tests:** `session_lifecycle_guard_test.dart`, `session_transition_table_test.dart`

| Check | Status |
|-------|--------|
| Enum parity package ↔ CF | ✅ |
| Legacy `status` field still written | ⚠️ `legacyStatusForLifecycle` in CF |
| Client writes lifecycle | ✅ Denied — CF only |
| Dispute only from completed | ✅ Tested in lifecycle guard |
| Teacher cancel compensates | 🟡 CF path exists; mobile UX partial |

---

## Blueprint screen inventory cross-check

Source: `specs/031-quran-session-blueprint/screen-inventory.md`

| Screen ID | Inventory status | Audit verdict | Notes |
|-----------|------------------|---------------|-------|
| S-01–S-07 | ✅ | ✅ Confirmed | Pull-to-refresh on S-07 exists (`RefreshIndicator` in `my_sessions_screen.dart`) |
| S-08 | Partial | 🟡 Confirmed partial | Timeline only |
| S-09 | Partial | 🟡 | `reschedule_session_screen.dart` wired in nav |
| S-10 | Partial | 🟡 | Sheet exists; validation mismatch |
| S-11 | ✅ | ✅ | Review in MySessions |
| S-12 | Planned | 🔴 | Not built |
| S-13 | Planned | 🔴 | Not built |
| T-01–T-06 | ✅ | ✅ | Application flag gates T-01 |
| T-07–T-08 | Partial | 🟡 | Shared S-08 gaps |
| T-09 | Planned | 🔴 | No-show UI |
| A-01–A-09 | ✅/Partial | 🟡 | Session actions partial |
| A-10–A-11 | Planned | 🔴 | Not built |

---

## Sequence diagram flows (high level)

| Sequence | Status |
|----------|--------|
| Book free session (student) | 🟡 CF OK; flag + link block E2E |
| Cancel by student | 🟡 CF OK; UX partial |
| Cancel by teacher + compensation | 🟡 CF OK; teacher UI on detail missing |
| Reschedule request → confirm | 🟡 CF OK; mobile E2E unverified |
| Notification outbox → FCM | 🟡 Coded; device unverified |
| Report concern | 🔴 CF only |
| Dispute open → admin resolve | 🔴 CF + partial admin gateway; no queues |
| Teacher apply → admin approve → marketplace | 🟡 Works when flags on + admin acts |

---

## Feature flag impact on flows

From `apps/tilawa/lib/core/bootstrap/app_launch_config.dart`:

| Flag | Default | Flows blocked |
|------|---------|---------------|
| `quranSessionsEnabled` | `true` | Entire feature if false |
| `quranSessionsBookingEnabled` | `false` | S-06 booking route, book CTA on profile |
| `teacherApplicationEnabled` | `false` | T-01 apply route |
| `teacherApplicationDiscoverability` | `profileAndEmptyState` | Entry points when apply off |

---

## Backend-agnostic architecture compliance

Per `specs/031-quran-session-blueprint/backend-agnostic-architecture.md`:

| Rule | Status |
|------|--------|
| No Firebase in package domain | ✅ |
| Gateways for mutations | ✅ `SessionMutationGateway`, `SessionCommandGateway` |
| `Either<Failure,T>` boundaries | ✅ |
| Host app owns Firestore DTOs | ✅ Under `apps/tilawa/.../firebase/` |
| Payment/call behind interfaces | ✅ Stubs + external meeting |
