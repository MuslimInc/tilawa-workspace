# Monitoring & Rollback Plan — Stable Production v1

Extends [032 rollback plan](../032-quran-session-delivery-plan/rollback-plan.md) and [037 experimental report](../037-quran-session-free-beta-closure/experimental-production-readiness-report.md).

## Kill switches (fastest first)

| Order | Control | Speed | Effect | Status |
|-------|---------|-------|--------|--------|
| 1 | `quranSessionsBookingEnabled=false` | ~1–5 min | Block new bookings; browse may continue | ✅ Enforced |
| 2 | `quranSessionsEnabled=false` | ~1–5 min | Hide home entry; redirect `/sessions/*` → home | ✅ Enforced (038) |
| 3 | `teacherApplicationEnabled=false` | ~5 min | Stop new teacher apply | ✅ Enforced |
| 4 | Firestore `enabledCallProviders` remove `mock` | ~5 min | Server rejects mock voice/video | ✅ |
| 5 | Play staged rollout halt | Immediate | Stop new installs | Ops |
| 6 | CF IAM / disable functions | ~15 min | All mutations fail | Extreme |
| 7 | `QURAN_SESSIONS_ENFORCE_APP_CHECK=false` + redeploy | ~15 min | Session CFs accept clients without App Check token | Ops |

### App Check staged rollout (P1)

Env gate: `QURAN_SESSIONS_ENFORCE_APP_CHECK=true` on Cloud Functions runtime env, then redeploy stable-scope session callables. Default **off** — no client impact until ops enables.

```sh
# Set runtime env on staging project (Console → Functions → env, or gcloud functions deploy --set-env-vars)
# QURAN_SESSIONS_ENFORCE_APP_CHECK=true

firebase deploy --only functions:createSessionBooking,functions:cancelSessionBooking,functions:requestSessionReschedule,functions:confirmSessionReschedule,functions:completeSession,functions:markSessionNoShow,functions:openSessionDispute,functions:resolveSessionDispute,functions:reportSessionConcern,functions:resolveSessionReport,functions:issueSessionRtcToken,functions:registerActiveDevice
```

Rollback: unset env or set `QURAN_SESSIONS_ENFORCE_APP_CHECK=false`, redeploy same function set.

### Dart-defines (production build)

```
TILAWA_LAUNCH_QURAN_SESSIONS_ENABLED=false
TILAWA_LAUNCH_QURAN_SESSIONS_BOOKING_ENABLED=false
TILAWA_LAUNCH_TEACHER_APPLICATION_ENABLED=false
TILAWA_DISTRIBUTION=play_production
```

Source: `apps/tilawa/lib/core/bootstrap/app_launch_config.dart`

## Observability

| Signal | Location | Quran-specific? |
|--------|----------|-----------------|
| App crashes | Firebase Crashlytics (global) | No tags |
| App errors | Sentry (global) | No breadcrumbs |
| Session audit | `quran_session_events` | ✅ |
| Teacher/student metrics | `metricsAggregationService` | ✅ |
| CF logs | Cloud Logging | ✅ |
| Notification outbox | `quran_session_notifications` | ✅ (admin SDK only) |

### P1 improvements

- Sentry breadcrumb on booking/join CF failure (app layer)
- Dashboard alert on booking CF error rate spike
- Weekly audit of `quran_session_reports` queue depth

## Rollback drill (15 min target)

1. Set `quranSessionsBookingEnabled=false` → verify book CTA blocked
2. Set `quranSessionsEnabled=false` → verify footer hidden + `/sessions` redirects home
3. Restore flags → verify entry returns
4. Document owner + comms template for user-facing incident

## Incident playbooks

### Booking CF regression
1. Disable booking flag (layer 1)
2. Check Cloud Functions logs + recent deploy
3. Roll back CF to previous tag if needed
4. Existing sessions remain readable; cancel via admin if broken

### Security / rules incident
1. Disable booking + sessions feature flags (layers 1–2)
2. Do **not** deploy permissive rules — revert rules from git tag
3. Audit affected bookings in Firestore

### External meeting link abuse
1. Remove compromised teacher `externalMeetingUrl` via admin
2. Cancel affected sessions
3. Suspend user via admin moderation

## Monitoring status (2026-06-24)

| Item | Status |
|------|--------|
| Feature flag rollback path | ✅ After 038 |
| Feature-scoped crash dashboards | ❌ P1 |
| Automated preflight script | ✅ |
| CI preflight on all PRs | ⚠️ Partial (emulator job exists) |
| On-call runbook linked in sign-off | ✅ docs/qa |
