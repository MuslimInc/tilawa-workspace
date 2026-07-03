# Quran Sessions — Staging Post-Apply Verification

**Date:** 2026-07-03  
**Second pass:** 2026-07-03 (after `npm run seed:platform-config:apply`)  
**Firebase project:** `quran-playera-app`  
**Rollout scope:** Free / video-only limited rollout (EG pilot) — verification only  
**Executor:** Automated post-apply QA pass (CI-local + live Firestore read)

---

## Executive sign-off

| Verdict | **STAGING VERIFIED** (automated + live config) — **Device QA PARTIAL** (2026-07-03) — **NOT READY for App Check soak** |
|---------|------------------------------------------------------------------------------------------------------------------------|

**Why:** Platform seed apply succeeded on live staging. `validatePlatformConfig` and market validators pass on Firestore reads. Cloud Functions unit/integration and targeted Flutter tests pass. Backfill dry-run reports 0 inconsistent sessions. **Device QA (2026-07-03)** ran on Android emulator `emulator-5554` with staging dart-defines; teacher dashboard reachable; **student hub booking path blocked** (missing student feature flag on device + no student test account); **external meeting link exposed** on teacher dashboard (check #10 fail). App Check soak should wait until student D1–D8 pass on a correctly flagged staging build.

**Prior pass (first):** Platform doc drift blocked booking-shaped validation until seed apply — **resolved** in second pass.

---

## Summary table (12 verification items)

| # | Item | Status | Notes |
|---|------|--------|-------|
| 1 | Platform config exists + validates | **PASS** (live + seed + unit) | `sessionMode: videoOnly`, `quranTutorBookingMode: requiresTutorApproval`, providers `mock` + `agora` only |
| 2 | Market config EG (+ pilots SA, AE) | **PASS** | Docs exist; EG/SA/AE `validateMarketConfigForBooking` valid (cairo / riyadh / dubai) |
| 3 | Fail-closed without config | **PASS** | Unit + integration; live platform now valid — bookings not blocked by `policy_not_configured` |
| 4 | Video-only policy | **PASS** (live + code/tests) | Live `sessionMode: videoOnly`; CF rejects non-video when mode set; Flutter `SessionModePolicy` aligned |
| 5 | Out of scope confirmed | **PASS** | Documented; paid/wallet/reschedule/admin UI not in gate |
| 6 | Teacher whitelist / market rollout | **PASS** (tests) / **N/A** (live whitelist unset) | No `teacherWhitelist` on EG/SA/AE → all verified teachers eligible; whitelist rejection in integration |
| 7 | Booking mode (tutor approval) | **PASS** (live + tests) | Live `requiresTutorApproval`; integration pending-tab flow passes |
| 8 | Fee / free config | **PASS** | EG `minSessionPrice: 100` EGP; paid blocked in integration; fee snapshot immutability integration pass |
| 9 | lifecycleStatus / status consistency | **PASS** | Backfill dry-run `0` updates; mapper reads `lifecycleStatus` |
| 10 | Allowed actions | **PASS** | `allowedActionsTransition.test.ts` + production flow integration |
| 11 | Fake backend staging guard | **PASS** | `quran_sessions_backend_config_test.dart` — staging/play_production force firebase |
| 12 | Device QA guide | **PARTIAL** | Device pass executed 2026-07-03; see Device QA section — student path blocked, external-link UI fail |

---

## Automated test results (second pass — 2026-07-03)

| Suite | Command | Result |
|-------|---------|--------|
| Cloud Functions unit | `cd functions && npm test` | **201/201 pass** |
| Cloud Functions integration (emulator) | `cd functions && npm run test:integration` | **70/70 pass** |
| App launch + backend guard + nav | `flutter test test/features/quran_sessions/quran_sessions_backend_config_test.dart test/features/quran_sessions/quran_sessions_launch_policy_test.dart test/router/quran_sessions_nav_test.dart` | **18/18 pass** |
| Backfill consistency dry-run | `npm run quran-sessions:backfill-booking-session-consistency` | **0 sessions would update** |
| Live Firestore validation | Admin SDK + `validatePlatformConfig` / `validateMarketConfigForBooking` | **All valid** (see below) |

### First pass (reference)

| Suite | Result |
|-------|--------|
| Full app `test/features/quran_sessions/` | 108 pass, 4 compile failures (nav import) — **not re-run** in pass 2 |
| `packages/quran_sessions` | 1096 pass, 14 fail — **not re-run** in pass 2 (not CF gate) |

### Integration highlights (emulator)

- Free booking → scheduled  
- Tutor approval → `pending_tutor_approval` + allowed actions  
- Student cancel pending → slot released  
- Join rejected before window / after cancel  
- Canceled booking excluded from upcoming query  
- Teacher not whitelisted → rejected  
- Fee snapshot immutable after market price change  
- Paid booking blocked while payment provider disabled  
- Unsupported call type rejected  

---

## Live Firestore verification (`quran-playera-app`) — second pass

ADC available; reads via Admin SDK on **2026-07-03** after platform seed apply.

### Platform — `quran_session_platform_config/global`

| Check | Result |
|-------|--------|
| Document exists | Yes |
| `validatePlatformConfig` | **Valid** — no missing/invalid fields |
| `sessionMode` | **`videoOnly`** |
| `quranTutorBookingMode` | **`requiresTutorApproval`** |
| `enabledCallProviders` | **`mock`, `agora`** (no `external`) |
| `childAgeThreshold` | **`14`** (matches seed) |

**Implication:** `assertBookingPolicyConfigured` should allow booking for valid market + eligibility (no live `policy_not_configured` from incomplete platform doc).

### Market — `quran_session_market_configs/EG` (and SA, AE)

| Check | EG | SA | AE |
|-------|----|----|-----|
| Exists | Yes | Yes | Yes |
| `isEnabled` | true | true | true |
| `minSessionPrice` / `currencyCode` | 100 / EGP | 100 / SAR | 100 / AED |
| `teacherWhitelist` | unset (open market) | unset | unset |
| `validateMarketConfigForBooking` | **Valid** (cairo) | **Valid** (riyadh) | **Valid** (dubai) |

### First pass delta (platform)

| Field | Before apply | After apply |
|-------|--------------|-------------|
| `validatePlatformConfig` | Invalid (missing booking mode + session mode) | Valid |
| `enabledCallProviders` | included `external` | `mock`, `agora` only |
| `childAgeThreshold` | 13 | 14 |

---

## Item details

### 3. Fail-closed without config

- Unit: `assertBookingPolicyConfigured fails closed when market doc missing` (`sessionPolicyResolver.test.ts`)
- Live (second pass): platform + markets valid — fail-closed path still covered by unit/integration when docs absent in emulator

### 4. Video-only

- Live: `sessionMode: "videoOnly"` on staging platform doc
- Seed: `sessionMode: "videoOnly"` in `scripts/seedPlatformConfig.ts`
- Server: `createSessionBooking` rejects non-`videoCall` when `eligibility.market.sessionMode === "videoOnly"`
- Client: `sessionModePolicyFromLaunchConfig` → `enabledCallTypes: { videoCall }` only

### 5. Out of scope (confirmed not part of this rollout)

| Area | Status |
|------|--------|
| Paid booking / wallet / checkout | Blocked server-side (`payment_provider_unavailable`, integration test) |
| Voice / external meeting in product UI | Not in limited rollout; live platform no longer lists `external` |
| Admin Panel UI | Seeds / console only (`admin-config-seed.md`) |
| Reschedule denorm (`hasPendingReschedule`) | Incomplete — not launch dependency |

### 8. Fee / free

- Market fee present on live EG (`minSessionPrice: 100`)
- Free rollout: book as free teacher / free pricing path; paid attempts rejected in integration
- No client hardcoded fee in domain price policy (server snapshot authoritative)

### 9. lifecycleStatus

- `session_firestore_mapper.dart` maps `lifecycleStatus` from Firestore
- Backfill dry-run: 0 inconsistent sessions on live project

### 10. Allowed actions

- Unit: `allowedActionsTransition.test.ts`
- Integration: `productionFlow.integration.test.ts` — pending approval, cancel, join window, fee snapshot, whitelist, upcoming filter
- Denorm written on create; transitions recompute via lifecycle callables

### 11. Fake backend guard

- `resolveQuranSessionsBackendMode`: `staging` and `play_production` → always `firebase`
- Tests: `staging distribution never resolves fake backend`, `play_production distribution never resolves fake backend`

---

## Manual re-check (maintenance)

After future seed or policy changes:

```sh
cd functions
npm run seed:platform-config          # compare dry-run vs live
node -r ts-node/register -e "
const admin = require('firebase-admin');
const { validatePlatformConfig, validateMarketConfigForBooking } = require('./src/quranSessions/sessionPolicyResolver');
admin.initializeApp({ projectId: 'quran-playera-app' });
const db = admin.firestore();
(async () => {
  const plat = (await db.doc('quran_session_platform_config/global').get()).data();
  const eg = (await db.doc('quran_session_market_configs/EG').get()).data();
  console.log('platform', validatePlatformConfig(plat));
  console.log('EG market', validateMarketConfigForBooking(eg, 'cairo'));
  console.log('sessionMode', plat?.sessionMode, 'bookingMode', plat?.quranTutorBookingMode);
})();
"
npm test && npm run test:integration
npm run quran-sessions:backfill-booking-session-consistency
```

Expected: `platform.valid === true`, `sessionMode === 'videoOnly'`, `quranTutorBookingMode === 'requiresTutorApproval'`, no `external` in `enabledCallProviders`.

---

## Staging build flags / flavor

Use **Firebase-backed** staging build pointing at `quran-playera-app`:

| Define | Staging value | Purpose |
|--------|---------------|---------|
| `TILAWA_DISTRIBUTION` | `staging` | Enables staging launch defaults; **blocks fake backend** |
| `TILAWA_LAUNCH_LEARN_QURAN_STUDENT_FEATURE_ENABLED` | `true` | **Required** for Home Learn Quran card + `/sessions` student hub (defaults **false** even on staging) |
| `TILAWA_LAUNCH_QURAN_SESSIONS_BOOKING_ENABLED` | omit or `true` | On by default when distribution ≠ `play_production` |
| `TILAWA_QURAN_SESSIONS_BACKEND` | omit or `firebase` | Must not be `fake` on staging |
| `USE_QURAN_SESSIONS_MVP_FAKE` | omit | Fake opt-in disabled for staging |

Example (student booking QA):

```sh
cd apps/tilawa
flutter run --dart-define=TILAWA_DISTRIBUTION=staging \
  --dart-define=TILAWA_LAUNCH_LEARN_QURAN_STUDENT_FEATURE_ENABLED=true \
  --dart-define=TILAWA_LAUNCH_QURAN_SESSIONS_BOOKING_ENABLED=true \
  --dart-define=TILAWA_LAUNCH_ENABLED_CALL_PROVIDERS=external,mock,agora \
  --dart-define=TILAWA_LAUNCH_AGORA_APP_ID=aacd48a930944ecea29bec112f229eb9
```

**Device QA note (2026-07-03):** `.vscode/launch.json` staging profiles omit `TILAWA_LAUNCH_LEARN_QURAN_STUDENT_FEATURE_ENABLED=true` — add before student hub QA.

---

## Test accounts (manual QA)

| Role | Requirements |
|------|----------------|
| **Student** | Complete Quran Sessions profile; EG market / enabled city; adult or guardian-linked child |
| **Teacher (general)** | Verified teacher profile; active; schedule with open slot |
| **Teacher (whitelisted)** | Only needed if ops sets `teacherWhitelist` on market doc for soft launch |

---

## Device QA checklist (manual)

**Pass executed:** 2026-07-03 on **Android emulator `emulator-5554`** (OPPO A98 profile), app `com.tilawa.app`, signed in as **verified teacher** (Muhammad Kamel). Build command included all staging defines above (including `LEARN_QURAN_STUDENT_FEATURE_ENABLED=true`); **Home Learn Quran card still absent** — treat student hub as blocked until flag + cold install verified.

### Mapping: verification checks → D1–D8

| Check # | Scenario | D-map | Status | Evidence |
|---------|----------|-------|--------|----------|
| 1 | Student opens Learn Quran hub | D1 entry | **BLOCKED** | No `تعلّم القرآن` / `ابدأ التعلّم` on Home after staging install; Maestro `inspect_screen` 2026-07-03 |
| 2 | Browse teachers | D1 | **BLOCKED** | `/sessions/teachers` unreachable without student hub |
| 3 | Book video-only session | D1 | **BLOCKED** | No student account + hub blocked |
| 4 | Booking in Pending vs Upcoming tab | D2 | **BLOCKED** | Requires student booking |
| 5 | Cancel pending/valid session | D3 | **BLOCKED** | Requires student booking |
| 6 | Canceled not in valid Upcoming | D8 | **BLOCKED** | Requires student booking |
| 7 | Join hidden/disabled before window | D5 | **BLOCKED** | Requires scheduled session |
| 8 | Join allowed in valid window | D6 | **BLOCKED** | Requires scheduled session |
| 9 | Join rejected for canceled | D7 | **BLOCKED** | Requires canceled session |
| 10 | Voice/external not exposed | — | **FAIL** | Teacher dashboard shows **رابط الاجتماع الخارجي** (external meeting link) app bar control — screenshot `docs/quran-sessions/device-qa-evidence/2026-07-03-teacher-dashboard-external-link.png` |
| 11 | Fake backend not active | — | **PASS** | `quran_sessions_backend_config_test.dart` (staging → firebase); teacher dashboard loads Firebase teacher capability (not `student_mvp` fake user) |
| 12 | Teacher pending/upcoming correct | — | **SKIPPED** | Dashboard reached; stats **0 pending / 0 upcoming** with empty schedule — no booking fixture to validate tab placement |

### D1–D8 (student scenarios)

| # | Scenario | Pass | Fail | Block | Notes |
|---|----------|:----:|:----:|:-----:|-------|
| D1 | Book a free video session with verified teacher | | | ☑ | Blocked — student hub not reachable on device |
| D2 | Booking appears under **Pending** when tutor approval required | | | ☑ | Blocked |
| D3 | Cancel pending session as student | | | ☑ | Blocked |
| D4 | Same slot bookable again after cancel | | | ☑ | Blocked |
| D5 | **Join** hidden/disabled before join window (15m rule) | | | ☑ | Blocked |
| D6 | **Join** allowed inside valid window | | | ☑ | Blocked |
| D7 | Canceled session cannot join | | | ☑ | Blocked |
| D8 | Canceled session not listed under upcoming | | | ☑ | Blocked |

**Automation mapping (emulator — not a substitute for device):** D2–D4, D5–D7, D8 covered in `productionFlow.integration.test.ts`.

### Maestro flows (created)

| Flow | Path |
|------|------|
| Teacher dashboard smoke | `.maestro/quran_sessions/staging_teacher_dashboard_smoke.yaml` |
| Student hub → teachers (needs student flag + account) | `.maestro/quran_sessions/staging_student_hub_booking_smoke.yaml` |

Run (device must be booted):

```sh
# Teacher smoke (verified teacher signed in)
maestro test .maestro/quran_sessions/staging_teacher_dashboard_smoke.yaml

# Student hub (after LEARN_QURAN_STUDENT flag confirmed on build)
maestro test .maestro/quran_sessions/staging_student_hub_booking_smoke.yaml
```

### Blocking issues

1. **Student hub not visible** — `TILAWA_LAUNCH_LEARN_QURAN_STUDENT_FEATURE_ENABLED` defaults false; doc/launch profiles must include `=true`; cold install + confirm Home card before D1–D8.
2. **No student test account on device** — current session is verified teacher; need EG/cairo student with `quranSessionsProfile.profileCompleted: true` per `staging_teacher_seed_example.md`.
3. **External meeting link exposed** on teacher dashboard app bar despite live `sessionMode: videoOnly` — UI alignment gap (check #10 fail); see `remaining-risks.md`.

### Manual rerun steps (unblock D1–D8)

```sh
cd apps/tilawa
flutter run -d <device> \
  --dart-define=TILAWA_DISTRIBUTION=staging \
  --dart-define=TILAWA_LAUNCH_LEARN_QURAN_STUDENT_FEATURE_ENABLED=true \
  --dart-define=TILAWA_LAUNCH_QURAN_SESSIONS_BOOKING_ENABLED=true \
  --dart-define=TILAWA_LAUNCH_ENABLED_CALL_PROVIDERS=external,mock,agora \
  --dart-define=TILAWA_LAUNCH_AGORA_APP_ID=aacd48a930944ecea29bec112f229eb9
```

1. Sign in as **student** (not teacher-only account).
2. Home → **تعلّم القرآن** card → **ابدأ التعلّم** → browse teachers.
3. Book free video slot → confirm **Pending** tab (live `requiresTutorApproval`).
4. Cancel → rebook same slot → exercise join window (15m rule) on scheduled session.

### App Check soak recommendation

**NOT READY for App Check soak.**

Rationale: Student booking/join/cancel path (D1–D8) not exercised on device; external meeting affordance still visible to teachers; soak should follow green Device QA on correctly flagged staging build with student + teacher accounts.

---

## Blockers / follow-ups

1. ~~**Apply platform seed** on staging~~ — **Done** (second pass).  
2. ~~**Re-read Firestore** after apply~~ — **Done**; videoOnly + approval mode + provider list confirmed.  
3. **Device QA** D1–D8 — **PARTIAL** (2026-07-03): teacher dashboard OK; student path blocked; external-link UI fail — see Device QA section.  
4. **App Check** staging soak per `app-check-staging-plan.md` — **hold** until Device QA green.  
5. **Doc/launch gap:** add `TILAWA_LAUNCH_LEARN_QURAN_STUDENT_FEATURE_ENABLED=true` to staging launch profiles and verification examples.  
6. **UI gap:** hide teacher external-meeting link when platform `sessionMode: videoOnly`.  
7. Optional: re-run full `test/features/quran_sessions/` tree if nav compile regressions were fixed (pass 2 nav tests: 5/5 pass).  

---

## Related docs

- `production-readiness-checklist.md` — launch gate + §9 post-apply  
- `admin-config-seed.md` — seed apply commands  
- `app-check-staging-plan.md` — App Check phases  
- `remaining-risks.md` — voice/external UI alignment  

---

## Sign-off log

| Pass | Date | Verdict |
|------|------|---------|
| 1 | 2026-07-03 | **PARTIAL** — platform doc drift; markets OK |
| 2 | 2026-07-03 | **STAGING VERIFIED** (config + automated); Device QA **READY** |
| 3 | 2026-07-03 | **STAGING VERIFIED** (config + automated); Device QA **PARTIAL** — student blocked, external-link fail; App Check **NOT READY** |
