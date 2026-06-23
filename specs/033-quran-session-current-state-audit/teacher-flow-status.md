# Teacher Flow Status

**Persona:** Quran teacher (verified profile, not user role — ADR-003)  
**Capability resolver:** `GetCurrentUserTeacherCapabilityUseCase`  
**Gate:** `_TeacherDashboardGate` in `quran_sessions_nav.dart`

---

## Journey map

```
Settings / Hub entry → Apply (T-01) → Status (T-02)
  → Admin approve → Complete profile (T-03)
  → Weekly availability (T-04) + Overrides (T-05)
  → Dashboard (T-06) → Session detail (T-07) → [Join | Cancel | No-show | Reschedule]
```

---

## Step-by-step audit

### 1. Discovery / entry — 🟡

| Check | Status | File |
|-------|--------|------|
| "أريد أن أصبح محفظًا" on sessions hub | 🟡 | Shown when `teacherApplicationEnabled` |
| Settings teaching tile | ✅ | `settings_teaching_on_memuslim_tile.dart` |
| Apply route redirect when flag off | ✅ | `quran_sessions_nav.dart` L259-262 |
| Option D hybrid IA (ADR-004) | ✅ | Profile + empty state discoverability |

**Stories:** US-019 🟡 (flag), US-058

---

### 2. Teacher application — ✅

| Check | Status | File |
|-------|--------|------|
| Application form | ✅ | `teacher_application_screen.dart` |
| Phone validation (E.164) | ✅ | `PhoneNormalizer`, bloc tests |
| Draft save | ✅ | `SaveTeacherApplicationDraftUseCase` |
| Submit → pending | ✅ | `SubmitTeacherApplicationUseCase` |
| Firestore applicant rules | ✅ | `firestore.rules` L122-143 |
| Debug simulate approval | ✅ | kDebugMode only in bloc |

**Stories:** US-019 ✅ (when flag on), US-020 ✅

---

### 3. Application status — ✅

| Check | Status | File |
|-------|--------|------|
| Status screen | ✅ | `teacher_application_status_screen.dart` |
| Pending / approved / rejected copy | ✅ | State-driven UI |
| Approved → complete profile CTA | ✅ | `onApproved` in nav |
| Revoked permanent block | ✅ | Domain failures + capability |

**Stories:** US-021 ✅

---

### 4. Admin approval (cross-persona) — ✅

| Check | Status | File |
|-------|--------|------|
| Admin review UI | ✅ | `teacher-application-detail.component.ts` |
| `reviewTeacherApplication` CF | ✅ | `functions/src/reviewTeacherApplication.ts` |
| Creates `TeacherProfile` on approve | ✅ | CF + domain use case |

**Stories:** US-033 ✅

---

### 5. Complete public profile — ✅

| Check | Status | File |
|-------|--------|------|
| Screen after approval | ✅ | `complete_teacher_public_profile_screen.dart` |
| Display name, bio, gender, specs, langs | ✅ | `SaveTeacherPublicProfileUseCase` |
| Firestore owner update rules | ✅ | `firestore.rules` L154-156 |
| Navigate to dashboard on complete | ✅ | Nav L248-252 |

**Stories:** US-022 ✅

---

### 6. Weekly availability — ✅

| Check | Status | File |
|-------|--------|------|
| Weekly editor screen | ✅ | `weekly_availability_screen.dart` |
| Day hours row widgets | ✅ | `availability_day_hours_row.dart` |
| Save to Firestore `availability_config` | ✅ | `FirestoreScheduleDataSource` |
| Slot generation 14-day | ✅ | `slot_generator.dart` |
| Overlap validation | ✅ | `weekly_schedule_validator_test.dart` |
| Golden tests | ✅ | `availability_day_hours_row_golden_test.dart` |

**Stories:** US-023 ✅

---

### 7. Vacation / overrides — ✅

| Check | Status | File |
|-------|--------|------|
| Override sheet | ✅ | `availability_override_sheet.dart` |
| Vacation dialogs | ✅ | `availability_vacation_dialogs.dart` |
| Firestore `availability_overrides` | ✅ | Rules L176-179 |
| Validator tests | ✅ | `vacation_override_validator_test.dart` |

**Stories:** US-024 ✅

---

### 8. Teacher dashboard — ✅

| Check | Status | File |
|-------|--------|------|
| Auth-aware access gate | ✅ | `_TeacherDashboardGate` — uses real UID |
| Upcoming sessions | ✅ | `TeacherDashboardScreen` |
| Slot list + toggle | ✅ | `TeacherDashboardBloc` |
| Edit/remove generated slots | ✅ | `AvailabilitySlotRemoved` event |
| Manage schedule nav | ✅ | `onManageSchedule` → availability route |
| **Roadmap claim "hardcoded teacher_1"** | ❌ Stale | Gate resolves `userId` L461 |

**Stories:** US-025 ✅, US-027 ✅

---

### 9. Receive bookings — 🟡

| Check | Status | Evidence |
|-------|--------|----------|
| Booking creates session for teacher | ✅ | CF writes `teacherId` on session |
| Dashboard refresh shows booking | 🟡 | Requires Firestore read + manual refresh |
| Push notification on book | 🟡 | Outbox enqueue; device E2E unverified |

**Stories:** US-026 🟡

---

### 10. Session delivery — 🔴

| Check | Status | Evidence |
|-------|--------|----------|
| Join via meeting link (T-07) | 🔴 | Same gaps as student US-008 |
| `meeting_link` on session doc | 🔴 | Not set in `createSessionBooking.ts` |
| Mark in progress / complete | 🟡 | CF `completeSession`; no teacher mobile UI |
| Mark student no-show (T-09) | 🔴 | CF exists; no mobile UI |

**Stories:** US-031 🔴, US-030 🟡

---

### 11. Teacher cancel — 🟡

| Check | Status | Evidence |
|-------|--------|----------|
| CF cancel with teacher actor | ✅ | `cancelSessionBooking.ts` `resolveActorRole` |
| Compensation enqueue | ✅ | Via notification/ledger services |
| Mobile cancel UX on session detail | 🔴 | Not on `session_detail_screen.dart` |
| Cancel sheet supports teacher actor | 🟡 | Sheet uses `ActorRole.student` default L14 |

**Stories:** US-028 🟡

---

### 12. Reschedule (teacher) — ⏸️

| Check | Status | Notes |
|-------|--------|-------|
| Teacher-initiated reschedule | ⏸️ | US-032 P2 |
| Confirm student request | 🟡 | CF `confirmSessionReschedule`; UI on detail missing |

**Stories:** US-029 🟡, US-032 ⏸️

---

### 13. Earnings / reviews — ⏸️

| Screen | Status |
|--------|--------|
| T-10 Earnings | 🔴 Not built (Paid) |
| T-11 Review history | 🔴 Not built |

---

## Teacher flow completion estimate

| Segment | % |
|---------|---|
| Application + approval | **85%** (flags) |
| Profile + availability | **88%** |
| Dashboard + slot mgmt | **82%** |
| Session delivery (join) | **15%** |
| Lifecycle actions (cancel/no-show) | **40%** |
| Notifications | **35%** |
| **Overall teacher Beta path** | **~52%** |

---

## Critical path to shippable teacher Beta

1. Enable `teacherApplicationEnabled` on staging.
2. Admin approve + complete profile for pilot teachers.
3. US-052 meeting link (teacher URL on profile → session doc).
4. US-031 join on shared session detail.
5. US-028 teacher cancel on session detail with `ActorRole.teacher`.
6. US-030 no-show CTA on teacher session detail.
7. US-026 booking notification E2E.
