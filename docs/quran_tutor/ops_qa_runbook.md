# QuranTutor — Ops / QA Runbook

**Product (user-facing):** QuranTutor  
**Code / routes (stable):** package `quran_sessions`, paths `/sessions/*`  
**Related:** [production_config.md](./production_config.md) · [firebase_config_checklist.md](./firebase_config_checklist.md) · [provider_config_checklist.md](./provider_config_checklist.md) · [two_device_qa_script.md](./two_device_qa_script.md)

---

## 1. Firestore teacher seed

### Collection paths

| Path | Purpose |
|------|---------|
| `quran_teacher_profiles/{teacherId}` | Public marketplace profile |
| `quran_teacher_profiles/{teacherId}/pricing/{marketId}` | Per-market price (`marketId` = `{countryCode}_{cityId}`) |
| `quran_teacher_profiles/{teacherId}/availability_config/schedule` | Weekly recurring rules (slots generated client-side) |
| `quran_teacher_profiles/{teacherId}/availability_overrides/{yyyy-MM-dd}` | Vacation / busy / custom hours |
| `quran_teacher_profiles/{teacherId}/availability/{slotId}` | Legacy published slots (optional) |
| `quran_session_platform_config/global` | Platform policy + `enabledCallProviders` |
| `quran_session_market_configs/{countryCode}` | Enabled markets + cities subcollection |
| `users/{uid}` | Student `quranSessionsProfile` (booking gate) |

Canonical path constants: `FirestoreQuranSessionsPaths` in `apps/tilawa/lib/features/quran_sessions/data/firebase/firestore_paths.dart`.

### Required teacher profile fields (discovery + booking)

Teachers appear in browse only when **all** of the following hold (see `FirestoreTeacherDataSource.getTeachers`):

| Field | Staging / prod value | Notes |
|-------|---------------------|-------|
| `displayName` | Non-placeholder Arabic/EN name | Placeholders (`Quran Teacher`, `محفظ قرآن`) filtered client-side |
| `userId` | Firebase Auth UID of teacher account | Must match signed-in teacher for dashboard edits |
| `verificationStatus` | `verified` | CF booking eligibility |
| `profileCompleteness` | `complete` | Required for list query |
| `isPubliclyVisible` | `true` | Required for list query |
| `isActive` | `true` | |
| `gender` | `male` \| `female` | Eligibility matching |
| `allowedStudentGender` | `both` \| `femaleOnly` \| `maleOnly` | |
| `canTeachChildren` | boolean | |
| `teachingLanguages` | e.g. `["ar"]` | Array; used in filters |
| `specializations` | e.g. `["tajweed"]` | Array; used in filters |
| `publicBio` | Non-empty string | Marketplace card |
| `externalMeetingUrl` | HTTPS URL | Required for `externalMeeting` bookings unless platform default set |
| `averageRating`, `reviewCount` | numbers | Display; `0` OK for new teachers |
| `createdAt`, `updatedAt` | Firestore `Timestamp` | Required by DTO mapper |

Optional: `avatarUrl` (empty string OK; UI shows placeholder).

### Call types per teacher (UI + server)

Client derives `supportedCallTypes` from profile (`FirestoreTeacherDataSource._supportedCallTypes`):

- Always offers `voice_call` and `video_call` in browse metadata.
- Adds `external_meeting` when `externalMeetingUrl` is non-empty.

**Locked at booking time** by Cloud Functions `callProviderResolver.ts` using `callType` + Firestore `enabledCallProviders` — not re-derived on join.

| Teacher role (QA) | `externalMeetingUrl` | Book external | Book voice/video | Server `callProvider` (typical) |
|-------------------|---------------------|---------------|------------------|--------------------------------|
| External-only staging teacher | Set | Yes | Yes if `mock` in platform config | `external` or `mock` |
| RTC QA teacher | Set + platform has `agora` | Yes | Yes | `agora` when enabled server-side |
| MVP fake `teacher_1` (local only) | N/A (in-memory) | Yes | Yes (mock join) | N/A — fake backend |

### Availability / slots

Production model: **rules only** in Firestore; slots generated on device via `SlotGenerator` + `GetTeacherAvailabilityUseCase`.

**Schedule document** — `quran_teacher_profiles/{teacherId}/availability_config/schedule`:

```json
{
  "teacherId": "<teacherId>",
  "timezone": "Africa/Cairo",
  "slotDurationMinutes": 30,
  "minNoticeMinutes": 120,
  "maxHorizonDays": 30,
  "bufferBeforeMinutes": 0,
  "bufferAfterMinutes": 0,
  "weeklyRules": {
    "sun": [{ "start": "09:00", "end": "12:00" }],
    "mon": [{ "start": "09:00", "end": "12:00" }],
    "tue": [{ "start": "09:00", "end": "12:00" }]
  },
  "version": 1,
  "updatedAt": "<server timestamp>"
}
```

**Ops path:** have teacher sign in → Teacher dashboard → **Edit weekly template** (writes schedule doc). Do not bulk-seed generated slot documents.

### Indexes

Deploy from repo root after any index change:

```sh
firebase deploy --only firestore:indexes --project <project-id>
```

Critical composite for teacher browse (`firestore.indexes.json`):

```
quran_teacher_profiles: profileCompleteness == complete
  AND isPubliclyVisible == true
  ORDER BY displayName
```

See also `docs/admin/teacher_profile_migration.md` for backfill scripts and index notes.

### Seed scripts

From `functions/` with Admin SDK credentials (`GOOGLE_APPLICATION_CREDENTIALS` or ADC):

| Script | Command | Writes |
|--------|---------|--------|
| Markets (EG, SA, AE) | `npm run seed:market-configs:apply` | `quran_session_market_configs/*` |
| Staging teachers (5) | `npm run seed:staging-teachers:apply` | `quran_teacher_profiles/staging_teacher_01`–`05` |
| Teacher profile backfill | `npm run admin:backfill-teacher-profiles -- --apply` | Fixes incomplete / placeholder profiles |
| Dry-run first | Omit `--apply` on any script | Logs only |

`seedStagingTeachers.ts` sets: verified, `profileCompleteness: complete`, `publicBio`, languages/specializations, ratings, timestamps, publicly visible, free pricing, external Meet URLs, Egypt/Cairo, **and** `availability_config/schedule` (Sun–Thu 09:00–12:00 Cairo). Idempotent merge — safe to re-run. Bulk `staging_teacher_*` docs use fake `userId` (dashboard availability edit won't work; seed schedule is sufficient for browse/booking QA).

### Minimum staging seed checklist

1. `npm run seed:market-configs:apply`
2. `npm run seed:staging-teachers:apply` (or real approved teachers with same field set)
3. Merge `quran_session_platform_config/global`:

   ```json
   {
     "enabledCallProviders": ["external", "mock"],
     "childAgeThreshold": 14,
     "globalAllowMaleTeacherFemaleStudent": true,
     "globalAllowFemaleTeacherMaleStudent": true
   }
   ```

4. Real teachers only: adjust weekly schedule via app dashboard (`userId == auth.uid`)
5. Test student: `users/{uid}.quranSessionsProfile` with gender, DOB, `countryCode`, `cityId`, `profileCompleted: true`
6. `firebase deploy --only firestore:rules,firestore:indexes` if rules/indexes changed

### Minimum production seed checklist

1. **Real** verified teachers (not `staging_teacher_*`) with complete profiles
2. `TILAWA_LAUNCH_QURAN_SESSIONS_BOOKING_ENABLED=true` on release build (see §2)
3. Platform `enabledCallProviders` aligned with shipped RTC (see [provider_config_checklist.md](./provider_config_checklist.md))
4. Markets enabled for target countries only (`isEnabled: true` on country + city docs)
5. Agora secrets deployed if `agora` in providers: `AGORA_APP_ID`, `AGORA_APP_CERTIFICATE` + `issueSessionRtcToken` deployed
6. Legal/privacy sign-off for external meeting links

### Avatar

Store HTTPS URL in `avatarUrl`. Empty omits field; UI uses initials/placeholder. Host on Firebase Storage or CDN; no bundled avatar requirement for ops seed.

### Local fake teachers (dev only)

`QuranSessionsMvpStore` seeds `teacher_1`–`teacher_3` when `TILAWA_QURAN_SESSIONS_BACKEND=fake` or `TILAWA_LAUNCH_FIREBASE_INIT=false`. **Never** ship Play builds pointed at fake backend.

---

## 2. Booking flags

| Define | `play_production` default | Staging / `local` default | When disabled |
|--------|---------------------------|---------------------------|---------------|
| `TILAWA_LAUNCH_QURAN_SESSIONS_ENABLED` | `true` | `true` | `/sessions/*` redirects home; entry hidden |
| `TILAWA_LAUNCH_QURAN_SESSIONS_BOOKING_ENABLED` | **`false`** | **`true`** (`distribution != play_production`) | Book CTAs hidden; booking route redirects |
| `TILAWA_LAUNCH_QURAN_SESSIONS_PAID_BOOKING_SANDBOX_ENABLED` | `false` | `false` | Wallet / paid sandbox off (stable prod) |
| `TILAWA_LAUNCH_TEACHER_APPLICATION_ENABLED` | `false` | `true` | Teacher apply flow off |

Source: `AppLaunchConfig.fromEnvironment()` in `app_launch_config.dart`.

### Staging vs production behavior

| Build stamp | Booking UI | Backend |
|-------------|------------|---------|
| `TILAWA_DISTRIBUTION=staging` or `play_internal` / `play_alpha` / `play_beta` | On (unless override `=false`) | Firebase (default) |
| `TILAWA_DISTRIBUTION=play_production` | **Off** unless explicit `BOOKING_ENABLED=true` | Firebase |

### Mock / fake leak prevention

| Layer | Guard |
|-------|-------|
| Backend selection | `TILAWA_QURAN_SESSIONS_BACKEND` defaults to **firebase** when `TILAWA_LAUNCH_FIREBASE_INIT=true`. Fake only with `=fake` or Firebase init off (`quran_sessions_backend_config.dart`). |
| Production booking | Default `quranSessionsBookingEnabled: false` on `play_production` — no public booking until ops flips define. |
| Mock RTC UI | `sessionModePolicyFromLaunchConfig` sets `voiceVideoUseMockProvider` only when client hint is `mock` (no Agora App ID + no WebRTC URL on prod build). |
| Server authority | `callProvider` locked at booking from Firestore `enabledCallProviders` — remove `mock` from prod Firestore to kill server-side mock voice/video. |
| Rebook rule | Changing providers requires **new booking**; existing sessions keep original `callProvider`. |

Kill-switch rollback: [quran_sessions_free_beta_signoff.md § Rollback](../qa/quran_sessions_free_beta_signoff.md#rollback-checklist).

---

## 3. Voice / video provider flags

See [provider_config_checklist.md](./provider_config_checklist.md) for full matrix.

**Summary**

| Environment | Client `TILAWA_LAUNCH_ENABLED_CALL_PROVIDERS` | Firestore `enabledCallProviders` | Join expectation |
|-------------|-----------------------------------------------|----------------------------------|------------------|
| Staging Free Beta | `external,mock` (+ `agora` in debug/staging auto-inject) | `["external","mock"]` | External browser; mock placeholder for voice/video |
| Staging Agora QA | `external,mock,agora` + `TILAWA_LAUNCH_AGORA_APP_ID` | `["external","mock","agora"]` | Agora via `issueSessionRtcToken` CF |
| Production (stable v1) | `external,mock` | `["external"]` or `["external","mock"]` | External only for wide release; mock optional internal QA |
| Production RTC | `external,agora` + App ID | `["external","agora"]` | Real Agora; **no mock** in Firestore |

**Priority (server + client):** `agora` → `webrtc` → `mock` (`callProviderResolver.ts`, `resolveVoiceVideoProviderHint`).

**Missing config behavior**

| Gap | Symptom |
|-----|---------|
| Agora in Firestore, not in client defines | Booking may set `callProvider: agora`; join fails (no SDK / token path) |
| Agora in client, empty App ID on `play_production` | Client falls back to **mock** hint |
| `webrtc` without `TILAWA_LAUNCH_WEBRTC_SIGNALING_URL` | WebRTC provider not wired; falls back to mock |
| Voice/video booked, `mock` removed from Firestore | CF `unsupported_call_provider` on create |
| `issueSessionRtcToken` secrets missing | Agora join fails at token mint |

Staging auto-inject: `resolveRtcLaunchConfig` adds `kStagingAgoraAppId` in debug or `distribution == staging` (`quran_sessions_launch_policy.dart`).

---

## 4. App Check / Firebase security

### Auth assumptions

| Action | Auth |
|--------|------|
| Browse teachers / read availability rules | Signed-in user (`isSignedIn()`) |
| Create booking / cancel / join token | Signed-in + valid session epoch (CF) |
| Teacher edit availability | Owner: `quran_teacher_profiles/{id}.userId == auth.uid` |
| Anonymous | **Not supported** for QuranTutor flows |

Student profile gate: `users/{uid}.quranSessionsProfile` complete before CF accepts booking.

### Firestore rules (high level)

Source: `firestore.rules` — client writes denied on bookings/sessions (CF only).

| Collection | Read | Client write |
|------------|------|--------------|
| `quran_teacher_profiles` | Public if `isPubliclyVisible`; owner always | Owner update marketplace fields only; no create/delete |
| `availability_config`, `availability_overrides` | Signed-in | Teacher owner |
| `quran_bookings`, `quran_sessions` | Participant or admin | **Denied** |
| `quran_session_platform_config` | Signed-in | **Denied** (admin seed) |
| `quran_slot_locks` | Signed-in | **Denied** |

Cancel / reschedule / dispute: **Cloud Functions only** (`cancelSessionBooking`, etc.).

### App Check

| Layer | Status |
|-------|--------|
| Client | Activated in **release/profile** only (`app_startup_tasks.dart`); debug skips |
| CF | Opt-in: `QURAN_SESSIONS_ENFORCE_APP_CHECK=true` → `sessionCallableHttpsOptions` |
| Default | Enforcement **off** until ops verifies staging |

Runbook: [app_check_staging_verification.md](../quran_sessions/app_check_staging_verification.md).

### Callable token issuance

`issueSessionRtcToken` (region `us-central1`):

- Requires auth + session participant + `callProvider == agora`
- Secrets: `AGORA_APP_ID`, `AGORA_APP_CERTIFICATE`
- Joinable statuses: `scheduled`, `in_progress`, `reschedule_pending`

Provider resolution at booking: `callProviderResolver.ts` reading `quran_session_platform_config/global`.

---

## 5. Two-device QA sign-off

Full script: [two_device_qa_script.md](./two_device_qa_script.md).

| ID | Scenario | Pass criteria |
|----|----------|---------------|
| B1 | Student external booking + join | `callProvider: external`; browser opens meeting URL |
| B2 | Student mock voice/video | `callProvider: mock`; in-app placeholder join |
| B3 | Teacher sees booking | Dashboard lists session |
| B4 | Double-tap confirm | Single session doc |
| B5 | Stale device on booking | CF rejects or signs out device A |
| T2 | Login device B revokes A | A forced out ≤30s |
| T5 | A offline when B logs in | A signs out on resume |
| T6 | A mid-booking when B active | No session created on A |
| T7 | Teacher approval push | Push on active device only |
| T8 | Re-login A after B logout | Last login wins |

**Build:** release APK, staging Firebase, booking enabled, providers per test plan.

**Preflight before manual QA:**

```sh
./scripts/quran_sessions_preflight.sh
```

---

## 6. Release readiness

Full tracker: [release_readiness_report.md](./release_readiness_report.md).

| Area | Status | Blocker? | Owner | Required action |
|------|--------|----------|-------|-----------------|
| CI `analyze-and-test` (dart analyze) | ✅ Hard gate | Yes if red | Eng | Fix analyzer errors on PR |
| CI `quran-sessions-preflight` | ✅ Hard gate | Yes if red | Eng | Fix booking/join/rules tests |
| CI `functions-emulator-tests` | ✅ Hard gate | Yes if red | Eng | Fix CF unit/integration/rules |
| CI `melos run test` (full suite) | ⚠️ Advisory (`continue-on-error`) | **No** | Eng | Triage failures; includes teacher dashboard widget tests |
| `teacher_dashboard_availability_sync_test` | ❌ 2/5 failing locally | **No** for CI/release gate | Eng | Fix teacher availability reload UX (not ops) |
| Firestore staging seed | ⬜ Ops | **Yes** for staging QA | Ops | Run `seed:market-configs:apply` + `seed:staging-teachers:apply` |
| Firestore teacher seed (prod) | ⬜ Ops | **Yes** for public booking | Ops | Real verified teachers + schedules |
| `quran_session_platform_config/global` | ⬜ Ops | **Yes** for voice/video mode | Ops | Set `enabledCallProviders` per release scope |
| Play production booking flag | Default off | **Yes** for GA booking | Release | `TILAWA_LAUNCH_QURAN_SESSIONS_BOOKING_ENABLED=true` when ready |
| Agora secrets + CF deploy | ⬜ Ops | Yes if RTC release | Ops | Secrets + `issueSessionRtcToken` |
| Manual B1–B5 + join lifecycle | ⬜ QA | **Yes** | QA | [two_device_qa_script.md](./two_device_qa_script.md) |
| Manual T2–T8 | ⬜ QA | **Yes** | QA | Two-device script |
| App Check staging | ⬜ Ops | Yes before CF enforce prod | Ops | [app_check_staging_verification](../quran_sessions/app_check_staging_verification.md) |
| Privacy / external links | ⬜ Legal | Yes for Play wide | Legal | Policy covers third-party meeting URLs |
| GitHub Actions billing | ⚠️ Known issue | Yes if jobs skip | Repo owner | Fix billing / spending limit |

---

## Automated verification commands

```sh
# Hard gates (CI mirrors this)
./scripts/quran_sessions_preflight.sh
cd functions && npm test && npm run test:integration && npm run test:rules

# Advisory full package tests
melos run test

# Targeted teacher dashboard test (currently failing 2 cases — not in preflight)
cd packages/quran_sessions && flutter test test/presentation/widgets/teacher_dashboard_availability_sync_test.dart
```
