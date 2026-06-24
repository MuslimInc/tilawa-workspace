# Implementation Plan — Stable Production v1

**Priority order:** security → rules → lifecycle → join → admin → notifications → UX → tests → monitoring → Play

---

## Phase 0 — Audit (complete)

- [x] Read codebase: app, package, functions, rules, admin, spec 037
- [x] Create spec 038 documentation
- [x] Classify flows and blockers honestly

---

## Phase 1 — P0 Security / safety (038 — implemented)

| # | Task | Files | Verify |
|---|------|-------|--------|
| 1.1 | Teacher CF auth uses profile `userId` | `sessionAuth.ts`, callables | `sessionAuthHelpers.test.ts` |
| 1.2 | Freeze eligibility fields in rules | `firestore.rules` | `usersModeration.rules.test.ts` |
| 1.3 | Wire `quranSessionsEnabled` kill switch | `quran_sessions_session_guard.dart`, `app_router.dart`, `home_dashboard_footer.dart` | `quran_sessions_session_guard_test.dart` |
| 1.4 | Fix teacher role in report callable | `sessionReportCallables.ts` | Integration tests |

---

## Phase 2 — Firestore rules / authz hardening (P1)

| Task | Effort |
|------|--------|
| Expand rules tests: client write denied on bookings/sessions | S |
| App Check staged rollout on session CFs | M |
| Document epoch limitation in user-facing help | S |

---

## Phase 3 — Booking / session lifecycle (mostly done)

| Task | Status |
|------|--------|
| Free booking CF + client flow | ✅ |
| Cancel / dispute / report | ✅ |
| Reschedule request (mobile) | ✅ |
| Reschedule confirm (admin) | ✅ |
| Join abstraction | ✅ |

---

## Phase 4 — Join / provider reliability

| Task | Status |
|------|--------|
| External meeting URL launcher + Android queries | ✅ |
| Mock provider server kill via Firestore config | ✅ |
| Session detail external join confirmation sheet | ✅ (git staged) |

---

## Phase 5 — Admin ops (acceptable for v1)

| Task | Priority |
|------|----------|
| Ops runbook for read-only dispute/report triage | P1 doc ✅ |
| Dispute resolve UI in admin | P1 post-v1 |
| `adminOverrideSessionCallSettings` callable | P2 |

---

## Phase 6 — Notifications

| Task | Status |
|------|--------|
| Outbox + FCM active device | ✅ |
| Teacher approval FCM → capability refresh | ✅ |

---

## Phase 7 — UX blockers (P1/P2)

| Task | Priority |
|------|----------|
| Remove experimental badge at stable launch | P2 |
| Dark mode smoke on booking + detail | P2 |
| `failure_ui` widget tests | P1 |
| Session detail copy: mode locked at booking | P2 |

---

## Phase 8 — Test coverage

| Task | Priority |
|------|----------|
| Manual B1–B5, T2–T8 | **P0 release** |
| RescheduleBloc + screen tests | P1 |
| SessionDetailBloc join/cancel | P1 |
| Maestro smoke flow | P1 |

---

## Phase 9 — Monitoring / rollback

| Task | Status |
|------|--------|
| Kill switch wired | ✅ (038) |
| Preflight script | ✅ |
| Feature Sentry tags | P1 |
| CI preflight on all PRs | P1 |

---

## Phase 10 — Google Play

| Task | Owner |
|------|-------|
| Execute internal upload runbook | Release |
| Legal privacy for meeting links | Legal |
| Complete sign-off table | QA |

---

## Execution log (038)

### Code changes

```
functions/src/quranSessions/sessionAuth.ts
functions/src/quranSessions/cancelSessionBooking.ts
functions/src/quranSessions/completeSession.ts
functions/src/quranSessions/markSessionNoShow.ts
functions/src/quranSessions/requestSessionReschedule.ts
functions/src/quranSessions/confirmSessionReschedule.ts
functions/src/quranSessions/sessionDisputeCallables.ts
functions/src/quranSessions/sessionReportCallables.ts
firestore.rules
apps/tilawa/lib/router/quran_sessions_session_guard.dart
apps/tilawa/lib/router/app_router.dart
apps/tilawa/lib/features/home/presentation/widgets/home_dashboard_footer.dart
functions/test/quranSessions/sessionAuthHelpers.test.ts
functions/test-rules/usersModeration.rules.test.ts
apps/tilawa/test/router/quran_sessions_session_guard_test.dart
packages/quran_sessions/test/presentation/blocs/session_detail_bloc_test.dart
packages/quran_sessions/test/domain/policies/session_mode_policy_test.dart
functions/test-rules/quranSessions.rules.test.ts
specs/038-quran-session-stable-production-release/*
```

### Verification commands

```sh
cd functions && npm test -- test/quranSessions/sessionAuthHelpers.test.ts
cd functions && npm run test:rules  # if JDK 21
cd apps/tilawa && dart analyze
cd apps/tilawa && flutter test test/router/quran_sessions_session_guard_test.dart
./scripts/quran_sessions_preflight.sh
```

---

## Definition of done (stable v1)

- [x] P0 code blockers fixed
- [x] Spec 038 docs complete
- [x] P1 SessionDetailBloc + rules write-denial tests
- [x] `flutter test` packages/quran_sessions — 673 pass
- [x] CF unit 121 pass; integration 38 + rules 31 pass (JDK 21)
- [x] `./scripts/quran_sessions_preflight.sh` pass
- [ ] `dart analyze` clean on touched paths (1 pre-existing warning)
- [ ] Manual sign-off B+T complete
- [ ] Legal privacy verify
- [ ] App Check rollout plan approved
