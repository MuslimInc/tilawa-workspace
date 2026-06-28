# QuranTutor — Release readiness report

**Last updated:** 2026-06-26 (ops arc — staging seed fix)  
**Environment focus:** Staging QA first; no destructive production actions in this doc.

**Related:** [teacher_approval_spec.md](./teacher_approval_spec.md) (GA blocker — tutor accept/reject) · [approval_deploy_qa_checklist.md](./approval_deploy_qa_checklist.md) (CF/index/config + Part F deploy) · [ops_qa_runbook.md](./ops_qa_runbook.md) · [firebase_config_checklist.md](./firebase_config_checklist.md) · [provider_config_checklist.md](./provider_config_checklist.md) · [two_device_qa_script.md](./two_device_qa_script.md)

---

## Summary

| Gate | Staging QA | Production GA |
|------|------------|---------------|
| Can run automated preflight | ✅ Now (no Firebase creds required) | Same |
| Can browse/book after seed apply | ⬜ After ops runs apply commands | ⬜ Real teachers required |
| Manual two-device sign-off | ⬜ Pending QA | ⬜ Pending QA |
| Public booking on Play | N/A (staging on by default) | ⬜ Blocked until explicit flag + seed |

---

## Readiness table

| Area | Status | Blocker? | Environment | Required action | Owner |
|------|--------|----------|-------------|-----------------|-------|
| Staging seed script (`seedStagingTeachers.ts`) | ✅ Fixed | No | Staging | Ops runs `seed:staging-teachers:apply` | Ops |
| Firestore markets seed | ⬜ Not applied (no creds in CI agent) | **Yes** for staging QA | Staging | `npm run seed:market-configs:apply` | Ops |
| Firestore teachers + schedules | ⬜ Not applied | **Yes** for staging QA | Staging | `npm run seed:staging-teachers:apply` | Ops |
| Platform config `enabledCallProviders` | ⬜ Manual merge | **Yes** for voice/video | Staging / Prod | Merge `quran_session_platform_config/global` | Ops |
| Browse query index | ✅ In repo | Yes if missing deploy | Staging / Prod | `firebase deploy --only firestore:indexes` | Ops |
| Firestore rules | ✅ In repo | Yes if not deployed | Staging / Prod | `firebase deploy --only firestore:rules` | Ops |
| Booking dart-defines | ✅ Documented | Yes for prod GA | Prod | `TILAWA_LAUNCH_QURAN_SESSIONS_BOOKING_ENABLED=true` when ready | Release |
| Provider client + Firestore alignment | ✅ Documented | Yes for RTC | Staging / Prod | See [provider_config_checklist.md](./provider_config_checklist.md) | Ops / Eng |
| Agora secrets + `issueSessionRtcToken` | ⬜ Not verified | Yes if RTC release | Staging / Prod | Set secrets + deploy CF | Ops |
| App Check enforcement | ⬜ Off by default | Yes before prod enforce | Staging → Prod | [app_check_staging_verification.md](../quran_sessions/app_check_staging_verification.md) | Ops |
| CI `analyze-and-test` | ✅ Hard gate | Yes if red | CI | Fix on PR | Eng |
| CI `quran-sessions-preflight` | ✅ Hard gate | Yes if red | CI | `./scripts/quran_sessions_preflight.sh` | Eng |
| CI `functions-emulator-tests` | ✅ Hard gate | Yes if red | CI | `cd functions && npm test && npm run test:rules` | Eng |
| CI `melos run test` (full suite) | ⚠️ Advisory | **No** | CI | `.github/workflows/pr-checks.yml` `continue-on-error: true` | Eng |
| `teacher_dashboard_availability_sync_test` | ❌ 2/5 failing | **No** (advisory) | Local / CI | Not a QuranTutor release blocker | Eng |
| Mock / fake backend leak | ✅ Guarded | Yes if misconfigured | Prod | No `TILAWA_QURAN_SESSIONS_BACKEND=fake`; remove `mock` from prod Firestore | Release |
| Manual B1–B5 booking | ⬜ Pending | **Yes** | Staging | [two_device_qa_script.md](./two_device_qa_script.md) Part A | QA |
| Manual D1–D3 gates | ⬜ Pending | **Yes** | Staging | Part D (booking/provider/slot) | QA |
| Manual J1–J8 join lifecycle | ⬜ Pending | **Yes** | Staging | Part E + min-notice cancel MN1–MN2 ([two_device_qa_script.md](./two_device_qa_script.md) Part C2) | QA |
| Manual T2–T8 single device | ⬜ Pending | **Yes** | Staging | Part B | QA |
| Manual F1–F9 teacher approval | ⬜ Pending | **Yes** | Staging | Part F + [approval_deploy_qa_checklist.md](./approval_deploy_qa_checklist.md) | QA |
| P2 tutor reject reason sheet (mobile) | ✅ In repo | No | Staging | F4 with/without reason | Eng |
| P2 dashboard card cancel (mobile) | ✅ In repo | No | Staging | F4b overflow cancel | Eng |
| Production verified teachers | ⬜ Not seeded | **Yes** for GA | Prod | Real Auth UIDs + dashboard schedules | Ops |
| Privacy / external meeting URLs | ⬜ Pending | Yes for Play wide | Prod | Legal sign-off | Legal |
| GitHub Actions billing | ⚠️ Known | Yes if jobs skip | CI | Repo owner | Repo owner |

---

## Staging apply commands (ops)

```sh
cd functions
export GOOGLE_APPLICATION_CREDENTIALS=/path/to/service-account.json   # or ADC
export FIREBASE_PROJECT_ID=quran-playera-app                          # optional override

npm run seed:market-configs          # dry run
npm run seed:market-configs:apply

npm run seed:staging-teachers        # dry run
npm run seed:staging-teachers:apply
```

Then merge platform config (Console or Admin SDK):

```json
{
  "enabledCallProviders": ["external", "mock"],
  "childAgeThreshold": 14,
  "globalAllowMaleTeacherFemaleStudent": true,
  "globalAllowFemaleTeacherMaleStudent": true
}
```

Deploy rules/indexes if stale:

```sh
firebase deploy --only firestore:rules,firestore:indexes --project quran-playera-app
```

---

## Post-apply verification checklist

- [ ] `quran_session_market_configs/EG` + `cities/cairo` enabled
- [ ] `quran_teacher_profiles/staging_teacher_01`: `profileCompleteness: complete`, `isPubliclyVisible: true`
- [ ] `availability_config/schedule` exists with `weeklyRules.mon` / `tue` / … keys
- [ ] Staging APK: browse shows ≥1 teacher; detail shows slots
- [ ] Student profile complete before booking test
- [ ] `./scripts/quran_sessions_preflight.sh` green

---

## Production blockers (do not enable without sign-off)

1. **`TILAWA_LAUNCH_QURAN_SESSIONS_BOOKING_ENABLED=true`** on `play_production` — default is **off**.
2. **Real teachers** — do not ship `staging_teacher_*` doc IDs to production browse.
3. **Remove `mock`** from Firestore `enabledCallProviders` for wide release unless internal QA only.
4. **App Check** — do not set `QURAN_SESSIONS_ENFORCE_APP_CHECK=true` until staging smoke passes.
5. **Agora** — secrets + CF deploy required before RTC GA; staging App ID is not a prod credential.

---

## Can move to staging QA?

**After ops runs apply commands above:** Yes — build staging APK per [two_device_qa_script.md](./two_device_qa_script.md) and execute Parts A–E.

**Without Firebase credentials:** Eng can run dry-run seeds + preflight only; browse/booking QA blocked until apply.
