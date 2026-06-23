# Firestore Rules Status — Quran Sessions

**Source:** `firestore.rules` (L98–295)  
**Draft doc:** `docs/security/quran_sessions_firestore_rules_draft.md`  
**Audit:** 2026-06-23

**Legend:** ✅ Done | 🟡 Partial | 🔴 Missing | ⚠️ Risky

---

## Collection rules matrix

| Collection / path | Read | Write (client) | Status | Classification |
|-------------------|------|----------------|--------|----------------|
| `quran_session_market_configs/{countryCode}` | Signed-in | **Denied** | ✅ | Seed via Admin SDK |
| `…/cities/{cityId}` | Signed-in | **Denied** | ✅ | |
| `quran_session_platform_config/{configId}` | Signed-in | **Denied** | ✅ | Global policy |
| `quran_teacher_applications/{applicationId}` | Owner or admin | Create/update: owner draft→pending only | ✅ | ADR-003 |
| `quran_teacher_profiles/{teacherId}` | Admin, owner, or `isPubliclyVisible` | Update: verified owner; trust fields frozen | ✅ | |
| `…/pricing/{marketId}` | Signed-in | **Denied** | ✅ | Admin seed |
| `…/availability_config/{docId}` | Signed-in | Owner (`canEditTeacherAvailability`) | ✅ | |
| `…/availability_overrides/{dateKey}` | Signed-in | Owner | ✅ | |
| `{path=**}/availability/{slotId}` | Signed-in | **Denied** | ✅ | CF generates bookable slots |
| `quran_bookings/{bookingId}` | Admin or participant | **Denied** | ✅ | US-047 |
| `quran_sessions/{sessionId}` | Admin or participant | **Denied** | ✅ | US-047 |
| `quran_session_events/{eventId}` | Signed-in + admin/actor/participant | **Denied** | ✅ | Audit timeline |
| `quran_session_compensations/{id}` | Admin or booking participant | **Denied** | ✅ | |
| `quran_session_refunds/{id}` | Admin or booking participant | **Denied** | ✅ | Paid phase |
| `quran_session_disputes/{id}` | Admin or booking participant | **Denied** | ✅ | |
| `quran_session_reports/{id}` | Admin or reporter | **Denied** | ✅ | |
| `quran_session_operations/{id}` | **Denied** | **Denied** | ✅ | Idempotency backend-only |
| `quran_session_notifications/{id}` | **Denied** | **Denied** | ✅ | Outbox backend-only |
| `quran_reschedule_requests/{id}` | Admin or requester | **Denied** | ✅ | |
| `quran_slot_locks/{id}` | **Denied** | **Denied** | ✅ | |
| `quran_teacher_metrics/{teacherId}` | Admin only | **Denied** | ✅ | |
| `quran_student_metrics/{studentId}` | Admin only | **Denied** | ✅ | |
| `users/{userId}` | Owner get; admin list | Owner update; `quranSessionsProfile` moderation fields frozen | ✅ | Smoke #2 |
| `users/{uid}/fcm_tokens/{tokenId}` | Owner | Owner | ✅ | FCM pipeline |

---

## Helper functions (rules)

| Helper | Purpose | Line ref |
|--------|---------|----------|
| `isAdmin()` | `request.auth.token.admin == true` | ~L20 |
| `canEditTeacherAvailability(teacherId)` | Owner verified teacher | ~L35-38 |
| `quranSessionsProfileModerationUnchanged()` | Block self-unblock | users match |

---

## Write model summary

| Pattern | Collections | Enforced |
|---------|-------------|----------|
| CF-only mutation | bookings, sessions, disputes, reports, compensations, refunds, operations, notifications, slot_locks | ✅ |
| Owner limited write | teacher applications (draft/pending), availability config/overrides, public profile (non-trust fields) | ✅ |
| Read-scoped participant | bookings, sessions | ✅ |
| Admin override read | metrics, all admin lists | ✅ |

**Staff Backend Engineer verdict:** Rules match blueprint CF-facade model. **No speculative rule changes needed for Beta.**

---

## Rules test coverage

| Test file | Coverage | Status |
|-----------|----------|--------|
| `functions/test-rules/usersModeration.rules.test.ts` | `users.quranSessionsProfile` moderation immutability | ✅ Smoke #2 |
| Dedicated `quran_bookings` / `quran_sessions` rules tests | — | 🔴 **Should fix before Free Beta** |

**Gap:** US-047 partially tested — only user moderation path has automated rules test.

---

## Indexes

**File:** `firestore.indexes.json`

Composite indexes exist for session/booking queries (student/teacher ordered by time, status filters). **Status:** ✅ adequate for Beta list screens.

**Classification:** Can improve after Beta — add indexes when admin filter combinations grow.

---

## Security findings

| Finding | Severity | Classification |
|---------|----------|----------------|
| Client cannot mutate booking/session lifecycle | — | ✅ Must-have met |
| Blocked user cannot self-unblock via profile write | — | ✅ |
| Teacher cannot self-verify | Trust fields frozen on profile update | ✅ |
| Applicant cannot self-approve | Application status transition guarded | ✅ |
| Non-participant session read denied | Participant check on booking lookup | ✅ |
| Rules tests thin for quran collections | Medium | Should fix before Free Beta |
