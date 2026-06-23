# Sprint 035 — QA / Staging Validation + Minimal Admin Disputes Queue

**Date:** 2026-06-23  
**Sprint goal:** Prove Free Beta loop on staging; ship minimal admin disputes triage.

---

## 1. Staging environment used

| Item | Value |
|------|-------|
| Firebase project | `quran-playera-app` |
| Admin web | `apps/tilawa_admin` → `environment.ts` points to same project |
| Mobile staging | `TILAWA_DISTRIBUTION != play_production` → booking + teacher-apply flags default **on** |
| Smoke auth | Application Default Credentials (local `gcloud` / service account) |

---

## 2. Deploy commands used

**Not run this sprint** — existing staging backend already served smoke. Document for next deploy:

```sh
# From repo root
cd functions && npm run build

firebase deploy --only functions:createSessionBooking,functions:cancelSessionBooking,functions:requestSessionReschedule,functions:confirmSessionReschedule,functions:markSessionNoShow,functions:completeSession,functions:issueSessionCompensation,functions:approveSessionRefund,functions:openSessionDispute,functions:resolveSessionDispute,functions:reportSessionConcern,functions:resolveSessionReport,functions:expirePendingReservations

firebase deploy --only firestore:rules
firebase deploy --only firestore:indexes   # if composite query errors in admin
```

Canonical reference: `specs/030-quran-sessions-domain/production-readiness-p0.md`

---

## 3. Seed commands used

```sh
cd functions
npm run seed:staging-teachers              # dry-run ✅ (5 teachers)
npm run seed:staging-teachers:apply        # NOT run — requires GOOGLE_APPLICATION_CREDENTIALS + explicit apply
```

**Action for user:** Run `seed:staging-teachers:apply` before manual teacher-browse QA if `staging_teacher_01`–`05` not already in Firestore.

---

## 4. Smoke checklist results (16-step manual loop)

Manual device E2E **not executed** in this sprint (requires physical devices + test accounts). Automated backend smoke **12/12 pass** (see §12).

| # | Step | Result | Notes |
|---|------|--------|-------|
| 1 | Admin approves teacher application | ⬜ Blocked | Manual — admin login + application review |
| 2 | Approved teacher completes public profile | ⬜ Blocked | Manual device |
| 3 | Teacher sets weekly availability | ⬜ Blocked | Manual device |
| 4 | Staging flags: booking + teacher apply on | ✅ Pass | `app_launch_config.dart` + unit test |
| 5 | Student completes Quran Sessions profile | ⬜ Blocked | Manual device |
| 6 | Student browses ≥5 verified teachers | ⬜ Blocked | Seed dry-run OK; apply + manual browse pending |
| 7 | Student books free session | 🟡 Partial | CF smoke pass; mobile UI not re-verified |
| 8 | Student sees session in My Sessions | ⬜ Blocked | Manual device |
| 9 | Teacher sees session in dashboard | ⬜ Blocked | Manual device |
| 10 | Session detail shows join CTA + link | 🟡 Partial | Code shipped (batch 1–3); manual tap not run |
| 11 | Join opens external meeting URL | ⬜ Blocked | Manual device + seeded `externalMeetingUrl` |
| 12 | Report concern filed (mobile) | 🟡 Partial | CF smoke pass; mobile sheet shipped |
| 13 | Dispute opened (mobile) | 🟡 Partial | CF smoke pass; `open_dispute_sheet.dart` shipped |
| 14 | Admin triages report | 🟡 Partial | Reports queue shipped; manual admin login not run |
| 15 | Admin triages dispute | ✅ Pass (code) | **New disputes list + detail** — manual login pending |
| 16 | No paid booking exposed | ✅ Pass | Smoke #10 `payment_provider_unavailable` |

---

## 5. Screens / flows tested

| Surface | What ran |
|---------|----------|
| `functions/scripts/stagingFreeBetaSmoke.ts` | 12 automated checks against live staging |
| `apps/tilawa_admin` `ng build` | Disputes routes compile |
| `app_launch_staging_flags_test.dart` | Staging flag default |
| Mobile UI | **Not run** on device/emulator this sprint |

---

## 6. Admin disputes queue status

**Implemented** — mirrors session-reports pattern.

| Capability | Status |
|------------|--------|
| List disputes (`/quran-sessions/disputes`) | ✅ |
| Filter by status + search | ✅ |
| View dispute summary (`/quran-sessions/disputes/:id`) | ✅ |
| Status, opened-by, reason, dates | ✅ |
| Student/teacher IDs + display names (from booking + users) | ✅ |
| Link to booking (`/quran-sessions/sessions/:bookingId`) | ✅ |
| Admin notes (`resolutionReason` when resolved) | ✅ read-only |
| Resolve dispute (refund/compensation) | ❌ **Intentionally omitted** — CF `resolveSessionDispute` triggers financial ledger; Free Beta admin stays read-only |
| Sidebar nav entry | ✅ |

**Files added:** `session-disputes/`, `session-dispute-detail/`, facade, repository, mapper, entity, use cases; wired in `app.routes.ts`, `app.config.ts`, `quran-sessions.paths.ts`.

**Firestore collection:** `quran_session_disputes` — shape per `functions/src/quranSessions/disputeTypes.ts` (`disputeId`, `bookingId`, `sessionId`, `status`, `reason`, `openedByUserId`, `openedByRole`, `resolutionReason`, …).

---

## 7. Bugs found

| ID | Severity | Description |
|----|----------|-------------|
| B-035-1 | P1 | `stagingFreeBetaSmoke.ts` failed to compile — `meeting_link_required` missing from `LifecycleErrorCode` |
| B-035-2 | P2 | Teacher seed not applied in staging (`seed:apply` not run) |
| B-035-3 | P2 | Full 16-step mobile/admin manual loop unverified |

---

## 8. Bugs fixed

| ID | Fix |
|----|-----|
| B-035-1 | Added `meeting_link_required` to `functions/src/quranSessions/lifecycleErrors.ts` |

---

## 9. Bugs postponed

| Item | Rationale |
|------|-----------|
| Order 12 — `videoCallAllowedForChildren` picker | Out of sprint scope |
| Order 16 — unknown lifecycle fallback | Not staging blocker |
| Dispute resolution admin UI | Financial execution risk; defer to paid/post-beta |
| FCM booking confirm device proof (order 19) | Manual QA |
| Full manual 16-step loop | Requires user device + accounts |

---

## 10. Permission / rules issues

| Check | Status |
|-------|--------|
| `quran_session_disputes` admin read | ✅ Rules allow `isAdmin()` |
| `quran_session_reports` admin read | ✅ Per 033 audit |
| Participant write denied on disputes | ✅ CF-only writes |
| Smoke: unauthorized cancel | ✅ `not_participant` |

No new rules changes this sprint.

---

## 11. Function / log errors

| Run | Result |
|-----|--------|
| `npm run quran-sessions:staging-smoke` | **12/12 PASS** (after B-035-1 fix) |
| `npm test` (functions) | **49/49 PASS** |

---

## 12. Crash / errors (mobile / admin)

None observed in automated runs. Admin build warning only: bundle budget +72 KB (pre-existing pattern).

---

## 13. Final Free Beta readiness

| Gate | Verdict |
|------|---------|
| **Code** | **CONDITIONAL GO** — join path, report/dispute mobile, admin reports + disputes queues shipped |
| **Staging (automated)** | **GO** — smoke 12/12 |
| **Staging (manual E2E)** | **NO-GO** — 16-step loop not executed on devices |
| **Play Internal** | **NO-GO** — wait for manual E2E + seed apply |
| **Closed Beta cohort** | **CONDITIONAL** — after seed apply + one full teacher→student→admin manual pass |

---

## 14. Updated Go / No-Go recommendation

| Milestone | Verdict |
|-----------|---------|
| Backend / CF staging | **GO** (smoke 12/12) |
| Admin operability (reports + disputes read) | **GO** (code); manual login QA pending |
| Mobile book→join E2E | **NO-GO** until device QA |
| Play Internal upload | **NO-GO** |

**Smallest path forward:**
1. `npm run seed:staging-teachers:apply`
2. One manual 16-step pass (student + teacher devices + admin)
3. If green → Play Internal checklist below

---

## Rollback / feature-disable plan

| Action | Command / flag |
|--------|----------------|
| Disable student booking | `--dart-define=TILAWA_LAUNCH_QURAN_SESSIONS_BOOKING_ENABLED=false` or `TILAWA_DISTRIBUTION=play_production` |
| Disable teacher applications | `--dart-define=TILAWA_LAUNCH_TEACHER_APPLICATION_ENABLED=false` |
| Disable entire Quran Sessions module | `--dart-define=TILAWA_LAUNCH_QURAN_SESSIONS_ENABLED=false` |
| Revert CF deploy | Redeploy previous functions release from Firebase console or git tag |
| Hide admin disputes | Remove sidebar link only — data remains in Firestore |

---

## Play Internal readiness (prep only — do not upload)

| Item | Status |
|------|--------|
| Signed AAB | ⬜ Not built this sprint |
| Version code / name bump | ⬜ User to set in `pubspec.yaml` |
| Release notes draft | "Quran Sessions Free Beta: book free sessions, join via external meeting link, report concerns" |
| Internal testing checklist | 16-step table §4 |
| Rollback | § above |

---

## Verification run this sprint

```sh
cd apps/tilawa_admin && npm run build          # ✅
cd functions && npm test                       # ✅ 49/49
cd functions && npm run quran-sessions:staging-smoke  # ✅ 12/12
cd apps/tilawa && flutter test test/core/bootstrap/app_launch_staging_flags_test.dart  # ✅
```

---

## Implementation summary (for parent agent)

- **Shipped:** Minimal admin disputes queue (list + read-only detail + booking link + participant names).
- **Fixed:** `meeting_link_required` lifecycle error code (unblocked smoke script).
- **Automated smoke:** 12/12 on `quran-playera-app`.
- **Blockers for user:** Run `seed:staging-teachers:apply`; execute 16-step manual loop on devices; admin manual login to verify disputes UI against live data.
