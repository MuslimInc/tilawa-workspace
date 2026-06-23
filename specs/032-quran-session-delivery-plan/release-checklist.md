# Release Checklist — Quran Sessions Free Beta

**Sprint:** 7 (staging/prod prep), Sprint 8 (Play)  
**Rollback:** [rollback-plan.md](./rollback-plan.md)

---

## Pre-release gates (all must pass)

- [ ] Sprint 0 scope freeze signed
- [ ] All P0 stories US-001–US-072 (Beta scope) dev-complete
- [ ] `flutter test packages/quran_sessions` green
- [ ] `dart analyze` clean (tilawa + quran_sessions)
- [ ] `cd functions && npm test && npm run test:integration && npm run test:rules` green
- [ ] Staging smoke 10/10 — [production-readiness-p0.md](../030-quran-sessions-domain/production-readiness-p0.md)
- [ ] Rollback drill executed — [US-072](./user-stories.md)
- [ ] Zero open P0 defects
- [ ] `docs/quran_sessions_roadmap.md` updated for shipped items

---

## Staging deploy

### Cloud Functions

```sh
cd functions && npm run build
firebase use staging   # confirm project
firebase deploy --only functions:createSessionBooking,functions:cancelSessionBooking,functions:requestSessionReschedule,functions:confirmSessionReschedule,functions:markSessionNoShow,functions:completeSession,functions:issueSessionCompensation,functions:approveSessionRefund,functions:openSessionDispute,functions:resolveSessionDispute,functions:reportSessionConcern,functions:resolveSessionReport,functions:expirePendingReservations,functions:reviewTeacherApplication
# Or full: firebase deploy --only functions
```

- [ ] Deploy completed without error
- [ ] CF version tagged in git (release tag `quran-sessions-beta-YYYYMMDD`)
- [ ] Sentry release created for functions

### Firestore rules

```sh
firebase deploy --only firestore:rules
```

- [ ] Rules deploy completed
- [ ] `npm run test:rules` passed pre-deploy

### Admin panel (if changed)

```sh
cd apps/tilawa_admin && npm run build
# Deploy per team hosting (Firebase Hosting or internal)
```

- [ ] Admin staging URL loads
- [ ] Admin test account can open sessions + reports + disputes

### Backfill (staging)

```sh
cd functions
npm run quran-sessions:backfill-booking-session-consistency -- --dry-run
npm run quran-sessions:backfill-booking-session-consistency -- --apply
npm run quran-sessions:backfill-lifecycle   # if needed
```

- [ ] Dry-run reviewed
- [ ] Apply completed; sample docs verified in console

### Staging config

- [ ] `quranSessionsEnabled: true` on staging
- [ ] `quranSessionsBookingEnabled: true` on staging
- [ ] `teacherApplicationEnabled: true` (or per plan)
- [ ] EG market `isEnabled: true`
- [ ] ≥5 verified free teachers with schedules + meeting links
- [ ] Platform default meeting URL configured if teachers lack personal link

### Staging verification

- [ ] Manual book→join on staging device
- [ ] FCM confirm + reminder on staging
- [ ] Admin dispute resolve creates manual_pending ledger

---

## Production gates

**Do not proceed until 7 days staging stable (or explicit risk acceptance).**

### Production deploy

- [ ] Change window announced to ops
- [ ] CF deploy to production (same function list as staging)
- [ ] Firestore rules deploy to production
- [ ] Admin panel prod deploy (if changed)

### Production backfill

- [ ] Dry-run on production data — ops sign-off
- [ ] Apply during low-traffic window
- [ ] Post-backfill audit: 0 ambiguous lifecycle rows (sample 50 docs)

### Production config

- [ ] `quranSessionsEnabled: true` (or staged via Remote Config)
- [ ] `quranSessionsBookingEnabled: false` initially — enable per rollout plan
- [ ] `DisabledPaymentProvider` verified — paid path returns `payment_provider_unavailable`
- [ ] Sentry production DSN active
- [ ] Alert policies configured (CF errors, crash rate)

### Feature flag rollout plan

| Step | `quranSessionsBookingEnabled` | Audience |
|------|--------------------------------|----------|
| 1 | false | Prod deploy verify read-only paths |
| 2 | true | Play internal testers only |
| 3 | true | Closed Beta list |
| 4 | true | Staged 5% → 20% → 50% → 100% |

- [ ] Remote Config keys documented
- [ ] Kill switch owner assigned

---

## Mobile app release

### Version

- [ ] Version name bumped (semver — e.g. `1.x.0-beta.1`)
- [ ] Version code incremented in `pubspec.yaml` / Android `build.gradle`
- [ ] Release notes drafted AR + EN — [google-play-release-plan.md](./google-play-release-plan.md)

### Build

```sh
cd apps/tilawa
flutter build appbundle --release
```

- [ ] AAB signed with release keystore
- [ ] ProGuard/R8 mapping uploaded to Play (if applicable)
- [ ] `quranSessionsBackendMode` = production for release flavor

### Changelog (user-facing summary)

Template:

```
## Quran Sessions (Beta)
- Book free 1-on-1 Quran sessions with verified teachers
- Manage upcoming sessions, cancel, and reschedule
- Join sessions via meeting link
- Teachers: apply, set availability, manage dashboard
```

- [ ] CHANGELOG or release notes file updated in repo (if project maintains one)
- [ ] Internal release notes with known limitations linked

---

## Post-release (first 48h)

- [ ] Monitor Sentry crash-free rate hourly
- [ ] Monitor CF error logs for `quranSessions/*`
- [ ] Check booking count vs failures
- [ ] Ops on-call for dispute/report queue
- [ ] Daily standup: metrics vs [beta-testing-plan.md](./beta-testing-plan.md) success table
- [ ] No forced rollout advance if stop condition met

---

## Sign-off

| Role | Name | Date | Staging | Prod |
|------|------|------|---------|------|
| Engineering | | | ☐ | ☐ |
| QA | | | ☐ | ☐ |
| Product | | | ☐ | ☐ |
| Ops/Admin | | | ☐ | ☐ |

---

## References

- Smoke: [production-readiness-p0.md](../030-quran-sessions-domain/production-readiness-p0.md)
- Play: [google-play-release-plan.md](./google-play-release-plan.md)
- Beta: [beta-testing-plan.md](./beta-testing-plan.md)
