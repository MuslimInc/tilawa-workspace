# QuranTutor — Firebase configuration checklist

Use with [ops_qa_runbook.md](./ops_qa_runbook.md). Project IDs below use staging example `quran-playera-app` — substitute your target project.

---

## Project & app wiring

- [ ] `google-services.json` (Android) / `GoogleService-Info.plist` (iOS) match target Firebase project
- [ ] Release build uses **staging** project for QA; production project for Play production track
- [ ] Firebase Auth providers enabled (Google sign-in used in QA scripts)
- [ ] Cloud Functions region: **`us-central1`** (client `FirebaseFunctions.instanceFor(region: 'us-central1')`)

---

## Firestore data seed

### Markets

```sh
cd functions
export GOOGLE_APPLICATION_CREDENTIALS=/path/to/service-account.json
npm run seed:market-configs          # dry run
npm run seed:market-configs:apply    # writes EG, SA, AE from docs/seed/quran_session_market_configs.json
```

- [ ] Target country doc `isEnabled: true`
- [ ] Student city exists under `quran_session_market_configs/{CC}/cities/{cityId}` with `isEnabled: true`

### Platform policy (`quran_session_platform_config/global`)

Merge (do not wipe existing fields):

```json
{
  "enabledCallProviders": ["external", "mock"],
  "childAgeThreshold": 14,
  "minimumStudentAgeYears": 3,
  "minimumTeacherAgeYears": 18,
  "globalAllowMaleTeacherFemaleStudent": true,
  "globalAllowFemaleTeacherMaleStudent": true,
  "requireGuardianApprovalForChildren": false,
  "videoCallAllowedForChildren": false
}
```

- [ ] `enabledCallProviders` matches release scope ([provider_config_checklist.md](./provider_config_checklist.md))
- [ ] Optional `defaultExternalMeetingUrl` if teachers lack per-profile URLs

### Teachers (`quran_teacher_profiles/{teacherId}`)

**Staging bulk seed:**

```sh
npm run seed:staging-teachers:apply
```

Creates `staging_teacher_01`–`05` with browse-complete profiles **and** `availability_config/schedule` (weekly rules, Cairo timezone).

**Per-teacher manual (real Auth teachers only):**

- [ ] `userId` = teacher's Firebase Auth UID
- [ ] `verificationStatus`: `verified`
- [ ] `profileCompleteness`: `complete`
- [ ] `isPubliclyVisible`: `true`
- [ ] `isActive`: `true`
- [ ] `displayName`, `publicBio`, `gender`, `teachingLanguages`, `specializations`
- [ ] `externalMeetingUrl` (HTTPS) for external bookings
- [ ] `allowedStudentGender`, `canTeachChildren`
- [ ] `createdAt`, `updatedAt` timestamps
- [ ] Weekly schedule: seeded by `seed:staging-teachers:apply` for bulk docs; real teachers via app **or** write `availability_config/schedule` (see runbook §1)

**Backfill incomplete legacy profiles:**

```sh
npm run admin:backfill-teacher-profiles          # dry run
npm run admin:backfill-teacher-profiles -- --apply
```

### Students (`users/{uid}`)

Booking CF reads `quranSessionsProfile` nested map:

```json
{
  "quranSessionsProfile": {
    "accountStatus": "active",
    "gender": "male",
    "dateOfBirth": "<Timestamp>",
    "countryCode": "EG",
    "cityId": "cairo",
    "profileCompleted": true
  },
  "session": {
    "epoch": 1,
    "activeDeviceId": "<device>"
  }
}
```

- [ ] Profile complete before B1 booking test
- [ ] Session epoch present for single-active-device tests

---

## Security rules & indexes

```sh
firebase deploy --only firestore:rules --project <project-id>
firebase deploy --only firestore:indexes --project <project-id>
```

- [ ] Rules deployed from repo `firestore.rules`
- [ ] Teacher list composite index live (`profileCompleteness` + `isPubliclyVisible` + `displayName`) — index id in `firestore.indexes.json` collectionGroup `quran_teacher_profiles`
- [ ] Filter indexes for `specializations` / `teachingLanguages` array-contains (when filters used)
- [ ] Rules tests pass: `cd functions && npm run test:rules`

**Client write model:** bookings, sessions, slot locks — **CF only**. Teachers may write own `availability_config` / `availability_overrides`.

---

## Cloud Functions

### Stable-scope callables

```sh
./scripts/deploy_quran_session_callables.sh <project-id>
```

- [ ] `createSessionBooking`, `cancelSessionBooking`, `issueSessionRtcToken`, lifecycle callables deployed
- [ ] `QURAN_SESSIONS_ENFORCE_APP_CHECK` unset or `false` until staging App Check smoke passes

### Agora (RTC staging / prod)

```sh
firebase functions:secrets:set AGORA_APP_ID AGORA_APP_CERTIFICATE --project <project-id>
firebase deploy --only functions:issueSessionRtcToken --project <project-id>
```

- [ ] Secrets set in target project
- [ ] Token callable redeployed after secret rotation

### Smoke script (optional ops validation)

```sh
cd functions
npx ts-node scripts/stagingFreeBetaSmoke.ts   # end-to-end CF smoke against live staging
```

---

## App Check

| Step | Check |
|------|-------|
| Client | Release build activates Play Integrity / App Attest (`app_startup_tasks.dart`) |
| CF default | `QURAN_SESSIONS_ENFORCE_APP_CHECK` **not** `true` until staging verified |
| Staging smoke | Follow [app_check_staging_verification.md](../quran_sessions/app_check_staging_verification.md) |
| Production | Flip env + redeploy callables only after staging pass |

---

## FCM / notifications

- [ ] Test devices have notification permission (T7 teacher approval)
- [ ] `users/{uid}.notifications.activeFcmToken` updated on login (active device)

---

## Pre-upload verification

```sh
./scripts/quran_sessions_preflight.sh
```

CI hard gate: `.github/workflows/pr-checks.yml` job `quran-sessions-preflight`.

---

## Environment matrix

| Target | Firebase project | `enabledCallProviders` | Booking define |
|--------|------------------|------------------------|----------------|
| Local fake UI | N/A | N/A | `TILAWA_QURAN_SESSIONS_BACKEND=fake` |
| Staging QA | Staging | `external`, `mock` (+ `agora` for RTC) | `TILAWA_DISTRIBUTION=staging` |
| Play internal | Staging | Same as staging | `play_internal` → booking on |
| Play production | Production | `external` (± `agora` when ready) | Explicit `BOOKING_ENABLED=true` when launching |
