# Google Play Release Checklist — Quran Sessions Stable v1

Reference: [docs/release/quran_sessions_play_internal.md](../../docs/release/quran_sessions_play_internal.md)

## Binary & permissions

| Item | Status | Notes |
|------|--------|-------|
| No Agora/WebRTC SDK | ✅ | No mic/camera permission regression from RTC |
| External URL queries (Android 11+) | ✅ | `AndroidManifest.xml` https/http VIEW queries |
| App size impact minimal | ✅ | External + mock only |
| ProGuard/R8 rules for Firebase | ✅ | Standard Flutter Firebase setup |

## Feature flags for Play tracks

| Track | Recommended flags |
|-------|-------------------|
| Internal / closed | `TILAWA_DISTRIBUTION=play_internal` → booking default **on** |
| Production | `play_production` → booking default **off** until ops enable |
| Kill switch build | `TILAWA_LAUNCH_QURAN_SESSIONS_ENABLED=false` |

## Store listing & policy

| Item | Status |
|------|--------|
| Feature described accurately (1:1 Quran sessions, external meetings) | ⬜ Content review |
| No promise of in-app video calls if only external links | ⬜ |
| Privacy policy covers third-party meeting URLs (Meet, etc.) | ⬜ Legal |
| Data safety form: user profile, bookings, FCM | ⬜ |
| Teacher-generated content (bio, meeting links) | ⬜ Disclose moderation |

## Pre-upload engineering

| Item | Command / artifact |
|------|-------------------|
| Preflight green | `./scripts/quran_sessions_preflight.sh` |
| Staging `google-services.json` for tester builds | Release owner |
| Manual B1–B5 on staging APK/AAB | Sign-off table |
| Two-device T2–T8 | Sign-off table |
| Rollback owner assigned | Sign-off doc |

## Post-upload smoke (15 min)

1. Install from track; confirm staging Firebase
2. Complete profile → browse teachers
3. Book external session (if booking enabled)
4. Open meeting link on device
5. Toggle kill switch build → entry hidden

## Production rollout recommendation

1. **Internal** → booking on, mock optional, full B+T sign-off
2. **Closed** → limited cohort, monitor reports queue + Crashlytics
3. **Production** → start with `quranSessionsBookingEnabled=false`; enable booking via rebuild when supply + support ready

## Readiness verdict

| Checklist section | Ready? |
|-------------------|--------|
| Engineering / binary | ✅ |
| Feature flags | ✅ |
| Automated tests | ✅ (preflight) |
| Manual QA | ❌ pending |
| Legal / store copy | ❌ pending |

**Play internal upload prep:** ✅  
**Play production wide release:** ❌ until manual QA + legal
