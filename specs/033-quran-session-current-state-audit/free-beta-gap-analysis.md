# Free Beta Gap Analysis

**Baseline:** `specs/032` Free Beta IN scope (44 P0 stories)  
**Audit:** 2026-06-23

**Legend:** ✅ Done | 🟡 Partial | 🔴 Missing | ⚠️ Risky | ⏸️ Postponed | ❌ Remove from Beta

---

## P0 story status (all 44)

### E-01 Student (12 P0)

| Story | Title | Status | Gap / file |
|-------|-------|--------|------------|
| US-001 | Sessions home + profile gate | ✅ | `home_sessions_entry_card.dart`, `quran_sessions_nav.dart` |
| US-002 | Browse verified teachers | 🟡 | List works; **supply** depends US-034 |
| US-003 | Teacher profile + availability | ✅ | `teacher_profile_screen.dart` |
| US-004 | Profile completion + market | ✅ | `profile_completion_screen.dart`; tests in `profile_completion_bloc_test.dart` |
| US-005 | Booking eligibility inline errors | 🟡 | UI ✅; **US-061 tests missing** |
| US-006 | Book free session | 🟡 | CF ✅; **flag off** `quranSessionsBookingEnabled` |
| US-007 | My upcoming/past sessions | ✅ | `my_sessions_screen.dart` |
| US-008 | Join via meeting link | 🔴 | No link in CF; join stub `my_sessions_bloc.dart` L96-99 |
| US-009 | Booking confirmation push | 🟡 | Outbox ✅; device E2E unverified |
| US-010 | Cancel with reason | 🟡 | `cancel_session_sheet.dart`; min 3 not 20 chars |
| US-013 | T-24h reminder | 🟡 | `sessionReminders.ts`; E2E unverified |
| US-015 | Report safety concern | 🔴 | CF only — no mobile UI |

### E-02 Teacher (8 P0)

| Story | Title | Status | Gap |
|-------|-------|--------|-----|
| US-019 | Start teacher application | 🟡 | Screen ✅; **flag off** `teacherApplicationEnabled` |
| US-020 | Submit application | ✅ | `SubmitTeacherApplicationUseCase` + rules |
| US-022 | Complete public profile | ✅ | `complete_teacher_public_profile_screen.dart` |
| US-023 | Weekly availability | ✅ | `weekly_availability_screen.dart` |
| US-025 | Teacher dashboard | ✅ | Auth-aware `_TeacherDashboardGate` |
| US-026 | New booking notification (teacher) | 🟡 | Same pipeline as US-009 |
| US-028 | Teacher cancel + compensation | 🟡 | CF ✅; mobile entry via detail 🟡 |
| US-031 | Teacher join meeting link | 🔴 | Same as US-008 |

### E-03 Admin (7 P0)

| Story | Title | Status | Gap |
|-------|-------|--------|-----|
| US-033 | Review applications | ✅ | `teacher-applications.component.ts` |
| US-034 | Seed ≥5 teachers | 🔴 | Ops — no verified supply in staging |
| US-037 | List/filter sessions | ✅ | `sessions.component.ts` |
| US-039 | Admin session actions | 🟡 | `session-detail.component.ts` partial actions |
| US-040 | Reports queue | 🔴 | No A-10 route/component |
| US-041 | Disputes queue | 🔴 | No A-11 route/component |
| US-042 | Manual_pending compensation | 🟡 | CF `issueSessionCompensation`; thin admin UX |

### E-04 Backend (14 P0)

| Story | Title | Status | Gap |
|-------|-------|--------|-----|
| US-045 | Real auth UID | ✅ | `requireQuranSessionsUserId`, `FirebaseAuthSessionProvider` |
| US-046 | Profile Firestore | ✅ | `firestore_user_profile_repository.dart` |
| US-047 | Deny client booking/session writes | ✅ | `firestore.rules` |
| US-048 | Configurable policies | 🟡 | `firestore_session_policy_repository.dart` |
| US-049 | Slot integrity server-side | ✅ | CF + `BookingIntegrityValidator` |
| US-050 | createSessionBooking E2E | 🟡 | Works except **meeting_link** |
| US-051 | Read repos | ✅ | Firestore session/booking repos |
| US-052 | meeting_link on create | 🔴 | `createSessionBooking.ts` L177-190 |
| US-053 | cancelSessionBooking | ✅ | |
| US-055 | FCM delivery | 🟡 | `deliverSessionNotification.ts` |
| US-056 | manual_pending ledger | 🟡 | `financialLedgerService.ts` |
| US-057 | Scheduled jobs | 🟡 | Reminders + expiry coded |
| US-058 | Feature flags | 🟡 | Implemented; **booking off** default |
| US-059 | Market config Firestore | ✅ | `firestore_market_config_repository.dart` |
| US-060 | Lifecycle backfill | ⏸️ | Scripts exist; ops not run |

### E-05 Release (8 P0)

| Story | Title | Status | Gap |
|-------|-------|--------|-----|
| US-061 | Eligibility test suite | 🔴 | No `validate_booking_eligibility_usecase_test.dart` |
| US-063 | CF integration + rules CI | 🟡 | Tests exist; CI green not verified |
| US-064 | ProfileCompletionBloc tests | ✅ | `profile_completion_bloc_test.dart` |
| US-065 | Staging smoke 10/10 | 🔴 | `stagingFreeBetaSmoke.ts` not evidenced |
| US-067 | Production backfill | ⏸️ | Pre-launch ops |
| US-068 | Play internal track | 🔴 | Not uploaded |
| US-069 | Closed testing 20+ users | 🔴 | Not started |
| US-070 | Staged rollout | 🔴 | Post closed Beta |
| US-072 | Rollback drill | 🔴 | Not executed |

---

## P0 scorecard

| Status | Count | % of 44 |
|--------|-------|---------|
| ✅ Done | 14 | 32% |
| 🟡 Partial | 19 | 43% |
| 🔴 Missing | 9 | 20% |
| ⏸️ Postponed | 2 | 5% |

**Weighted Free Beta readiness:** ~**56%**

---

## Gap → action table

| Gap | Stories | Action | Classification |
|-----|---------|--------|----------------|
| No meeting link at booking | US-052, US-008, US-031 | Add field in CF from teacher `externalMeetingUrl` or platform default | **Must fix** |
| Join no-op | US-008, US-031 | Implement `_onJoinRequested` + detail CTA | **Must fix** |
| Booking flag off | US-006, US-058 | Staging dart-define / Remote Config | **Must fix** |
| No teacher supply | US-034 | Approve 5+ apps + complete profiles | **Must fix** |
| Eligibility untested | US-061 | 12-case unit file | **Must fix** |
| Report UI + admin queue | US-015, US-040 | S-12 modal + A-10 list | **Must fix** |
| Disputes admin queue | US-041 | A-11 minimal list | **Must fix** |
| FCM not proven | US-009, US-013, US-026, US-055 | Staging device test | **Should fix** |
| Cancel reason length | US-010 | Align to 20 chars | **Should fix** |
| App Check off | — | Enable on prod callables before public | **Should fix** |
| Reschedule mobile E2E | US-011 (P1) | Wire confirm path | Can improve after Beta |
| Filter/search teachers | US-017 | — | Postpone to Production |
| Guardian linking | — | — | Postpone to Production |
| Paid checkout | US-P01+ | — | Postpone to Paid Sessions |
| Admin policy editor UI | A-14 | Use scripts | Remove from Free Beta scope |

---

## Removed / deferred from Beta (explicit)

Per `032` — not gaps:

- US-017 filter UI → Production  
- US-018 EN l10n complete → Production  
- US-P01–P08 → Paid Sessions  
- OTP verify → ADR-003 deferred  
- Agora/WebRTC → Paid/Production  

---

## True blocker summary

**10 tracked blockers** → **8 user-journey blockers** when grouped:

1. meeting_link + join (one journey)  
2. booking flag + teacher supply  
3. eligibility tests  
4. report path (mobile + admin)  
5. disputes admin queue  
6. FCM E2E  
7. staging smoke  
8. Play release track (US-068+) — after code blockers  
