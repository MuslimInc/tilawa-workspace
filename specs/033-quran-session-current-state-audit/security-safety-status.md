# Security & Safety Status — Quran Sessions

**Audit:** 2026-06-23  
**References:** `specs/031/data-ownership-security.md`, `specs/031/business-rules.md`, ADR-003

**Legend:** ✅ | 🟡 | 🔴 | ⚠️

---

## Child safety & eligibility

| Control | Implementation | Status | Classification |
|---------|----------------|--------|----------------|
| Profile gate (gender, DOB, country, city) | `ValidateBookingEligibilityUseCase` step 1 | ✅ | |
| Child age threshold | `UserProfile.ageGroup(childAgeThreshold)` | ✅ | |
| `canTeachChildren` per teacher | Step 8 eligibility | ✅ | |
| Guardian approval required | `GuardianApprovalRequiredFailure` emitted | 🟡 | Block only — no linking UI (**Postpone to Production**) |
| `videoCallAllowedForChildren` in picker | Not enforced in UI | 🟡 | **Should fix** if video call type shown |
| Eligibility unit tests | 0 dedicated | 🔴 | **Must fix** (US-061) |

**Security & Safety Reviewer:** Eligibility logic exists in domain + CF (`bookingEligibilityService.ts`) but **untested at unit level** is the main safety regression risk.

---

## Teacher verification (ADR-003)

| Control | Status | Evidence |
|---------|--------|----------|
| Teacher ≠ user role | ✅ | `TeacherProfile` separate from `UserRole` |
| Phone in application only (not public profile) | ✅ | `TeacherApplication` vs `TeacherProfile` |
| Applicant cannot self-approve | ✅ | Firestore rules + CF |
| 30-day re-application cooldown | ✅ | `RejectTeacherApplicationUseCase` |
| Revoke permanent | ✅ | Domain + CF |
| OTP phone verify | ⏸️ | Explicitly deferred |
| Format-only phone validation | ✅ | `PhoneNormalizer` + tests |

---

## Session integrity

| Control | Status | Evidence |
|---------|--------|----------|
| Client cannot write bookings/sessions | ✅ | `firestore.rules` |
| Lifecycle via CF only | ✅ | All mutation callables |
| Idempotency on create/cancel | ✅ | `quran_session_operations` |
| Slot lock anti double-book | ✅ | `quran_slot_locks` |
| Actor attribution on cancel | ✅ | `cancelSessionBooking.ts` |
| Dispute only from completed | ✅ | Lifecycle guard LG-05 |
| Admin cannot direct-write sessions | ✅ | Admin UI uses CF facades |

---

## Reports & disputes

| Control | Status | Gap |
|---------|--------|-----|
| `reportSessionConcern` CF | ✅ | Participant check when `bookingId` set |
| `openSessionDispute` CF | ✅ | Lifecycle guard |
| Mobile report UI | 🔴 | **Must fix before Free Beta** (US-015) |
| Admin reports queue | 🔴 | **Must fix** (US-040) |
| Admin disputes queue | 🔴 | **Must fix** (US-041) |

---

## Account moderation

| Control | Status | Evidence |
|---------|--------|----------|
| Blocked user cannot book | ✅ | CF `account_blocked` smoke #3 |
| Blocked user cannot self-unblock | ✅ | Rules smoke #2 |
| `moderateQuranSessionsUser` CF | ✅ | Admin only |
| Admin UI user list | ✅ | `quran-sessions-users.component.ts` |

---

## App Check & auth

| Control | Status | Classification |
|---------|--------|----------------|
| Firebase Auth on all callables | ✅ | |
| App Check on session callables | 🔴 `enforceAppCheck: false` all | **Should fix before Free Beta** (prod) |
| Real auth UID in prod module | ✅ | `FirebaseAuthSessionProvider` |
| Fake UID in MVP mode only | ✅ | `fake_auth_session_provider.dart` → `student_mvp` |

---

## Privacy

| Data | Exposure | Status |
|------|----------|--------|
| Teacher phone | Admin + application doc only | ✅ |
| Student PII in sessions | Participant + admin read | ✅ |
| Meeting link | Should be participant-only on session doc | 🟡 Field not populated yet |
| FCM tokens | `users/{uid}/fcm_tokens` owner write | ✅ |

---

## Payment / financial safety (Beta)

| Control | Status |
|---------|--------|
| Paid booking blocked when PSP off | ✅ |
| Refunds manual_pending only | ✅ |
| No client payment reference forgery path | ✅ CF validates |

**Postpone to Paid Sessions:** PCI scope, automated refund idempotency with PSP.

---

## Security verdict

| Severity | Count | Items |
|----------|-------|-------|
| **Must fix before Free Beta** | 3 | Eligibility tests, report UI, admin safety queues |
| **Should fix before Free Beta** | 2 | App Check on prod callables, video call child policy in picker |
| **True blockers only** | 3 | Untested eligibility, no report path, no admin triage UI |

**Not blockers for closed Beta:** OTP verify, guardian linking, App Check on staging-only testing (enable before public rollout).
