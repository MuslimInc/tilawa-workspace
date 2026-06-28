# QuranTutor — production configuration

**Product name (user-facing):** QuranTutor (EN) · تعلّم القرآن مع محفظك (AR)  
**Code / routes (legacy, stable):** package `quran_sessions`, paths `/sessions/*`

---

## App dart-defines (`TILAWA_LAUNCH_*`)

| Define | Default (`play_production`) | Staging / non-production |
|--------|----------------------------|---------------------------|
| `TILAWA_LAUNCH_QURAN_SESSIONS_ENABLED` | `true` | `true` |
| `TILAWA_LAUNCH_QURAN_SESSIONS_BOOKING_ENABLED` | `false` | `true` when `TILAWA_DISTRIBUTION != play_production` |
| `TILAWA_LAUNCH_ENABLED_CALL_PROVIDERS` | `external,mock` | `external,mock,agora` when `TILAWA_DISTRIBUTION != play_production` |
| `TILAWA_LAUNCH_AGORA_APP_ID` | empty (required for real Agora) | staging ID injected in debug/staging via `resolveRtcLaunchConfig` |
| `TILAWA_LAUNCH_WEBRTC_SIGNALING_URL` | empty | set when `webrtc` enabled |

**Production voice/video:** set Firestore `quran_session_platform_config/global.enabledCallProviders` to include `agora` (or `webrtc`), ship app with matching `TILAWA_LAUNCH_ENABLED_CALL_PROVIDERS` and `TILAWA_LAUNCH_AGORA_APP_ID`. Do **not** rely on client mock fallback when real RTC is expected — mock is only used when no RTC provider is configured.

---

## Cloud Functions / secrets

| Item | Purpose |
|------|---------|
| Firestore `enabledCallProviders` | Server authority for booking-time provider lock (`callProviderResolver.ts`) |
| Agora token minting secrets | CF Agora join credentials (not client App ID alone) |
| `QURAN_SESSIONS_ENFORCE_APP_CHECK` | Callable App Check (default off until staging verified) |

Align client `resolveRtcLaunchConfig` + `resolveVoiceVideoProviderHint` with Firestore array order: `agora` → `webrtc` → `mock`.

---

## Fake / local MVP teachers

`QuranSessionsMvpStore` seeds three Egypt teachers (`teacher_1`–`teacher_3`). `teacher_1` supports voice + video for RTC path testing; others use external meeting links.

---

## Ops / QA runbooks (canonical)

| Doc | Purpose |
|-----|---------|
| [ops_qa_runbook.md](./ops_qa_runbook.md) | Master ops/QA runbook + release blocker table |
| [firebase_config_checklist.md](./firebase_config_checklist.md) | Firestore seed, rules, indexes, CF |
| [provider_config_checklist.md](./provider_config_checklist.md) | Agora / mock / external alignment |
| [two_device_qa_script.md](./two_device_qa_script.md) | B1–B5 + T2–T8 sign-off script |
| [release_readiness_report.md](./release_readiness_report.md) | Staging/prod readiness tracker |

## Ops checklist (before wide release)

1. `TILAWA_LAUNCH_QURAN_SESSIONS_BOOKING_ENABLED=true` on target build flavor.
2. Seed verified teacher profiles + availability in Firestore (or enable fake backend only for QA).
3. Set `enabledCallProviders` in Firestore **and** matching app dart-defines.
4. Run `scripts/quran_sessions_preflight.sh` + manual two-device join ([two_device_qa_script.md](./two_device_qa_script.md)).
5. Flip App Check on staging, then production, per `docs/quran_sessions/app_check_staging_verification.md`.

---

## Legacy references (intentional)

- Firestore collections: `quran_sessions`, `quran_bookings`, …
- Package name: `quran_sessions` (alias export `QuranTutorRoutes` → `QuranSessionsRoutes`)
- Route prefix: `/sessions` (alias redirect `/quran-tutor` → home)
