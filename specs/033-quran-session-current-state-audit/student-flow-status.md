# Student Flow Status

**Persona:** Student (MeMuslim app)  
**Routes:** `packages/quran_sessions/lib/src/presentation/router/quran_sessions_routes.dart`  
**Nav wiring:** `apps/tilawa/lib/features/quran_sessions/router/quran_sessions_nav.dart`

---

## Journey map

```
Home (S-01) → Profile gate? → Sessions hub (S-02)
  → Teacher list (S-03) → Profile (S-04) → Book (S-06) → My sessions (S-07)
  → Detail (S-08) → [Join | Cancel | Reschedule | Report]
```

---

## Step-by-step audit

### 1. Entry and profile gate — ✅

| Check | Status | File |
|-------|--------|------|
| Home card visible when `quranSessionsEnabled` | ✅ | `home_sessions_entry_card.dart` (via home dashboard) |
| Incomplete profile → completion screen | ✅ | Nav + `GetUserProfileUseCase` |
| Real auth UID | ✅ | `requireQuranSessionsUserId(getIt)` |
| Return after completion | ✅ | `ProfileCompletionScreen` pops with result |

**Stories:** US-001 ✅, US-004 ✅

---

### 2. Sessions hub — ✅

| Check | Status | File |
|-------|--------|------|
| Abbreviated teacher list | ✅ | `quran_sessions_home_screen.dart` |
| Navigate to full list / my sessions | ✅ | Routes in `quran_sessions_nav.dart` |
| Empty state CTA | ✅ | `quran_sessions_student_empty_state.dart` |
| Teacher apply entry (when flag on) | 🟡 | Gated by `teacherApplicationEnabled` |

**Stories:** US-001 ✅, US-002 🟡 (supply)

---

### 3. Browse teachers — 🟡

| Check | Status | File |
|-------|--------|------|
| Paginated list | ✅ | `TeacherListBloc`, `teacher_list_screen.dart` |
| Firestore data source | ✅ | `FirestoreTeacherDataSource` |
| Verified teachers only | 🟡 | Query depends on `isPubliclyVisible` + seed |
| Filter chips UI | 🔴 | BLoC supports filters; no chip UI |
| Search by name | 🔴 | Not implemented |
| Empty state | ✅ | Student empty state widget |

**Stories:** US-002 🟡, US-017 ⏸️

---

### 4. Teacher profile — ✅

| Check | Status | File |
|-------|--------|------|
| Bio, languages, specializations | ✅ | `teacher_profile_screen.dart` |
| Price via `PriceFormatter` | ✅ | `utils/price_formatter.dart` |
| Availability preview / book CTA | 🟡 | CTA disabled when `bookingEnabled` false |
| Suspended teacher handling | 🟡 | Depends on Firestore visibility flags |

**Stories:** US-003 ✅ (booking CTA gated)

---

### 5. Profile completion — ✅

| Check | Status | File |
|-------|--------|------|
| Gender, DOB, country, city | ✅ | `profile_completion_screen.dart` |
| Market from backend catalog | ✅ | `GetMarketConfigUseCase` |
| Currency/timezone from city | ✅ | `CompleteStudentProfileUseCase` |
| Tests | ✅ | `profile_completion_bloc_test.dart` |

**Stories:** US-004 ✅, US-064 ✅

---

### 6. Booking — 🟡

| Check | Status | File |
|-------|--------|------|
| Route redirect when flag off | ✅ | `quran_sessions_nav.dart` L117-119 |
| Eligibility 8-step chain | ✅ | `ValidateBookingEligibilityUseCase` |
| Inline failure UI | ✅ | `booking_screen.dart` `_EligibilityBlockedView` |
| Slot picker 14-day | ✅ | `DateGroupedSlotPicker` |
| Call type picker | ✅ | `booking_screen.dart` |
| Submit via CF | ✅ | `FirestoreBookingDataSource.createBooking` |
| Idempotency key | 🟡 | CF defaults key; client may not pass explicit key |
| Success → My Sessions | ✅ | Nav after snackbar |

**Stories:** US-005 ✅ (tests gap US-061), US-006 🟡

**Blockers:** `quranSessionsBookingEnabled=false`, teacher supply, eligibility unit tests

---

### 7. My sessions — 🟡

| Check | Status | File |
|-------|--------|------|
| Upcoming / past sections | ✅ | `my_sessions_screen.dart` |
| Pull-to-refresh | ✅ | `RefreshIndicator` L84-85 |
| Session cards | ✅ | `session_card.dart` |
| Cancel flow | 🟡 | `_confirmCancel` → sheet → bloc |
| Review submission | ✅ | `MySessionsBloc` review handler |
| Join button visible | ✅ | `SessionCard` shows join CTA |
| Join actually works | 🔴 | `MySessionsBloc._onJoinRequested` **empty** L96-99 |
| Reschedule navigation | 🟡 | `onRescheduleRequested` callback in nav |
| Session detail navigation | 🟡 | Callback to detail route |

**Stories:** US-007 ✅, US-008 🔴, US-012 ✅

---

### 8. Session detail — 🟡

| Check | Status | File |
|-------|--------|------|
| Load aggregate + timeline | ✅ | `SessionDetailBloc` |
| Lifecycle status label | ✅ | `session_detail_screen.dart` L40-42 |
| Localized time | ✅ | `formatFullDate` |
| Meeting link display | 🔴 | Not in UI |
| Join CTA | 🔴 | Missing |
| Cancel / reschedule CTAs | 🔴 | Missing |
| Report / dispute entry | 🔴 | Missing |

**Stories:** US-014 🟡, US-008 🔴, US-015 🔴

---

### 9. Cancel session — 🟡

| Check | Status | File |
|-------|--------|------|
| Bottom sheet with reason | ✅ | `cancel_session_sheet.dart` |
| Policy copy from config | ✅ | `ConfigurableCancellationPolicy` |
| Min reason length | ⚠️ | 3 chars in UI; stories say ≥20 |
| Server cancel via CF | ✅ | `CancelSessionViaServerUseCase` |
| Block window UI | 🟡 | Policy message shown; pre-check partial |

**Stories:** US-010 🟡

---

### 10. Reschedule — 🟡

| Check | Status | File |
|-------|--------|------|
| Reschedule screen | ✅ | `reschedule_session_screen.dart` |
| Slot picker + reason | ✅ | `RescheduleBloc` |
| CF `requestSessionReschedule` | ✅ | Via mutation gateway |
| Teacher confirm flow | 🟡 | CF exists; student UX for pending state unclear |

**Stories:** US-011 🟡

---

### 11. Notifications — 🟡

| Check | Status | Evidence |
|-------|--------|----------|
| FCM token stored | ✅ | App-level `users/{uid}/fcm_tokens` |
| Booking confirmation push | 🟡 | CF enqueues outbox; device unverified |
| Reminder 24h | 🟡 | `sessionReminders.ts` |
| Deep link to session | 🔴 | No quran-sessions-specific routing in FCM handler verified |

**Stories:** US-009 🟡, US-013 🟡

---

### 12. Safety — reports — 🔴

| Check | Status | Evidence |
|-------|--------|----------|
| Report modal (S-12) | 🔴 | Not in codebase |
| CF `reportSessionConcern` | ✅ | `sessionReportCallables.ts` |
| Guardian block only | ✅ | `GuardianApprovalRequiredFailure` in eligibility |

**Stories:** US-015 🔴

---

### 13. Disputes — 🔴

| Check | Status | Evidence |
|-------|--------|----------|
| Dispute modal (S-13) | 🔴 | Not in codebase |
| CF `openSessionDispute` | ✅ | `sessionDisputeCallables.ts` |

**Stories:** US-016 🟡 (CF only)

---

## Student flow completion estimate

| Segment | % |
|---------|---|
| Discovery + profile | **90%** |
| Booking (with flags on) | **70%** |
| Session management | **55%** |
| Join / attend | **15%** |
| Safety (report/dispute) | **20%** |
| Notifications | **35%** |
| **Overall student Beta path** | **~58%** |

---

## Critical path to shippable student Beta

1. Enable `quranSessionsBookingEnabled` on staging.
2. US-052 — populate `meeting_link` in CF.
3. Wire `MySessionsBloc._onJoinRequested` → `CallProvider` + `url_launcher`.
4. Complete `session_detail_screen.dart` actions (join, cancel, report).
5. Seed teachers (US-034).
6. FCM E2E on device (US-009).
