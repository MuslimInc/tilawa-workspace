# Production Blockers — Quran Sessions Stable v1

**Last updated:** 2026-06-24

## P0 — Must fix before stable production Go

| ID | Blocker | Status | Evidence / fix |
|----|---------|--------|----------------|
| P0-1 | CF teacher auth compares Auth uid to profile doc id | **Fixed (038)** | `sessionAuth.ts` accepts `teacherUserId`; callables resolve via `resolveTeacherProfileUserId` |
| P0-2 | Client can mutate eligibility fields (gender, DOB, location) | **Fixed (038)** | `firestore.rules` → `quranSessionsProfileEligibilityUnchanged()` |
| P0-3 | `quranSessionsEnabled` not enforced (rollback broken) | **Fixed (038)** | `quranSessionsFeatureRedirect` in router; home footer gated; `openHomeQuranSessions` no-op when off; `home_dashboard_footer_test.dart` |
| P0-4 | Manual E2E sign-off unsigned (B1–B5, T2–T8) | **Open** | [docs/qa/quran_sessions_free_beta_signoff.md](../../docs/qa/quran_sessions_free_beta_signoff.md) — all ⬜ |
| P0-5 | Teacher report role when profile id ≠ uid | **Fixed (038)** | `sessionReportCallables.ts` resolves teacher auth uid |

### Previously P0 — resolved in spec 037

| Item | Status |
|------|--------|
| Stale Settings capability after admin approve | Fixed — resume/route/FCM refresh |
| Approved teacher dashboard dead-end (`approvedInactive`) | Fixed — routing + backfill script |
| Teacher cancel/dispute notifications wrong uid | Fixed in 037 for notifications; 038 fixes authz |

---

## P1 — Harden before wide production / Play production track

| ID | Item | Status | Notes |
|----|------|--------|-------|
| P1-1 | App Check on session CFs | **Staged (Phase 4)** | Env `QURAN_SESSIONS_ENFORCE_APP_CHECK`; default off until ops enables on staging |
| P1-2 | RescheduleBloc / screen tests | Open | Domain covered; UI untested |
| P1-3 | SessionDetailBloc join/cancel/error paths | **Fixed (038)** | Join + report + dispute bloc tests |
| P1-4 | Maestro E2E (book → join) | Open | Deferred in 037 |
| P1-5 | CI wire `quran_sessions_preflight.sh` | Open | Script exists; not all workflows |
| P1-6 | Feature-scoped Sentry breadcrumbs | Open | Generic telemetry only |
| P1-7 | Legal: privacy policy for external meeting links | Open | Legal verify |
| P1-8 | Expand rules write-denial tests | **Fixed (038)** | `functions/test-rules/quranSessions.rules.test.ts` — client create/mutate denied on `quran_bookings`, `quran_sessions`, `quran_session_events` |
| P1-9 | Admin dispute resolve UI | Open | Read-only by design; session detail CF actions |
| P1-10 | Remove experimental badge at stable launch | Open | UX polish |

---

## Postponed (explicit non-blockers)

- Paid booking, wallet checkout, payouts
- Group sessions
- Agora / WebRTC SDK
- Bilateral mode/provider change (`SessionModeChangeRequest`)
- Mobile reschedule confirm UI
- Mobile teacher mark no-show
- Marketplace ranking / advanced reviews
- Cryptographic single-device (epoch secrecy)

---

## Verdict gate

| Gate | Required for **Stable Production Go** |
|------|----------------------------------------|
| All P0 code fixes | ✅ (038) except manual QA |
| B1–B5 + T2–T8 pass on staging | ❌ pending |
| `play_production` booking flag intentional | ✅ default off |
| Rollback drill (flags 1–2) | ✅ after P0-3 |
| App Check | P1 — **Conditional Go** acceptable for closed/staging |

**Current verdict:** **Conditional Go** — ship to staging / closed testers after manual QA; **No-Go** for unrestricted Play production until sign-off + App Check plan.
