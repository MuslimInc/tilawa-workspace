# Tilawa Admin — List Sort & Pagination Spec

> Cost-first: every browse list uses **server `orderBy` + cursor pagination**.
> Client sort only on bounded detail sub-lists. No unbounded streams or load-all.

**Defaults:** page size **25** (call events **20**), cursor = last doc id, sort change resets cursor to page 1.

---

## Browse lists

### `/users`

| Field | Value |
|-------|-------|
| Collection | `users` |
| Default sort | `createdAt` desc |
| Supported sort | `createdAt`, `displayName`, `email` |
| Server filters | none (full-text search N/A in Firestore) |
| Indexes | `createdAt` DESC; `displayName` ASC/DESC; `email` ASC/DESC |
| Cursor | document id |
| Realtime | **no** — paginated `getDocs` (migrated off `collectionData`) |
| Reads / page | **26** docs (+1 cursor `getDoc` when paginating) |
| Edge cases | `createdAt` stored as ISO string; lexicographic order matches chronological. Users without `createdAt` may sort last. Select-all applies to **current page only**. `collectionCount` on dashboard unchanged (1 aggregation read). |

---

### `/quran-sessions/teacher-applications`

| Field | Value |
|-------|-------|
| Collection | `quran_teacher_applications` |
| Default sort | `updatedAt` desc |
| Supported sort | `updatedAt`, `submittedAt`, `createdAt` |
| Server filters | `status`, `submittedAt` range, `specializations` array-contains, **`countryCode` / `cityId` via bounded `users` lookup → `userId in`** |
| Client filters | `search` (display names, email, userId, phone) on current page |
| Indexes | `status`+`updatedAt`; `userId`+`updatedAt`; `status`+`userId`+`updatedAt`; `users` geo composites for applicant lookup |
| Cursor | document id |
| Realtime | no |
| Reads / page | **26** + N user lookups for display (bounded to page) |
| Edge cases | Geo filters use **exact** `quranSessionsProfile.countryCode` / `cityId` (e.g. `EG`, `cairo`), not country/city display names. Applicant lookup capped at **30** user ids (`in` query limit) — if more users match geo, results are incomplete until applicant geo is denormalized onto application docs. Search remains client on page. |

---

### `/quran-sessions/teachers`

| Field | Value |
|-------|-------|
| Collection | `quran_teacher_profiles` |
| Default sort | `updatedAt` desc |
| Supported sort | `updatedAt`, `createdAt`, `displayName` |
| Server filters | `isActive`, `verificationStatus`, `teachingLanguages`, `specializations` |
| Client filters | `search` (displayName, userId) |
| Indexes | `verificationStatus`+`isActive`+`updatedAt`; filter combos per Firestore rules |
| Cursor | document id |
| Realtime | no |
| Reads / page | **26** |
| Edge cases | Search on current page only. |

---

### `/quran-sessions/users` ⚠️ fixed

| Field | Value |
|-------|-------|
| Collection | `users` (QS slice via `quranSessionsProfile.*`) |
| Default sort | `quranSessionsProfile.updatedAt` desc |
| Supported sort | `quranSessionsProfile.updatedAt`, `quranSessionsProfile.createdAt` |
| Server filters | `quranSessionsProfile.accountStatus`, `gender`, `countryCode`, `cityId`, `profileCompleted` |
| Client filters | `search` (displayName, email, userId) on returned page |
| Indexes | see `firestore.indexes.json` — `users` collection composites |
| Cursor | document id |
| Realtime | no |
| Reads / page | **26** (was up to **50** scan with sparse client filter) |
| Edge cases | `orderBy` on nested `updatedAt` excludes users without QS profile (intended). Search cannot be server-side without Algolia. |

---

### `/quran-sessions/sessions`

| Field | Value |
|-------|-------|
| Collection | `quran_bookings` |
| Default sort | `startsAt` desc |
| Supported sort | `startsAt`, `createdAt`, `updatedAt` |
| Server filters | `lifecycleStatus`, `countryCode`, `cityId`, `startsAt` range, **`teacherId`**, **`studentId`** |
| Client filters | `search` (ids, slotId) |
| Indexes | `teacherId`+`startsAt`; `studentId`+`startsAt`; existing status/geo composites |
| Cursor | document id |
| Realtime | no |
| Reads / page | **26** |
| Edge cases | teacherId + studentId + status may need triple composite — if missing, prefer teacherId OR studentId server filter, not both. Search remains client on page. |

---

### `/quran-sessions/reports`

| Field | Value |
|-------|-------|
| Collection | `quran_session_reports` |
| Default sort | `createdAt` desc |
| Supported sort | `createdAt`, `updatedAt` |
| Server filters | `status`, `severity`, `category` |
| Client filters | `search` |
| Indexes | per filter + `createdAt` |
| Cursor | document id |
| Realtime | no |
| Reads / page | **26** |

---

### `/quran-sessions/disputes`

| Field | Value |
|-------|-------|
| Collection | `quran_session_disputes` |
| Default sort | `createdAt` desc |
| Supported sort | `createdAt`, `updatedAt` |
| Server filters | `status` |
| Client filters | `search` |
| Indexes | `status` + `createdAt` |
| Cursor | document id |
| Realtime | no |
| Reads / page | **26** |

---

## Detail sub-lists

### Session detail — timeline

| Field | Value |
|-------|-------|
| Path | `quran_session_events` where `aggregateId ==` |
| Sort | `timestamp` asc (server) |
| Pagination | none — bounded per session aggregate |
| Client sort | no |

### Session detail — compensations

| Field | Value |
|-------|-------|
| Path | `quran_session_compensations` where `bookingId ==` |
| Sort | `createdAt` desc (server `orderBy`) |
| Pagination | none — typically &lt; 20 per booking |
| Client sort | removed — server order |

### Session detail — call events

| Field | Value |
|-------|-------|
| Path | `quran_sessions/{id}/call_events` |
| Default sort | `recordedAt` desc |
| Page size | **20** |
| Pagination | cursor, lazy load |
| Realtime | no |

### Wallet transactions (`/quran-sessions/wallets/:userId`)

| Field | Value |
|-------|-------|
| Path | `wallet_transactions` where `userId ==` |
| Default sort | `createdAt` desc |
| Page size | **25** |
| Pagination | cursor |
| Index | `userId` + `createdAt` (exists) |

---

## Stubs (document only)

| Route | Notes |
|-------|-------|
| `/dashboard` | `collectionCount(users)` — 1 aggregation read; no list |
| `/reciters` | not implemented |
| `/surahs` | not implemented |

---

## Global rules

1. Sort change → `cursor = null`, replace list (no append).
2. `limit(pageSize + 1)` to detect `hasMore` without count query.
3. No `collectionData` on browse lists.
4. Search text → client filter on current server page only; see **Text search** below.
5. New indexes added to repo-root `firestore.indexes.json`.

---

## Firestore indexes (`firestore.indexes.json`)

Deploy: `firebase deploy --only firestore:indexes --project quran-playera-app`

**2026-06-24 parity check:** deploy without `--force` reported 2 remote-only indexes. They are **production** indexes (not orphan `users` single-field leftovers):

| Collection | Fields | Consumer |
|------------|--------|----------|
| `quran_session_events` | `sessionId` ASC, `timestamp` ASC | Tilawa app audit timeline (`listBySessionId` queries `sessionId`) |
| `quran_teacher_profiles` | `isPubliclyVisible` ASC, `profileCompleteness` ASC, `displayName` ASC | Tilawa teacher browse (legacy field order on remote) |

Both field-order variants are in the local file (legacy remote order + query-correct order for Flutter marketplace). **`--force` was not run** — orphans were production indexes, not stale `users` single-field leftovers. Parity achieved by adding them locally (second deploy: no orphan warning).

Admin browse composites (users QS slice, bookings geo, teacher applications `status`+`userId`+`updatedAt`, etc.) are in the same file.

---

## Text search (client-side limits)

Firestore has no full-text / substring search. Admin `search` inputs filter **only the current server page** (25 rows) after fetch. Sort and non-text filters remain server-side.

| Route | Search matches (current page) | Cheapest server path |
|-------|------------------------------|----------------------|
| `/users` | `displayName`, `email`, `id` | Prefix `orderBy`+`startAt`/`endAt` per field (3 indexes each); or Algolia/Typesense extension |
| `/quran-sessions/teacher-applications` | display names, email, `userId`, phone | Denormalize searchable fields on application doc + prefix indexes; or Algolia |
| `/quran-sessions/teachers` | `displayName`, `userId` | Prefix on `displayName` (index exists for sort) |
| `/quran-sessions/users` | `displayName`, `email`, `userId` | Same as `/users` on nested profile fields |
| `/quran-sessions/sessions` | ids, `slotId` | Prefix on `teacherId`/`studentId` when search is id-shaped |
| `/quran-sessions/reports` | reporter/session ids | Prefix on id fields |
| `/quran-sessions/disputes` | session/booking ids | Prefix on id fields |

**Recommendation:** keep client page search for MVP admin volume; add Algolia only if operators need cross-page search. Prefix queries help exact-startswith id lookup only.

