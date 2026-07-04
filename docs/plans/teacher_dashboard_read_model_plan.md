# Teacher Dashboard Read Model (O(1) reads) — Implementation Plan

Status: **planned** (no code yet)
Goal: entering `/sessions/dashboard` costs **one Firestore document read** on
mobile, and every backend mutation keeps that document fresh with **O(1)
incremental work** (bounded recompute + one write). No per-entry fan-out
queries at read time.

Prior work (already shipped on `feature/learn-quran`): the client-side loader
was de-serialized — `GetTeacherDashboardUseCase` now runs its profile/config,
schedule, and sessions fetches concurrently, and availability generation
reuses the fetched schedule instead of re-reading it. That cut ~4s of serial
round trips to ~500ms, but it is still **5 network reads per cold entry**.
This plan removes the remaining O(n).

---

## 1. Current read fan-out (what we're replacing)

Per dashboard entry, `GetTeacherDashboardUseCase`
(`packages/quran_sessions/lib/src/application/usecases/get_teacher_dashboard_usecase.dart`)
reads:

| # | Read | Source |
|---|---|---|
| 1 | Teacher profile | `quran_teacher_profiles/{teacherProfileId}` |
| 2 | Owner user profile | `users/{userId}` |
| 3 | Scheduling config | `quran_session_market_configs/{country|global}` (1–2 reads) |
| 4 | Weekly schedule | `quran_teacher_profiles/{id}/availability_config/schedule` |
| 5 | Upcoming sessions | `quran_sessions` query (`teacherId ==`, horizon) |
| 6 | Overrides | `quran_teacher_profiles/{id}/availability_overrides` range query |
| 7 | Booked slot locks | `quran_slot_locks` query (active locks in window) |

Reads 5–7 scale with data volume (O(n) documents). Slot *generation* is
already client-side and bounded (14-day horizon) — it stays as is.

## 2. Target architecture — materialized summary document

### 2.1 Document

Path: `quran_teacher_profiles/{teacherProfileId}/dashboard/summary`

A subcollection doc (not a new top-level collection) so rules scope naturally
under the existing `quran_teacher_profiles` match block.

```jsonc
{
  "revision": 42,                  // monotonic, for debugging staleness
  "updatedAt": Timestamp,
  "horizonDays": 14,

  // §1 reads 1–3, denormalized
  "teacher": { "userId", "timezone", "countryCode", "displayName" },
  "schedulingConfig": { /* resolved market-or-global config snapshot */ },

  // §1 read 4 — the schedule doc is small; embed verbatim
  "weeklySchedule": { /* same shape as availability_config/schedule */ },

  // §1 reads 6–7, windowed to horizon
  "overrides": [ { "date", "..." } ],          // horizon window only
  "bookedStartsUtc": [ Timestamp ],            // active locks in window

  // §1 read 5, split the way the bloc consumes it
  "pendingBookingRequests": [ { /* session card fields */ } ],
  "upcomingSessions": [ { /* session card fields */ } ]   // capped, sorted
}
```

Size budget: session entries ≈ 0.5 KB each; cap `upcomingSessions` +
`pendingBookingRequests` at 200 combined (≈ 100 KB worst case, far under the
1 MiB doc limit). If a teacher exceeds the cap, the doc stores the first 200
by `startsAt` and sets `"truncated": true`; the client falls back to the
legacy query path for that teacher (rare, acceptable).

### 2.2 Complexity after

| Actor | Operation | Cost |
|---|---|---|
| Mobile | Enter dashboard | **1 doc read** (or 1 listener) + local slot generation over 14-day window |
| Backend | Session mutation | 1 bounded recompute of the sessions arrays + 1 doc write |
| Backend | Schedule/override edit | copy small doc(s) into summary + 1 doc write |
| Backend | Lock create/expire | recompute `bookedStartsUtc` window + 1 doc write |

"Near O(1)": recomputes re-query only the horizon window for the affected
section (bounded constant ≤ 200 docs), never unbounded history.

## 3. Backend (functions/)

### 3.1 Projector module

`functions/src/quranSessions/dashboardProjection/`

- `dashboardSummaryService.ts` — pure builders: given source snapshots,
  produce each summary section. Mirrors the field mapping the app's DTOs use
  today (`packages/quran_sessions/lib/src/data/dtos/…`) so the Dart mapper is
  a straight decode.
- `projectTeacherDashboard.ts` — orchestrator: `rebuildSection(teacherId,
  section)` runs the bounded query for one section and merges it into the
  summary doc in a transaction, bumping `revision`.

### 3.2 Triggers (v2 `onDocumentWritten`)

Triggers, not callable-embedded writes, because schedule and overrides are
written **directly by the app** (`firestore_schedule_repository.dart` `set()`
calls), bypassing the callables. Triggers catch every write path uniformly,
including admin tooling and future writers.

| Trigger doc | Rebuilds section |
|---|---|
| `quran_sessions/{sessionId}` | `pendingBookingRequests` + `upcomingSessions` for `teacherId` |
| `quran_teacher_profiles/{id}/availability_config/schedule` | `weeklySchedule` |
| `quran_teacher_profiles/{id}/availability_overrides/{dateKey}` | `overrides` |
| `quran_slot_locks/{lockId}` | `bookedStartsUtc` for `teacherId` |
| `quran_teacher_profiles/{id}` | `teacher` + `schedulingConfig` (country may change) |
| `users/{uid}` (countryCode change only, guarded) | `schedulingConfig` |

Ordering/idempotency: each trigger rebuilds its section **from a fresh
bounded query inside the transaction** (recompute, not patch), so replayed or
out-of-order events converge. No outbox needed.

### 3.3 Time-based staleness

Two decay sources, two mitigations:

- **Client-side filtering (authoritative for UX):** the app filters
  `upcomingSessions`/`bookedStartsUtc` by `now` on read — a stale doc never
  shows past sessions.
- **Scheduled prune:** extend the existing scheduled-function pattern
  (`sessionReminders.ts`, `expirePendingReservations.ts`) with a daily
  `pruneDashboardSummaries` job that drops expired entries and refreshes the
  override/lock windows. Cheap: one query per *active* teacher (collection
  group query on `dashboard/summary` where `updatedAt` is recent).

### 3.4 Backfill

None upfront. Missing summary doc ⇒ client falls back to the legacy path
(§4.2), and the first subsequent mutation materializes the doc. Optional
one-off script under `functions/src/migration/` if we want warm docs for all
approved teachers before flipping the flag to default-on.

## 4. Mobile (packages/quran_sessions + apps/tilawa)

### 4.1 Data layer

- New `TeacherDashboardSummaryRepository` boundary +
  `FirestoreTeacherDashboardSummaryRepository` (one `get()` on the summary
  doc; DTO → existing `TeacherDashboardResult`).
- `GetTeacherDashboardUseCase` gains a summary-first branch:
  1. summary doc exists, not `truncated`, `updatedAt` within TTL → use it
     (1 read);
  2. otherwise → existing multi-fetch path unchanged (it already backs
     `forceRefresh`, offline cache semantics, and tests).
- Bloc, screen, and `TeacherDashboardSuccess` state are untouched — the use
  case contract (`TeacherDashboardResult`) is the seam.

### 4.2 Fallback & flag

Gate with an `AppLaunchConfig` flag (same mechanism as `learnQuranStudent`),
default off → staging on → default on. The legacy path is kept permanently as
the `truncated`/missing-doc fallback, so no flag-day risk.

### 4.3 Later (not this phase)

Swap the one-shot `get()` for a snapshot listener — same doc, live dashboard
updates for free. Deliberately out of scope until the projection is proven.

## 5. Firestore rules

New match block (required — see repo convention that new collections must
land with rules in the same change):

```
match /quran_teacher_profiles/{teacherId} {
  match /dashboard/{docId} {
    // Owner-only read; summary contains booking/student data.
    allow read: if isAdmin() || isVerifiedTeacherProfileOwner();
    allow write: if false;   // Cloud Functions only (admin SDK bypasses rules)
  }
}
```

Deploy with `firebase deploy --only firestore:rules` alongside the functions.

## 6. Testing & verification

- **Functions:** jest unit tests in `quranSessions/__tests__/` for the
  section builders (pure) and one emulator test per trigger asserting the
  summary converges after out-of-order writes.
- **Dart:** contract test that summary-path and legacy-path produce identical
  `TeacherDashboardResult` for the same fixture data (the projection's field
  mapping is the main drift risk); bloc tests unchanged.
- **Perf gate:** the existing `[PerformanceTrace]` logging — dashboard entry
  should show a single `firestore_getDashboardSummary` trace and no
  `getSchedule`/`getOverrides`/`getTeacherUpcomingSessions` traces when the
  flag is on.

## 7. Rollout

1. Land projector + triggers + rules (writes only; nothing reads the doc).
2. Verify docs materialize correctly in staging via mutations.
3. Land mobile summary-first path behind the flag; enable in staging.
4. Compare parity (contract test + manual QA on a seeded teacher).
5. Default the flag on; keep legacy path as structural fallback.

## 8. Open questions

- Should `schedulingConfig` changes (admin edits to
  `quran_session_market_configs`) fan out to all teacher summaries in that
  market, or is next-mutation/daily-prune freshness acceptable? (Plan assumes
  the latter; config edits are rare and non-urgent.)
- Cap value (200) — confirm against real max sessions-per-teacher in prod.
- Does the student-side home/my-sessions screen want the same treatment? The
  projector is per-audience; a `studentDashboards` twin is a copy of this
  plan, not a redesign.
