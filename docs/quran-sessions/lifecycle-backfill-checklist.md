# Quran Sessions — Lifecycle Backfill Checklist

**Last updated:** 2026-07-03  
**Scope:** Migrate legacy `status` → `lifecycleStatus` before dropping dual-write.

---

## 1. Pre-flight

- [ ] Deploy Cloud Functions that dual-write `lifecycleStatus` + legacy `status`.
- [ ] Confirm Flutter mappers and list classifiers prefer `lifecycleStatus` when present.
- [ ] Take Firestore export backup (production project).
- [ ] Announce read-only window if running during low traffic (optional).

---

## 2. Backfill commands

Run from `functions/` with production credentials:

### Step A — populate `lifecycleStatus` from legacy `status`

```sh
# Dry run (counts only — script skips docs that already have lifecycleStatus)
npm run quran-sessions:backfill-lifecycle

# Apply
npm run quran-sessions:backfill-lifecycle -- --apply
```

Script: `functions/scripts/backfillLifecycleStatus.ts`

### Step B — align session docs with booking lifecycle

```sh
# Dry run
npm run quran-sessions:backfill-booking-session-consistency

# Apply
npm run quran-sessions:backfill-booking-session-consistency -- --apply
```

Script: `functions/scripts/backfillBookingSessionConsistency.ts`

---

## 3. Verification

- [ ] Sample 20 bookings: `lifecycleStatus` present and matches expected terminal states.
- [ ] Sample linked sessions: `lifecycleStatus` equals parent booking.
- [ ] Teacher/student dashboards show correct Upcoming vs History after refresh.
- [ ] No queries still filter on legacy `status` only (grep repo for `.where("status"`).
- [ ] `allowedActionsStudent` / `allowedActionsTeacher` present on active bookings.

---

## 4. Dual-write period

During migration:

- CF continues writing both `lifecycleStatus` and `status` via `legacyStatusForLifecycle`.
- Clients read `effectiveLifecycleStatus` (prefer `lifecycleStatus`).
- Do **not** drop legacy `status` until verification passes in staging and production.

---

## 5. Production safety before dropping legacy `status`

- [ ] 100% of `quran_bookings` have non-null `lifecycleStatus`.
- [ ] 100% of active `quran_sessions` have non-null `lifecycleStatus`.
- [ ] Monitoring: zero booking creation errors for 7 days.
- [ ] Rollback plan documented (re-enable dual-write reads from legacy field).
- [ ] Remove legacy `status` writes in CF only after one release with read-only legacy field.

---

## 6. Rollback

If bad data detected after apply:

1. Stop further backfill scripts.
2. Restore from Firestore export if corruption is widespread.
3. For partial issues, fix individual docs from audit events in `quran_session_events`.

---

## 7. Launch gate verification (2026-07-03)

- [x] Code review: mappers use `resolveLifecycleStatusRawFromFirestore` (prefers `lifecycleStatus` when set).
- [x] Live scan `quran-playera-app`: `backfillLifecycleStatus` → `bookings=0, sessions=0` (no docs missing `lifecycleStatus`).
- [x] Dry-run `backfillBookingSessionConsistency` → `0 session(s) would be updated`.
- [ ] Firestore export backup — not run (ops).
- [ ] **Caveat:** `backfillLifecycleStatus.ts` auto-commits when counts > 0; no `--dry-run` flag. Use counts-only interpretation when output is `0`.

