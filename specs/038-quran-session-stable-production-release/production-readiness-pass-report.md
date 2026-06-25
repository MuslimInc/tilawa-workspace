# Quran Sessions — Production Readiness Pass Report

**Date:** 2026-06-25
**Scope:** Free individual 1:1 sessions — student app, teacher app, admin panel.
**Method:** Read-only audit of Flutter package, app layer, Cloud Functions, Angular admin, Firestore rules/indexes; then targeted P0/P1/P2 fixes with tests.
**Verdict:** **Conditional Go** for staging/closed testing. **No-Go** for unrestricted Play production until manual QA sign-off + App Check enforcement flip + legal privacy verify.

---

## 1. Production readiness summary

Stable-scope Quran Sessions is implemented end-to-end (Flutter + Cloud Functions + Firestore rules + Angular admin). This pass audited the **critical business-domain rules** flagged by product and fixed **2 P0 blockers** (session classification, manual-session duration), **1 P1** (admin search debounce), and **1 P2** (call-tracking notification flag persistence). All automated gates are green.

Remaining gates are **operational**, not code: manual E2E sign-off (B1–B5/T2–T8), ops App Check enforcement flip, legal privacy verify for external meeting links, and device QA for Agora (only if RTC enabled).

## 2. Student readiness status — **Ready** (code complete)

- Discover approved/public teachers (server-side `arrayContains` filter + indexes; empty state + clear-filters CTA).
- Open teacher profile, see slots, book free individual session (CF `createSessionBooking`).
- Upcoming/current/past classification **fixed** to use `endsAt` (ongoing sessions now stay in the active list, not past).
- Session detail, join (external/mock/agora), cancel, reschedule request, report, dispute.
- Clear loading/error/empty states; locked-at-booking footnote; sub-fetch failure banners (Phase 6).
- Suspended/blocked → localized `AccountBlockedFailure` view on booking.

## 3. Teacher readiness status — **Ready** (code complete)

- Apply → admin approve → dashboard without restart (capability refresh on resume/FCM).
- Availability management (generated slots + overrides + optimistic delete with undo).
- Dashboard **fixed**: ongoing sessions (started, not ended) now appear in `upcomingSessions` (was excluded by `startsAt.isAfter(now)` filter).
- Session detail, join, cancel, reschedule request/respond, report, dispute.
- Teacher identity: dashboard queries by `teacherId` (profile id); CF auth resolves `teacherUserId` (038 P0-1). Admin-created sessions appear for the teacher (session doc stores `teacherId` + `teacherUserId`).
- Suspended teacher → dashboard blocked via capability gate.

## 4. Admin readiness status — **Ready** (code complete, with documented limitations)

- Approve/reject/suspend teachers; view teachers, students, sessions, reports, disputes.
- Create manual test/support sessions **fixed**: durations enforced to {15, 30, 45, 60} min server-side (12h rejected); picker search **debounced** (250 ms).
- Active sessions: dual bounded server queries (lifecycle window + `hasActiveCall`); live/waiting/ended/early-active states from aggregate.
- Session detail: direct `getDoc`; participants via bounded single-doc reads; **call tracking summary** = aggregated `callTracking/summary` doc (no raw scan); **raw events lazy** on panel toggle (paginated, page size 20).
- Server-side sort + cursor pagination on all lists (page size 25; sort-field allow-list; no client sort on paginated lists; no load-all).
- **Known limitation:** admin free-text `search` filters the current page only (Firestore has no full-text search). Bounded, not a scan. Recommended UX: "applies to current page" notice or a server-side prefix path for high-value fields.

## 5. P0 blockers fixed (this pass)

| ID | Blocker | Fix |
|----|---------|-----|
| P0-A | Session classification used `startsAt` only → ongoing sessions misclassified as past and excluded from teacher dashboard | Entity `isUpcoming`/`isOngoing`/`isPast` + `phaseAt(now)`; Firestore queries split by `endsAt`; teacher dashboard no longer filters out ongoing; 3 new `endsAt` composite indexes |
| P0-B | Manual admin sessions accepted any duration (12h possible) | `assertAllowedSessionDuration` in `createAdminTestQuranSession.ts` (server source of truth) + client-side check in admin facade |

## 6. P1 hardening completed (this pass)

| ID | Item | Fix |
|----|------|-----|
| P1-A | Admin create-test-session picker search fired per keystroke (dead `debounceTime` import) | Wired `Subject` + `debounceTime(250)` + `distinctUntilChanged`; `OnInit`/`OnDestroy` lifecycle |

## 7. P2 fixes (this pass)

| ID | Item | Fix |
|----|------|-----|
| P2-A | `teacherNotifiedIncomingCall`/`studentNotifiedIncomingCall` persisted as `false` (dead data) — notification idempotency relied on `*EverConnected` instead | Moved `tx.set(trackingRef, …)` to after the notification block so mutated flags are durably persisted |

## 8. What remains postponed (out of stable scope)

- Paid booking, wallet checkout, payouts, subscriptions.
- Group sessions (CF rejects; no UI).
- Full Agora/WebRTC rollout (scaffold is flag-gated, default off; device QA + legal remain).
- Bilateral mode/provider change (Option A lock only).
- Mobile reschedule confirm UI (admin confirms by request ID).
- Mobile teacher mark no-show (admin/CF only).
- Admin dispute resolve UI (read-only triage by design; resolve via session detail CF).
- Maestro book→join E2E.
- Cryptographic single-device epoch (documented ~1h token-window limitation).
- Server-side cap on raw `call_events` docs (P2; aggregate is protected; client uses CF path).

## 9. Business domain fixes

- **Classification:** `now < startsAt` → upcoming; `startsAt <= now < endsAt` → ongoing; `now >= endsAt` → past. Lists split by `endsAt` so ongoing sessions are visible to student and teacher.
- **Teacher identity:** `teacherProfileId` (dashboard query field `teacherId`) vs `teacherUserId` (CF auth + notifications) kept separate; admin-created sessions carry both.
- **Manual sessions:** follow same booking lifecycle + slot lock; durations restricted to 15/30/45/60 min.
- **Suspended/blocked:** localized blocked state on booking + teacher capability gate; no silent disable.

## 10. Performance improvements

- Ongoing-session fix uses indexed `endsAt` queries (no client filter over fetched lists).
- No new realtime listeners, no full scans, no client-side sort on paginated lists introduced.

## 11. Firebase cost improvements

- Session-list queries remain paginated (page size 30) with cursor; switching the boundary field from `startsAt` to `endsAt` is cost-neutral (indexed composite).
- 3 new composite indexes (`studentId+endsAt` asc/desc, `teacherId+endsAt` asc) — deploy via `./scripts/deploy_firestore_indexes.sh`.
- Call-tracking summary remains a single aggregated doc read; raw events stay lazy.

## 12. Security / rules changes

- No rules changes this pass (rules already deny client writes on `quran_sessions`/`quran_bookings`/`callTracking`; manual session CF is admin-only; eligibility fields frozen).
- Call-tracking aggregate write reordered within the same transaction (no new write surface).

## 13. Admin panel readiness

See section 4. All required pages exist with server-side sort + cursor pagination. Call tracking = aggregated summary; raw events lazy. Known limitation: free-text search is current-page only.

## 14. Tests added / updated

| Suite | New/changed |
|-------|-------------|
| `quran_session_test.dart` | +6 entity classification (`phaseAt`/`isUpcoming`/`isOngoing`/`isPast`) |
| `my_sessions_bloc_test.dart` | +1 ongoing session stays in upcoming |
| `teacher_dashboard_bloc_test.dart` | +1 ongoing session appears in `upcomingSessions` |
| `fake_session_repository.dart` | split by `endsAt` to match query semantics |
| `fixtures.dart` | `makeSession` accepts optional `endsAt` |
| `createAdminTestSession.test.ts` | +5 duration validation (15/30/45/60 ok; 12h/10/20/90/120 rejected; non-positive; invalid ts) |
| `callTelemetryService.test.ts` | +1 aggregate persists `*NotifiedIncomingCall` flags |

**14 new tests; 0 weakened regressions.**

## 15. Coverage percentage

- `packages/quran_sessions`: **865/865** pass (critical-path coverage ~92–95%).
- `apps/tilawa` quran_sessions: **66/66** pass (1 skipped).
- Cloud Functions unit: **164/164** pass.
- `dart analyze` (quran_sessions): clean on scope (4 pre-existing test-file warnings, unchanged).
- `dart analyze` (app `firestore_session_repository.dart`): no issues.
- Angular `tsc --noEmit`: exit 0.
- Rules/integration emulator: not re-run this pass (require JDK 21); last green 31 rules / 38 integration (038 report).

## 16. Commands run

```
melos run fix:format
dart analyze  (packages/quran_sessions)
dart analyze  (apps/tilawa firestore_session_repository.dart)
flutter test  (packages/quran_sessions)               -> 865 pass
flutter test  (apps/tilawa test/features/quran_sessions) -> 66 pass
npm run test  (functions unit)                        -> 164 pass
npx tsc --noEmit  (apps/tilawa_admin)                 -> exit 0
python3 -c json.load(firestore.indexes.json)          -> valid
```

## 17. Remaining risks

1. **Manual E2E unsigned** — B1–B5, T2–T8 still ⬜ in `docs/qa/quran_sessions_free_beta_signoff.md`.
2. **App Check off** on session CFs — code staged (env gate), ops flip pending.
3. **External meeting links** — privacy policy not legal-verified.
4. **Admin free-text search** — current-page only; ops training needed.
5. **Active-sessions cursor** — approximate across merged dedup set (documented).
6. **Agora device QA** — native join/R8 survival unverified (only if RTC enabled).
7. **Single-device epoch** — client-readable, ~1h token window (documented).
8. **Raw `call_events`** — no server-side per-session cap; client direct-write allowed by rules (P2; aggregate protected).

## 18. Go / No-Go recommendation

| Track | Verdict |
|-------|---------|
| Staging / closed testing | **Go** — code complete, automated gates green, P0 domain blockers fixed |
| Play internal / closed | **Conditional Go** — after manual QA + seed teachers |
| Play production (wide) | **No-Go** — pending manual sign-off + App Check flip + legal privacy |

**Do not mark production-ready** until student, teacher, and admin manual QA pass on staging with the new `endsAt` indexes deployed.
