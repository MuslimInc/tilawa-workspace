# UX / UI Status — Quran Sessions

**Screens:** `packages/quran_sessions/lib/src/presentation/screens/`  
**Design tokens:** Package uses `context.quranSessionsL10n` + theme; partial hardcoded padding  
**Audit:** 2026-06-23

**Legend:** ✅ | 🟡 | 🔴 | ⚠️ | ⏸️

---

## Screen inventory vs blueprint (`031/screen-inventory.md`)

| ID | Screen | File | Status | UX notes |
|----|--------|------|--------|----------|
| S-01 | Home entry | `home_sessions_entry_card.dart` (app) | ✅ | Experimental badge |
| S-02 | Sessions hub | `quran_sessions_home_screen.dart` | ✅ | |
| S-03 | Teacher list | `teacher_list_screen.dart` | 🟡 | No filter chips (US-017 postponed) |
| S-04 | Teacher profile | `teacher_profile_screen.dart` | ✅ | Reviews list missing — Production |
| S-05 | Profile completion | `profile_completion_screen.dart` | ✅ | Country/city pickers |
| S-06 | Booking | `booking_screen.dart` | 🟡 | Gated by booking flag; eligibility inline errors ✅ |
| S-07 | My sessions | `my_sessions_screen.dart` | 🟡 | Join dispatches event to **no-op** handler |
| S-08 | Session detail | `session_detail_screen.dart` | 🔴 | Timeline only — no actions |
| S-09 | Reschedule | `reschedule_session_screen.dart` | 🟡 | Screen exists; limited entry points |
| T-01 | Teacher apply | `teacher_application_screen.dart` | ✅ | Flag-gated |
| T-02 | Application status | `teacher_application_status_screen.dart` | ✅ | |
| T-03 | Complete teacher profile | `complete_teacher_public_profile_screen.dart` | ✅ | |
| T-04 | Weekly availability | `weekly_availability_screen.dart` | ✅ | |
| T-05 | Overrides | `availability_override_sheet.dart`, vacation dialogs | ✅ | |
| T-06 | Teacher dashboard | `teacher_dashboard_screen.dart` | ✅ | Capability gate |
| S-12 | Report concern modal | — | 🔴 | **Must fix** |
| S-13 | Dispute modal | — | 🔴 | P1 — can ship admin-only triage for Beta |

---

## P0 UX issues

| Issue | Evidence | Role | Classification |
|-------|----------|------|----------------|
| Cannot join session | `my_sessions_bloc.dart` L96-99 empty; no link in CF | PM + UX | **Must fix** |
| Session detail useless for actions | `session_detail_screen.dart` — status + timeline only | UX | **Must fix** |
| Booking disabled silently | Nav redirect when `quranSessionsBookingEnabled` false | PM | **Must fix** (staging flag) |
| Cancel reason min 3 chars vs spec 20 | `cancel_session_sheet.dart` L110 | UX + QA | Should fix |
| No report entry point | No modal/screen | Safety | **Must fix** |
| Guardian failure no remediation | `GuardianApprovalRequiredFailure` blocked only | Safety | Postpone to Production |
| Hardcoded padding in detail | `session_detail_screen.dart` `EdgeInsets.all(16)` | UI Kit | Can improve after Beta |
| Pull-to-refresh missing on My Sessions | Not in screen | UX | Can improve after Beta |
| Empty state illustrations | Text-only empty states | UX | Can improve after Beta |

---

## RTL / localization

| Check | Status | Evidence |
|-------|--------|----------|
| Package l10n AR + EN | ✅ | `packages/quran_sessions/l10n/` |
| Screens use `quranSessionsL10n` | 🟡 | Most screens migrated |
| App-level `context.l10n` for sessions | 🟡 | Home entry still app l10n |
| RTL layout audit | 🟡 | No formal audit doc; Arabic primary |
| Date formatting | 🟡 | `MaterialLocalizations` + `intl` |

**Principal UX Designer:** Arabic-first is acceptable for Free Beta closed cohort. EN completeness is **Postpone to Production** (US-018).

---

## Trust & safety UX

| Flow | UI state | Status |
|------|----------|--------|
| Profile incomplete | Inline CTA "إكمال الملف الشخصي" on booking | ✅ |
| Gender mismatch | Inline failure message | ✅ |
| Market disabled | `MarketNotEnabledFailure` message | ✅ |
| Teacher not verified | `TeacherNotVerifiedFailure` | ✅ |
| Account blocked | `AccountBlockedFailure` | ✅ |
| Report safety concern | No UI | 🔴 |
| Dispute after complete | No UI | 🟡 P1 |

---

## UI Kit alignment

| Check | Status |
|-------|--------|
| `TilawaCard` pattern for session cards | 🟡 — package uses custom cards |
| Theme tokens vs hardcoded | 🟡 — some `const EdgeInsets` in package screens |
| Experimental badge on entry | ✅ |

**Staff Flutter Engineer:** Token migration in package is **Can improve after Beta** — not a launch blocker for closed testing.

---

## UX verdict by priority

| Priority | Count | Examples |
|----------|-------|----------|
| P0 gaps | 4 | Join, session detail actions, report UI, booking flag messaging |
| P1 gaps | 5 | Cancel from detail, reschedule entry, teacher no-show UI, FCM deep link |
| P2 (Production) | 4 | Filter chips, search, illustrations, full EN |
