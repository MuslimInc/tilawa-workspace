# Teacher profile & users migration notes

One-time Firestore data fixes for legacy Quran Sessions teacher profiles and
user document hygiene. **Run dry-run first**; scripts never auto-merge users.

## New schema fields

### `quran_teacher_applications/{applicationId}`

| Field | Type | Notes |
|-------|------|-------|
| `publicDisplayName` | string? | Intended public marketplace name (never from bio) |
| `teacherDisplayName` | string? | Teacher-preferred label; may differ from `publicDisplayName` |

Legacy `displayName` on applications is read as a fallback in admin mappers only.

### `quran_teacher_profiles/{teacherId}`

| Field | Type | Notes |
|-------|------|-------|
| `profileCompleteness` | `"complete"` \| `"incomplete"` | Persisted gate for required public fields |
| `isPubliclyVisible` | boolean | Eligible for public teacher discovery queries |

Placeholder display names (`Quran Teacher`, `محفظ قرآن`) count as incomplete.

## Scripts

From `functions/` with Admin SDK credentials (`GOOGLE_APPLICATION_CREDENTIALS` or
ADC). Optional `FIREBASE_PROJECT_ID` (default `quran-playera-app`).

### 1. Teacher profile backfill

```sh
npm run admin:backfill-teacher-profiles          # dry-run report
npm run admin:backfill-teacher-profiles -- --apply
```

**Targets:** profiles with placeholder/empty `displayName`, missing `userId`, or
missing `publicBio`, or missing new visibility fields.

**Resolution order for `displayName`:**

1. `quran_teacher_applications/{profileId}.publicDisplayName`
2. `users/{userId}.displayName` (temporary migration only)
3. Mark `profileCompleteness: incomplete` — **never** derive from bio

**Report JSON:** `scanned`, `fixed`, `incomplete`, `manualReview`, `skipped`.

### 2. Duplicate users audit (read-only)

```sh
npm run admin:audit-duplicate-users
```

**Reports:**

- Users grouped by normalized email with multiple doc IDs
- `doc.id` ≠ stored `uid` / `userId` field when present

No merge or delete — manual ops only.

## Index deploy

Public teacher list query (after app query update):

```
verificationStatus == verified
  AND isActive == true
  AND profileCompleteness == complete
  AND isPubliclyVisible == true
```

Deploy from repo root:

```sh
firebase deploy --only firestore:indexes
```

Index #8 in [`firestore.indexes.json`](../../firestore.indexes.json). Legacy
`displayName` sort index kept until all clients migrate.

## Risks

- **User displayName fallback** is migration-only; teachers should confirm public
  name via profile completion flow.
- **Backfill without `--apply`** is safe; with `--apply`, review dry-run counts
  first especially `manualReview`.
- **Duplicate users** need human merge policy — script is audit-only.
- **Index + query mismatch** until Flutter teacher list query adds new filters
  (Agent 4). Old query still uses legacy index.

See also [`firestore_collections.md`](firestore_collections.md),
[`quran_sessions_firestore_data_model.md`](../quran_sessions_firestore_data_model.md).
