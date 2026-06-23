# Admin Flow Status

**App:** `apps/tilawa_admin` (Angular)  
**Module:** `src/app/features/quran-sessions/`  
**Sidebar:** `sidebar.component.html` L33-54

---

## Available routes (verified)

| Route | Component | Status |
|-------|-----------|--------|
| `/quran-sessions/teacher-applications` | `TeacherApplicationsComponent` | ✅ |
| `/quran-sessions/teacher-applications/:id` | `TeacherApplicationDetailComponent` | ✅ |
| `/quran-sessions/teachers` | `TeachersComponent` | ✅ |
| `/quran-sessions/users` | `QuranSessionsUsersComponent` | ✅ |
| `/quran-sessions/sessions` | `SessionsComponent` | ✅ |
| `/quran-sessions/sessions/:id` | `SessionDetailComponent` | ✅ |
| `/quran-sessions/reports` | — | 🔴 Not in sidebar |
| `/quran-sessions/disputes` | — | 🔴 Not in sidebar |
| `/quran-sessions/policy` | — | 🔴 Not built |
| `/quran-sessions/ledger` | — | ⏸️ Paid phase |

---

## Flow audit

### 1. Teacher application review — ✅

| Check | Status | File |
|-------|--------|------|
| List pending applications | ✅ | `teacher-applications.component.ts` |
| Detail view with phone (admin-only) | ✅ | `teacher-application-detail.component.html` |
| Approve → CF | ✅ | `review-teacher-application.usecase` → `reviewTeacherApplication` |
| Reject with reason + cooldown | ✅ | ADR-003 via CF |
| Mapper tests | ✅ | `quran-sessions.mapper.spec.ts` |

**Stories:** US-033 ✅

---

### 2. Teacher supply management — 🟡

| Check | Status | Notes |
|-------|--------|-------|
| Teachers list | ✅ | `teachers.component.ts` |
| Teacher detail page | 🟡 | Inline/partial per screen-inventory A-05 |
| Suspend/revoke UI | 🟡 | `moderateTeacherProfile` CF; thin UI |
| Seed ≥5 teachers | 🔴 | Ops task US-034 |

**Stories:** US-034 🔴, US-035 🟡

---

### 3. User moderation — 🟡

| Check | Status | File |
|-------|--------|------|
| Quran sessions users list | ✅ | `quran-sessions-users.component.ts` |
| Block account via CF | 🟡 | `moderateQuranSessionsUser` |
| Firestore profile moderation rules | ✅ | `quranSessionsProfileModerationUnchanged` in rules |

**Stories:** US-036 🟡, US-044 ✅

---

### 4. Session operations — 🟡

| Check | Status | File |
|-------|--------|------|
| Sessions list with filters | ✅ | `sessions.component.ts` |
| Session detail + timeline | ✅ | `session-detail.component.ts` |
| Admin cancel | 🟡 | `openCancel` → reason dialog → facade |
| Mark no-show | 🟡 | Classification picker |
| Force complete | 🟡 | `openComplete` |
| Issue compensation | 🟡 | Manual types incl. `restore_credit` |
| Approve refund | ⏸️ | Paid phase |
| Audit export | 🔴 | A-15 planned |

**Stories:** US-037 ✅, US-038 ✅, US-039 🟡

**Gateway:** `firebase-session-moderation.gateway.ts` calls CFs.

---

### 5. Reports queue — 🔴

| Check | Status | Evidence |
|-------|--------|----------|
| A-10 list UI | 🔴 | No route in `sidebar.component.html` |
| CF `reportSessionConcern` | ✅ | `sessionReportCallables.ts` |
| CF `resolveSessionReport` | ✅ | Same file |
| Integration test | ✅ | `sessionReports.integration.test.ts` |
| Mobile reporter UI | 🔴 | Blocks intake |

**Stories:** US-040 🔴, US-015 🔴

---

### 6. Disputes queue — 🔴

| Check | Status | Evidence |
|-------|--------|----------|
| A-11 list UI | 🔴 | Not in sidebar |
| CF `openSessionDispute` | ✅ | `sessionDisputeCallables.ts` |
| CF `resolveSessionDispute` | ✅ | Same file |
| Admin gateway methods | 🟡 | `firebase-session-moderation.gateway.ts` L83+ |
| Integration test | ✅ | `resolveSessionDispute.integration.test.ts` |

**Stories:** US-041 🔴, US-016 🟡

---

### 7. Financial / compensation — 🟡

| Check | Status | Evidence |
|-------|--------|----------|
| `issueSessionCompensation` CF | ✅ | Exported in `index.ts` |
| Admin compensation form on session detail | 🟡 | `session-detail.component.ts` L96+ |
| `manual_pending` when PSP off | ✅ | `financialExecutionStatus()` in `paymentProviderStatus.ts` |
| Ledger UI (A-12) | ⏸️ | Paid |

**Stories:** US-042 🟡, US-056 ✅

---

### 8. Platform policy — 🔴

| Check | Status | Notes |
|-------|--------|-------|
| Global safety policy editor | 🔴 | A-13 |
| Per-teacher eligibility editor | 🔴 | Use cases exist; no admin UI |
| Read policy from Firestore | ✅ | `quran_session_platform_config` rules read-only |

**Stories:** Part of US-048 (read ✅, edit UI 🔴)

---

### 9. Bookings inspection — 🟡

| Check | Status | Notes |
|-------|--------|-------|
| Firestore rules participant read | ✅ | `quran_bookings` L191-197 |
| Dedicated admin bookings view | 🔴 | US-043 partial — sessions view may suffice |

**Stories:** US-043 🟡

---

## Admin test coverage

| Area | Tests |
|------|-------|
| Mapper | `quran-sessions.mapper.spec.ts` |
| Review application use case | `review-teacher-application.usecase.spec.ts` |
| Reports/disputes components | 🔴 None |
| Session detail actions | 🔴 None found |

---

## Admin flow completion estimate

| Segment | % |
|---------|---|
| Teacher onboarding ops | **80%** |
| Session inspection + actions | **55%** |
| Safety (reports/disputes) | **25%** |
| Policy / ledger | **10%** |
| **Overall admin Beta path** | **~42%** |

---

## Critical path for admin Beta

1. Build A-10 reports queue + resolve actions.
2. Build A-11 disputes queue + resolve actions.
3. Wire mobile S-12/S-13 to same CFs.
4. Complete A-09 session action panel (force reschedule if in scope).
5. Ops: seed teachers + run backfill dry-run (US-060).
