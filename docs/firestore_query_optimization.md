# Firestore Query Optimization — Quran Sessions

Operational guide for monitoring, indexing, and tuning Firestore queries used by
Quran Sessions. Query shapes are derived from
`apps/tilawa/lib/features/quran_sessions/data/firebase/`.

Related docs:

- [Quran Sessions Firestore data model](quran_sessions_firestore_data_model.md)
- [Backend migration](quran_sessions_backend_migration.md)
- Index definitions: [`firestore.indexes.json`](../firestore.indexes.json)

---

## Query Insights overview

[Firestore Query Insights](https://firebase.google.com/docs/firestore/enterprise/query-insights)
(Firestore Enterprise) surfaces per-query telemetry in the Firebase Console:
execution count, latency, documents scanned, index entries scanned, and billable
read operations. Use it after deploys and under load to catch missing indexes,
full-collection scans, and queries that return more documents than the UI needs.

> Query Insights requires Firestore in **Enterprise edition**. On Standard edition,
> rely on client-side `FAILED_PRECONDITION` index links, Cloud Monitoring export,
> and the inventory below.

### How to use Query Insights

1. Open [Firebase Console](https://console.firebase.google.com/) → your project.
2. **Build** → **Firestore Database** → **Query Insights** tab.
3. Set the time range (default: last 24 hours).
4. Sort by **Avg execution duration** or **Billable read operations** to find
   expensive queries first.
5. Click a query row to see the normalized query text, index used (or “none”),
   and per-metric breakdown.
6. Cross-check the query against the [inventory](#query-inventory) below and
   [`firestore.indexes.json`](../firestore.indexes.json).

---

## Metrics reference

| Metric | What it means | Action when high |
|--------|---------------|------------------|
| **Execution count** | How often the query ran in the window | Expected for hot paths; spikes may indicate retry loops or missing pagination |
| **Error count** | Failed executions (often missing index, permission, or timeout) | Fix index (`FAILED_PRECONDITION` link) or security rules first |
| **Avg execution duration** | End-to-end latency per execution | Add/locate composite index; reduce scanned docs; add `limit()` |
| **Avg documents scanned** | Documents read to satisfy the query | Tighten filters; avoid collectionGroup full scans; paginate |
| **Avg index entries scanned** | Index entries examined | Usually tracks documents scanned; indicates inefficient range or inequality |
| **Billable read operations** | Charged document reads | Primary cost signal — target queries where reads ≫ documents returned |

---

## Query inventory

Implementation files (Tilawa app layer only — domain/package code has no Firestore):

| Datasource | File |
|------------|------|
| Market config | `firestore_market_config_repository.dart` |
| Teacher applications | `firestore_teacher_application_repository.dart` |
| Teacher profiles | `firestore_teacher_profile_repository.dart` |
| Teachers (discovery) | `firestore_teacher_repository.dart` |
| Availability | `firestore_availability_repository.dart` |
| Bookings | `firestore_booking_repository.dart` |
| Sessions | `firestore_session_repository.dart` |
| User profile | `firestore_user_profile_repository.dart` |
| Session policy | `firestore_session_policy_repository.dart` |

### `quran_session_market_configs`

| Operation | Query shape | Index |
|-----------|-------------|-------|
| List enabled countries | `where('isEnabled', == true).orderBy('sortOrder')` | Composite: `isEnabled` ASC, `sortOrder` ASC |
| Get country by code | `doc(countryCode).get()` | Document lookup |
| List enabled cities | Subcollection `cities`: `where('isEnabled', == true).orderBy('sortOrder')` | Composite on `cities`: `isEnabled` ASC, `sortOrder` ASC |
| Get city by id | `doc(countryCode)/cities/doc(cityId).get()` | Document lookup |

### `quran_teacher_applications`

| Operation | Query shape | Index |
|-----------|-------------|-------|
| Latest application for user | `where('userId', == uid).orderBy('updatedAt', desc).limit(1)` | Composite: `userId` ASC, `updatedAt` DESC |
| Get / create / review by id | `doc(applicationId).get()` / `set()` | Document lookup / write |

### `quran_teacher_profiles`

| Operation | Query shape | Index |
|-----------|-------------|-------|
| Profile by user id | `where('userId', == uid).limit(1)` | Single-field (automatic) |
| Profile by id | `doc(teacherId).get()` | Document lookup |
| Teacher discovery list | `where('verificationStatus', == 'verified').where('isActive', == true).orderBy('displayName').limit(20)` (+ optional `startAfterDocument`) | Composite: `verificationStatus` ASC, `isActive` ASC, `displayName` ASC |
| Pricing subdoc | `doc(teacherId)/pricing/doc(marketId).get()` | Document lookup |

Specialization and language filters run **in memory** after the paginated query
(`firestore_teacher_repository.dart`) — not in Firestore.

### `availability` (subcollection of `quran_teacher_profiles/{teacherId}`)

| Operation | Query shape | Index |
|-----------|-------------|-------|
| Slots in date range | `where('startsAt', >= from).where('startsAt', < to)` | Single-field range on `startsAt` (automatic per subcollection) |
| Publish slot | `doc(slotId).set()` | Write |
| **Withdraw slot** | **`collectionGroup('availability').get()` then filter by `doc.id` client-side** | **None — full collectionGroup scan (P0)** |

Client-side `isBooked` filtering for “available slots” happens after the range
query in `firestore_teacher_repository.dart`; no composite index required today.

### `quran_bookings`

| Operation | Query shape | Index |
|-----------|-------------|-------|
| Student booking history | `where('studentId', == uid).orderBy('createdAt', desc)` | Composite: `studentId` ASC, `createdAt` DESC |
| Create booking | Transaction: slot doc read + booking/session writes | Point reads/writes |
| Cancel booking | `doc(bookingId).get()`; sessions `where('bookingId', == id)` | Document lookup; single-field equality on `bookingId` |

**Pagination gap:** `getStudentBookings` returns all matching documents — no
`limit()` or cursor. Add pagination before scale.

### `quran_sessions`

| Operation | Query shape | Index |
|-----------|-------------|-------|
| Session by id | `doc(sessionId).get()` | Document lookup |
| Student sessions | `where('studentId', == uid).orderBy('startsAt', desc)` | Composite: `studentId` ASC, `startsAt` DESC |
| Teacher sessions | `where('teacherId', == uid).orderBy('startsAt', desc)` | Composite: `teacherId` ASC, `startsAt` DESC |
| Cancel side-effect | `where('bookingId', == bookingId)` | Single-field (automatic) |

**Pagination gap:** `getStudentSessions` and `getTeacherSessions` load full lists.

### `users`

| Operation | Query shape | Index |
|-----------|-------------|-------|
| Profile read/write | `doc(uid).get()` / `set(merge: true)` on `quranSessionsProfile` map | Document lookup / write |

No collection queries.

### `quran_session_platform_config`

| Operation | Query shape | Index |
|-----------|-------------|-------|
| Global policy | `doc('global').get()` | Document lookup |

---

## Index requirements

All composite indexes for **current** Quran Sessions queries live in
[`firestore.indexes.json`](../firestore.indexes.json). Deploy from repo root:

```sh
firebase deploy --only firestore:indexes
```

| # | Collection group | Fields | Serves |
|---|------------------|--------|--------|
| 1 | `quran_session_market_configs` | `isEnabled` ASC, `sortOrder` ASC | Enabled country list |
| 2 | `cities` | `isEnabled` ASC, `sortOrder` ASC | Enabled city list per country |
| 3 | `quran_teacher_applications` | `userId` ASC, `updatedAt` DESC | Latest application per user |
| 4 | `quran_sessions` | `studentId` ASC, `startsAt` DESC | Student session history |
| 5 | `quran_sessions` | `teacherId` ASC, `startsAt` DESC | Teacher session history |
| 6 | `quran_bookings` | `studentId` ASC, `createdAt` DESC | Student booking history |
| 7 | `quran_teacher_profiles` | `verificationStatus` ASC, `isActive` ASC, `displayName` ASC | Verified teacher discovery |

**Audit result:** these seven indexes cover every composite-indexed query in
production code. No index file changes required for the current release.

### Future-only indexes (do not deploy until query changes)

| Collection group | Fields | When needed |
|------------------|--------|-------------|
| `availability` | `isBooked` ASC, `startsAt` ASC | Only if slot listing moves `isBooked == false` into the Firestore query instead of client-side filtering |

Single-field queries (`userId` on profiles, `bookingId` on sessions, range on
`startsAt` within a teacher subcollection) use automatic indexes.

---

## Post-release monitoring checklist

Run after deploying Quran Sessions Firebase backend or index changes:

1. **Wait 1–2 hours** of real or staged traffic so Query Insights accumulates data.
2. Open **Firestore → Query Insights** (or check client logs for index errors).
3. Review **top queries by avg execution duration** — investigate anything > 500 ms
   sustained.
4. Review **top queries by billable read operations** — compare scanned docs to
   documents returned; large gaps mean over-fetching or full scans.
5. Confirm **error count = 0** for indexed queries (especially market list,
   teacher discovery, session/booking history).
6. If a query lacks an index, use the Console **Create index** link or add to
   `firestore.indexes.json` and redeploy.
7. Re-check after fixes; keep Query Insights baseline for the next release.

---

## Quran Sessions recommendations

### P0 — `withdrawSlot` collectionGroup scan

`FirestoreAvailabilityDataSource.withdrawSlot` executes
`collectionGroup('availability').get()` and filters by document id in Dart. This
reads **every availability slot across all teachers** on each withdraw — cost and
latency grow linearly with catalog size.

**Fix (code change, tracked separately):** pass `teacherId` into withdraw and
delete via the known subcollection path
(`quran_teacher_profiles/{teacherId}/availability/{slotId}`), matching how
`publishSlot` and booking transactions already address slots.

Until fixed, expect this query to dominate **billable read operations** in Query
Insights if teachers withdraw slots in production.

### Pagination gaps

These list queries have no `limit()` or cursor today:

- `getStudentBookings` — all bookings per student
- `getStudentSessions` / `getTeacherSessions` — all sessions per role
- `getTeachers` — paginated (limit 20) but specialization/language filters shrink
  the page after fetch

Add cursor-based pagination before high-volume launch; monitor read ops per user
in Query Insights to set sensible page sizes.

### No premature denormalization

Do **not** duplicate session or booking fields onto user or teacher documents to
“optimize” reads until Query Insights shows a proven hot path and pagination is
exhausted. Prefer:

- Composite indexes for filter + order patterns already in code
- Pagination and tighter date ranges (availability window)
- Targeted point reads inside existing transactions (booking flow)

Denormalization adds invalidation complexity across booking, cancel, and reschedule
flows — defer until metrics justify it.

### Client-side filtering

Teacher discovery filters specializations and languages after the Firestore query.
That is acceptable at MVP scale but wastes reads when filters are selective. If
Query Insights shows high execution count with low UI yield, consider array-contains
indexes or dedicated filter fields — only after measuring.

---

## Clean Architecture boundary

Firestore query shapes, indexes, and performance tuning belong in the **Tilawa app
data layer**:

`apps/tilawa/lib/features/quran_sessions/data/firebase/`

The `quran_sessions` package exposes **datasource interfaces** and DTOs; it must
not import `cloud_firestore` or reference collection paths. When optimizing queries:

1. Change Firestore datasources and `firestore.indexes.json` in the app repo.
2. Update this doc and
   [quran_sessions_firestore_data_model.md](quran_sessions_firestore_data_model.md).
3. Keep domain entities, use cases, and BLoCs unchanged unless the **contract**
   (e.g. pagination cursor) intentionally evolves.

See [ADR-002](adr/002-quran-sessions-backend-agnostic-architecture.md) and
[quran_sessions_backend_migration.md](quran_sessions_backend_migration.md).
