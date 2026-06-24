# Quran Sessions — Baseline Performance Audit

**Date:** 2026-06-24  
**Method:** Read-only code review of Flutter package, app layer, Cloud Functions, admin panel, Firestore paths/indexes. No profiling run.  
**Framework:** [performance_first_review_framework.md](./performance_first_review_framework.md)

---

## System-wide Performance Impact Analysis (baseline state)

### Backend / Firebase

| Item | Finding |
|------|---------|
| **Queries affected** | All critical paths use scoped collections (`quran_sessions`, `quran_bookings`, `quran_teacher_profiles`, subcollections). Exceptions: legacy `withdrawSlot` collectionGroup scan; unbounded session/lock lists; reminder scheduler window query. |
| **Reads/writes (hot paths)** | Booking: 4–7 reads pre-transaction + 1 platform config + transaction (lock, teacher profile, booking, session, audit). Availability: schedule doc + override range + all teacher locks. Session list: 1 unbounded query per role. |
| **Indexes** | Composites exist for sessions by `studentId`/`teacherId` + `startsAt`, public teachers, notifications, events (`firestore.indexes.json`). Slot locks by `teacherId` indexed. |
| **Global scans?** | **Yes** — `FirestoreAvailabilityDataSource.withdrawSlot` uses `collectionGroup('availability').get()` then filters client-side by `slotId`. |
| **Unbounded queries?** | **Yes** — `getStudentSessions` / `getTeacherSessions` (no `limit`); `getLocksForTeacher` (all locks for teacher); reminder job scans sessions in time window (bounded by window, unbounded at scale). |
| **Complexity before (system)** | Mixed: O(1) direct reads where deterministic IDs used; O(n) client generation bounded by horizon; O(N) global paths for legacy delete and lifetime session lists. |
| **Complexity after (target)** | All paths O(1) or O(k) with bounded k; paginated session lists; direct override/slot doc paths only. |
| **Expected Firestore cost impact** | Acceptable for closed Beta (&lt;500 DAU) except legacy withdraw path and heavy teachers (many sessions/locks). Cost grows linearly with lifetime sessions per user without pagination. |

### Flutter

| Item | Finding |
|------|---------|
| **Rebuild impact** | BLoCs use `restartable`/`sequential` transformers appropriately on cancel/join/delete. `AgoraCallSurface` binds RTC handlers; phase updates are localized. |
| **State update impact** | Teacher dashboard optimistic slot delete with 5s commit timer — good UX, extra state maps (`pendingDeletes`). |
| **List/grouping/sorting** | `groupTeacherAvailabilityByLocalDay` O(n log n); perf tests cap 1000 slots @ 50ms. `MySessionsBloc` splits/sorts full session list on every load. |
| **Memory impact** | Full session list + 14-day generated slots held in memory per dashboard/booking screen — bounded by horizon, not by pagination. |
| **Repeated computations?** | **Partial** — teacher list primary filter now server-side (`arrayContains`); dual-filter still client secondary pass; `_isGeneratedSlotBooked` now O(1) lock read (P0); slot delete commit may still refetch sessions. |

### Audio/Video Provider

| Item | Finding |
|------|---------|
| **Provider affected** | `RoutingSessionCallProvider` → external / mock / optional Agora / WebRTC. Production path: Agora via `FirebaseCallTokenProvider` + `issueSessionRtcToken` CF. |
| **Startup latency risk** | **Medium** — `LiveAgoraRtcJoinGateway` creates and initializes new `RtcEngine` per join; CF round-trip for token before join. |
| **Network/battery risk** | **Medium** — full A/V SDK on low-end Android; no documented poor-network profile on OPPO-class device. |
| **Token/channel generation cost** | 1 callable + 3 Firestore reads (session, booking, teacher profile userId) server-side. |
| **Low-end Android risk** | **Unverified** — Agora pool tests exist; no device matrix evidence in repo. |

### Verdict

- **Performance safe for closed Beta at low volume?** **Mostly yes**, with **two code-level exceptions**: legacy slot `withdrawSlot` global scan and unbounded session lists for active teachers/students.
- **What must change first (perf-first):** (1) Replace collectionGroup withdraw with teacher-scoped direct delete. (2) Paginate session lists. (3) Scope slot-lock queries by time window. (4) Add slow-network device smoke (US-066).

---

## Per-flow complexity reporting

### 1. Booking creation

| Field | Value |
|-------|-------|
| **Key files** | Client: `firestore_booking_repository.dart`, `create_session_booking_usecase.dart`. Server: `createSessionBooking.ts`, `bookingEligibilityService.ts`, `idempotencyService.ts`. |
| **Current complexity** | Client: O(1) schedule read + 1 callable. Server: O(1) eligibility reads (3–5 docs parallel + optional market/pricing) + O(1) idempotency + transaction O(1) lock get/set. **No server validation that slot exists in generated availability** (lock-only collision prevention). |
| **Target complexity** | O(1) reads; optional slot-exists check via deterministic slotId without scan. |
| **Data structures** | `quran_slot_locks/{slotId}` deterministic lock; random IDs for booking/session docs; `Set` idempotency keys; participant map in session doc. |
| **Bottleneck** | Duplicate eligibility + platform config reads (loaded pre-tx, platform read again in handler); callable cold start; client sends `startsAt`/`endsAt` derived from schedule read (extra round-trip). |
| **Recommended optimization** | Merge platform config into eligibility load; pass `slotDurationMinutes` from client cache only for display — server derives end from schedule in tx; document lock-only model or add O(1) slot validation. |
| **Free Beta blocker?** | **No** (functional). **Yes** for child bookings — `guardian_approval_required` blocks without capture flow (product/safety, not perf). |

---

### 2. Availability loading

| Field | Value |
|-------|-------|
| **Key files** | `get_teacher_availability_usecase.dart`, `slot_generator.dart`, `firestore_schedule_repository.dart`, `firestore_booked_slot_lock_data_source.dart`. |
| **Current complexity** | 3 network round-trips: schedule O(1), overrides O(d) where d = days in window, locks O(L) all locks for teacher. Client generation O(d × slots_per_day) — perf tests: 14d &lt;200ms, 90d &lt;800ms. |
| **Target complexity** | O(1) schedule + O(d) overrides + O(k) locks in window only; generation O(d × s) with small s. |
| **Data structures** | `Map<String, AvailabilityOverride>` by dateKey in `SlotGenerator`; `Set<DateTime>` booked starts; `List<GeneratedSlot>` output. |
| **Bottleneck** | `getLocksForTeacher` fetches **all** locks — no `startsAt`/expiry filter at query level. Legacy dual-query via `_loadLocks` doubles reads for migrated teachers. |
| **Recommended optimization** | Composite query locks by `teacherId` + expiry/window; cache schedule+overrides per teacher for booking session; single lock query. |
| **Free Beta blocker?** | **No** at Beta volume; **Yes** if teacher accumulates hundreds of locks without TTL cleanup. |

---

### 3. Slot deletion

| Field | Value |
|-------|-------|
| **Key files** | `teacher_dashboard_bloc.dart`, `block_generated_slot_usecase.dart`, `firestore_availability_repository.dart` (legacy withdraw). |
| **Current complexity** | **Generated slots:** O(1) `getOverrideByDate` + O(1) `saveOverride` — incremental, no full regen. **Legacy published slots:** `withdrawSlot` → **O(N) collectionGroup scan** across all `availability` subcollections. Commit path: `_isGeneratedSlotBooked` → full `getTeacherSessions` O(S). |
| **Target complexity** | O(1) per delete — direct doc path `teacher_profiles/{id}/availability/{slotId}` or override-only for generated. |
| **Data structures** | Optimistic `Map<String, PendingSlotDelete>`; override doc per date key; `DayIntervalEditor` subtracts one interval. |
| **Bottleneck** | CollectionGroup withdraw; session list refetch on every commit to detect booking. |
| **Recommended optimization** | Require `teacherId` on withdraw (API already has it in dashboard); delete `doc(teacherId, slotId)`; replace session scan with lock doc read or slotId parse + lock check. |
| **Free Beta blocker?** | **Yes** for legacy withdraw path — global scan can timeout and scales with platform slot count. Generated path: **No**. |

---

### 4. Availability override lookup

| Field | Value |
|-------|-------|
| **Key files** | `firestore_schedule_repository.dart` (`getOverrideByDate`, `getOverrides`), `slot_generator.dart`, `block_generated_slot_usecase.dart`. |
| **Current complexity** | Single date: **O(1)** direct `doc(dateKey)`. Range: O(d) docs in range query. Generator: O(1) per day via `overrideByDate` map. |
| **Target complexity** | O(1) single date; O(d) range — already met. |
| **Data structures** | Deterministic override doc ID = `yyyy-MM-dd`; `Map<String, AvailabilityOverride>` in generator. |
| **Bottleneck** | Range fetch when `from`/`to` spans full horizon on dashboard load (≤14 days — acceptable). |
| **Recommended optimization** | None critical; ensure `getOverrides` always passes tight `from`/`to` (already done in use case). |
| **Free Beta blocker?** | **No**. |

---

### 5. Teacher list loading

| Field | Value |
|-------|-------|
| **Key files** | `firestore_teacher_repository.dart`, `teacher_list_bloc.dart`. |
| **Current complexity** | O(page_size) query with `limit(20)` + cursor; **primary** filter via `arrayContains` on `specializations` or `teachingLanguages` (one per query; specialization wins). Dual-filter: O(page_size) client pass on language. |
| **Target complexity** | O(page_size) server-side filtered query with composite index. |
| **Data structures** | `List<QuranTeacherDto>`; cursor = last doc id. |
| **Bottleneck** | Both filters active: only specialization in query — language still client-side; may under-fill page. |
| **Recommended optimization** | **Done (P2.8)** primary filter + indexes. Optional: composite query strategy when both filters common. |
| **Free Beta blocker?** | **No** (perf). UX impact when filters used: **Yes** (empty list despite more teachers). |

---

### 6. Session list loading

| Field | Value |
|-------|-------|
| **Key files** | `firestore_session_repository.dart`, `my_sessions_bloc.dart`, teacher dashboard load. |
| **Current complexity** | **O(S)** — unbounded `where(studentId|teacherId).orderBy(startsAt).get()`; client split upcoming/past + sort. |
| **Target complexity** | O(page_size) with cursor; optional "upcoming only" query with `startsAt >= now` + limit. |
| **Data structures** | `List<QuranSessionDto>` → domain entities; no pagination state in BLoC. |
| **Bottleneck** | Lifetime session growth; teacher dashboard loads all sessions every refresh; used again on slot delete commit. |
| **Recommended optimization** | Paginate student/teacher lists; dashboard: upcoming sessions query only; cache session list during dashboard session. |
| **Free Beta blocker?** | **No** for new Beta users; **Yes** for teachers with long history or heavy delete-commit churn. |

---

### 7. Join info loading

| Field | Value |
|-------|-------|
| **Key files** | `session_detail_bloc.dart`, `firebase_session_aggregate_repository.dart`, `join_session_usecase.dart`. |
| **Current complexity** | Load: aggregate O(1) + timeline O(events) + optional session O(1) for call context + reschedule query. Join: session O(1) + teacher profile O(1) for role resolution. |
| **Target complexity** | O(1) for join metadata on detail screen; timeline bounded. |
| **Data structures** | `SessionAggregate`; `CallJoinRequest` built from session fields (`meetingLink`, `providerSessionId`, `joinToken`). |
| **Bottleneck** | Multiple sequential reads on detail load (aggregate, timeline, session, reschedule); no single "join bundle" callable. |
| **Recommended optimization** | Aggregate doc includes join fields needed for UI; lazy-load timeline; optional `getSessionJoinInfo` callable for RTC refresh. |
| **Free Beta blocker?** | **No**. |

---

### 8. Report / dispute creation

| Field | Value |
|-------|-------|
| **Key files** | `sessionReportCallables.ts`, `sessionDisputeCallables.ts`, `open_session_dispute_usecase.dart`, `report_session_concern_usecase.dart`. |
| **Current complexity** | O(1) booking read + optional student/guardian read + idempotent write transaction. Report without booking: O(1) write. |
| **Target complexity** | O(1) — met. |
| **Data structures** | `quran_session_reports`, `quran_session_disputes` with server-generated IDs; idempotency keys. |
| **Bottleneck** | Extra teacher profile userId resolution per call; acceptable. |
| **Recommended optimization** | Denormalize `teacherUserId` on booking for report/dispute paths. |
| **Free Beta blocker?** | **No** (perf). Product: report path must be reachable in app (tracked in 033 audit). |

---

### 9. Admin dispute / report list

| Field | Value |
|-------|-------|
| **Key files** | `firebase-session-dispute-read.repository.ts`, `firebase-session-report-read.repository.ts`. |
| **Current complexity** | O(page_size + 1) with `orderBy(createdAt desc).limit(26)` + cursor — **good**. Optional status filters via `where`. |
| **Target complexity** | O(page_size) — met. |
| **Data structures** | Firestore cursor pagination; DTO mappers. |
| **Bottleneck** | None at Beta scale; ensure indexes for filtered admin queries. |
| **Recommended optimization** | Document composite indexes for filter + `createdAt` if adding heavy filters. |
| **Free Beta blocker?** | **No**. |

---

### 10. Notification targeting

| Field | Value |
|-------|-------|
| **Key files** | `notificationOutboxService.ts`, `deliverSessionNotification.ts`, `fcmTokenService.ts`, `sessionReminders.ts`. |
| **Current complexity** | Enqueue: O(1) write per event. Deliver: O(r) user doc reads for r recipients (`collectActiveFcmTokens` batches of 10). Reminders: O(window_sessions) query hourly + per-doc teacher userId resolve. |
| **Target complexity** | O(r) reads for delivery; reminders O(k) in time window with indexed query. |
| **Data structures** | `recipientUserIds: string[]` on outbox doc; `users.notifications.activeFcmToken` single-token model. |
| **Bottleneck** | Legacy sessions without `teacherUserId` still hit profile resolve; scheduler scans all sessions in 30-min window each hour. |
| **Recommended optimization** | **Done (P2.9–10)** `teacherUserId` on new session/booking docs; reminders read denormalized field first. Scale: shard reminder windows or per-session scheduled tasks. |
| **Free Beta blocker?** | **No** at Beta volume; E2E push delivery unverified (033: treat as closed-Beta blocker for **reliability**, not algorithm). |

---

### 11. Single active device validation

| Field | Value |
|-------|-------|
| **Key files** | `registerActiveDevice.ts`, `sessionRegistration.ts`, `sessionAuth.ts` (`requireValidSessionEpoch`), client `callable_session_payload_builder.dart`. |
| **Current complexity** | O(1) user doc read per protected callable; epoch compare O(1). Register: O(1) user read/write + optional legacy FCM token batch delete. |
| **Target complexity** | O(1) — met. |
| **Data structures** | `users.sessionEpoch`, `users.activeDeviceId`, `notifications.activeFcmToken`. |
| **Bottleneck** | Extra read on **every** session callable; acceptable for security. Stale epoch UX (user confusion) not perf. |
| **Recommended optimization** | Cache epoch client-side with invalidation on `session_revoked` push; server unchanged. |
| **Free Beta blocker?** | **No** (perf). |

---

### 12. Agora / external / mock join path

| Field | Value |
|-------|-------|
| **Key files** | `routing_session_call_provider.dart`, `external_meeting_call_provider.dart`, `mock_session_call_provider.dart`, `agora_rtc_join_gateway.dart`, `agora_call_surface.dart`, `issueSessionRtcTokenService.ts`. |
| **Current complexity** | External: O(1) URL launch. Mock: O(1) local. Agora: 1 CF + engine `createAgoraRtcEngine` + initialize + join channel — **heavy constant factor**. `leaveSession`/`endSession` on router invokes **all** registered providers sequentially. |
| **Target complexity** | O(1) network + one SDK init per session; leave only active provider. |
| **Data structures** | `CallJoinRequest`; `AgoraRtcEnginePool` session handles; server Agora token builder. |
| **Bottleneck** | Per-join engine init; multi-provider leave fan-out; token fetch adds RTT before join; Agora credentials missing → hard failure. |
| **Recommended optimization** | Reuse engine pool across joins; route leave/end to joined provider only; prefetch token when session detail opens; fallback UI for external meeting when Agora fails. |
| **Free Beta blocker?** | **Yes** if Agora credentials unset on staging/production — join fails. **Unverified** on target Android hardware. |

---

## Top 5 performance blockers

1. **Legacy `withdrawSlot` collectionGroup scan** — `firestore_availability_repository.dart` loads entire `availability` collection group to find one `slotId`; unbounded O(N) platform-wide.
2. **Unbounded session list queries** — `getStudentSessions` / `getTeacherSessions` fetch full history; amplified by teacher dashboard refresh and slot-delete booking checks.
3. **Unscoped slot-lock fetch** — `getLocksForTeacher` returns all locks; dual legacy query doubles reads for some teachers.
4. **Agora per-join SDK init + token callable RTT** — cold engine create/initialize/join on each session; no proven low-end Android profile.
5. **Teacher list client-side filtering** — wastes Firestore reads and pagination when specialization/language filters applied.

---

## Top 5 UX blockers (after perf lens)

1. **Guardian approval required with no in-app capture flow** — child bookings blocked server-side (`bookingEligibilityService.ts`); dead-end for families.
2. **Session epoch stale errors** — multi-device sign-in revokes callables with technical lifecycle errors; users may not understand "signed in elsewhere."
3. **Join reliability unproven** — Agora credential/config gaps and missing OPPO-class slow-network smoke; fast UI useless if join fails silently or times out.
4. **Teacher list filter empty states** — client filter after page fetch shows empty list while more teachers exist server-side.
5. **Dashboard refresh vs pending slot delete** — pull-to-refresh discards undo window (`refreshDiscardedPendingCount`); user may lose undo without clear explanation.

---

## UI (third priority)

Not audited in depth for this baseline. Known from 033/034: token migration and bottom-CTA reach are **post-perf** polish items. Do not prioritize visual consistency work ahead of blockers above.

---

## Free Beta blockers (performance / reliability)

| Blocker | Severity |
|---------|----------|
| Legacy `withdrawSlot` collectionGroup scan | **Yes** — perf/cost/timeouts |
| Agora join on target devices unverified | **Yes** — reliability |
| Unbounded session lists (active teachers) | **Conditional Yes** — grows with usage |
| Guardian approval product block | **Yes** — not perf, but blocks booking segment |
| FCM E2E unverified | **Yes** — notification reliability (033) |

**Summary:** At least **one hard perf blocker** (collectionGroup withdraw). **Join + notifications** are reliability blockers before open Free Beta.

---

## Recommended next implementation phase (perf-first)

**Phase P0 — Firestore hot paths (1–2 sprints)**

1. Fix `withdrawSlot`: require `teacherId`, delete `teacher_profiles/{id}/availability/{slotId}` — remove collectionGroup.
2. Paginate `getStudentSessions` / `getTeacherSessions` (page size 20–30, cursor on `startsAt`).
3. Scope `getLocksForTeacher` with window filter or TTL on expired soft locks.
4. Replace `_isGeneratedSlotBooked` session scan with O(1) lock doc read.

**Phase P1 — Join path**

5. Agora engine pool reuse + leave only active provider.
6. Staging credential check + OPPO/slow-3G join smoke script.
7. Optional token prefetch on session detail when join window open.

**Phase P2 — Query efficiency**

8. Server-side teacher list filters + indexes.
9. Denormalize `teacherUserId` on session/booking for CF read reduction.
10. Reminder job: batch teacher userId resolution.

**Phase P3 — UX (after P0–P1 green)**

11. Guardian approval capture flow.
12. Session epoch user-facing copy + re-auth path.
13. Filter-empty-state UX for teacher list.

Each phase must ship with Performance Impact Analysis + updated complexity table rows per the framework.

### Implementation status (2026-06-24)

| Item | Status | Notes |
|------|--------|-------|
| P0.1–4 | Shipped (prior) | withdraw scoped; session pagination; lock window; O(1) booked check |
| P2.8 | **Done** | `firestore_teacher_repository.dart` + composites in `firestore.indexes.json` |
| P2.9 | **Done** | `createSessionBooking.ts` writes `teacherUserId` on session + booking |
| P2.10 | **Done** | `sessionReminders.ts` uses `teacherUserIdFromDenormalizedSessionData` |
| P3.13 | **Done** | Teacher list filter-empty state + clear-filters CTA |
| P1.5–7 | **Done** | Active-provider routing leave; Agora engine park/reuse; RTC token prefetch on detail; `scripts/stagingRtcJoinSmoke.ts` |
| P3.11–12 | **Done** | Guardian approval capture screen + `approveChildGuardianBooking` CF; session epoch dialog → login |
| Indexes deploy | **Script** | `./scripts/deploy_firestore_indexes.sh` |
| CF deploy | **Script** | `./scripts/deploy_quran_session_callables.sh` (+ App Check env) |
| Manual E2E | **Ops** | B1–B5 / T2–T8 checklist after staging deploy |

---

## References (verified in codebase)

| Path | Role |
|------|------|
| `apps/tilawa/lib/features/quran_sessions/data/firebase/firestore_availability_repository.dart` | Legacy withdraw scan |
| `packages/quran_sessions/lib/src/domain/usecases/get_teacher_availability_usecase.dart` | Generated availability |
| `packages/quran_sessions/lib/src/domain/services/slot_generator.dart` | O(1) override map |
| `apps/tilawa/lib/features/quran_sessions/data/firebase/firestore_session_repository.dart` | Unbounded session queries |
| `functions/src/quranSessions/createSessionBooking.ts` | Booking transaction |
| `functions/src/quranSessions/issueSessionRtcTokenService.ts` | RTC token issuance |
| `packages/quran_sessions_rtc/lib/src/boundaries/call/agora_rtc_join_gateway.dart` | Agora init/join |
| `apps/tilawa_admin/src/app/core/data/repositories/firebase-session-dispute-read.repository.ts` | Paginated admin disputes |
