# Staging teacher seed — copy-paste ops reference

**Project (repo default):** `quran-playera-app` (`.firebaserc` + `functions/src/github.ts`)  
**Master runbook:** [ops_qa_runbook.md](./ops_qa_runbook.md)

---

## Prerequisites

| Requirement | Notes |
|-------------|-------|
| Node 22 | `functions/package.json` `engines.node` |
| Admin credentials | `export GOOGLE_APPLICATION_CREDENTIALS=/path/to/service-account.json` **or** `gcloud auth application-default login` |
| Firebase CLI project | `firebase use quran-playera-app` (optional; scripts default to `quran-playera-app`) |
| Override project | `export FIREBASE_PROJECT_ID=your-staging-id` before apply |

Service account needs **Firestore write** on target project (Firebase Admin SDK).

---

## Step 1a — Markets (run first)

```sh
cd functions
npm run seed:market-configs          # dry run — lists EG/SA/AE + city counts
npm run seed:market-configs:apply    # writes 3 countries, 19 cities
```

Source JSON: `docs/seed/quran_session_market_configs.json`  
Collection: `quran_session_market_configs/{countryCode}` + subcollection `cities/{cityId}`.

---

## Step 1b — Staging teachers (bulk seed)

```sh
cd functions
export GOOGLE_APPLICATION_CREDENTIALS=/path/to/service-account.json   # if not using ADC
npm run seed:staging-teachers          # dry run
npm run seed:staging-teachers:apply      # merge-writes 5 docs
```

**Doc IDs written:** `staging_teacher_01` … `staging_teacher_05`  
**Collection:** `quran_teacher_profiles/{teacherId}`

### What `seed:staging-teachers:apply` actually writes

Per teacher (from `functions/scripts/seedStagingTeachers.ts`) — **browse-ready** out of the box:

| Field | Example (`staging_teacher_01`) |
|-------|------------------------------|
| `userId` | `staging_teacher_01` (doc id — **not** a real Auth UID) |
| `displayName` | `أحمد المحفظ` |
| `verificationStatus` | `verified` |
| `profileCompleteness` | `complete` |
| `isPubliclyVisible` | `true` |
| `isActive` | `true` |
| `publicBio` | Non-empty Arabic bio (varies per teacher) |
| `teachingLanguages` | `["ar"]` |
| `specializations` | e.g. `["tajweed"]` (varies per teacher) |
| `averageRating` | `0` |
| `reviewCount` | `0` |
| `gender` | `male` / `female` |
| `allowedStudentGender` | `both` |
| `canTeachChildren` | `true` |
| `requiresGuardianApprovalForChildren` | `false` |
| `externalMeetingUrl` | `https://meet.google.com/staging-teacher-01` |
| `countryCode` | `EG` |
| `cityId` | `cairo` |
| `pricingType` | `free` |
| `createdAt` | fixed staging timestamp (`2026-01-01T00:00:00Z`) |
| `updatedAt` | server timestamp |

**Subcollection (same apply run):** `availability_config/schedule` with `weeklyRules` using short weekday keys (`sun`…`fri`), `09:00`–`12:00` Sun–Thu, Cairo timezone, `minNoticeMinutes: 120`.

Browse query (`FirestoreTeacherDataSource.getTeachers`):

```
profileCompleteness == 'complete' AND isPubliclyVisible == true
```

No Console merge required after apply. Re-run is idempotent (`merge: true`).

Optional backfill for **legacy** profiles missing completeness fields (not needed for fresh seed):

```sh
npm run admin:backfill-teacher-profiles          # dry run
npm run admin:backfill-teacher-profiles -- --apply
```

---

## Minimum **complete** teacher document (reference)

Use for Console import or Admin SDK when not using the bulk seed:

**Path:** `quran_teacher_profiles/staging_teacher_01`

```json
{
  "userId": "<Firebase Auth UID of teacher account>",
  "displayName": "أحمد المحفظ",
  "verificationStatus": "verified",
  "profileCompleteness": "complete",
  "isPubliclyVisible": true,
  "isActive": true,
  "gender": "male",
  "allowedStudentGender": "both",
  "canTeachChildren": true,
  "requiresGuardianApprovalForChildren": false,
  "publicBio": "محفظ قرآن متخصص في التجويد — حساب تجريبي.",
  "teachingLanguages": ["ar"],
  "specializations": ["tajweed"],
  "externalMeetingUrl": "https://meet.google.com/staging-teacher-01",
  "avatarUrl": "",
  "countryCode": "EG",
  "cityId": "cairo",
  "pricingType": "free",
  "averageRating": 0,
  "reviewCount": 0,
  "createdAt": "<Timestamp>",
  "updatedAt": "<Timestamp>"
}
```

### Avatar

- Store **HTTPS URL** in `avatarUrl` (Firebase Storage download URL or CDN).
- Omit or `""` → UI shows initials placeholder (`TeacherInitialsAvatar`).
- No storage path field — URL only.

### Call types (client metadata)

Derived in app from `externalMeetingUrl` (`FirestoreTeacherDataSource._supportedCallTypes`):

| `externalMeetingUrl` | `supportedCallTypes` shown in browse |
|----------------------|--------------------------------------|
| non-empty HTTPS | `external_meeting`, `voice_call`, `video_call` |
| empty / missing | `voice_call`, `video_call` only |

**Booking-time lock:** Cloud Functions use `callType` (`externalMeeting` \| `voiceCall` \| `videoCall`) + `quran_session_platform_config/global.enabledCallProviders` — not re-derived on join.

### Pricing subcollection (optional for free beta)

**Path:** `quran_teacher_profiles/{teacherId}/pricing/EG_cairo`

```json
{
  "amount": 0,
  "currencyCode": "EGP",
  "countryCode": "EG",
  "cityId": "cairo"
}
```

Omit when `pricingType: "free"` — app treats as free.

---

## Weekly schedule (required for bookable slots)

**Path:** `quran_teacher_profiles/{teacherId}/availability_config/schedule`

Field names are **camelCase** in Firestore. Weekday keys are **short** (`sat`…`fri`), not `monday`.

```json
{
  "teacherId": "staging_teacher_01",
  "timezone": "Africa/Cairo",
  "slotDurationMinutes": 30,
  "minNoticeMinutes": 120,
  "maxHorizonDays": 30,
  "bufferBeforeMinutes": 0,
  "bufferAfterMinutes": 0,
  "weeklyRules": {
    "sat": [],
    "sun": [{ "start": "09:00", "end": "12:00" }],
    "mon": [{ "start": "09:00", "end": "12:00" }],
    "tue": [{ "start": "09:00", "end": "12:00" }],
    "wed": [{ "start": "09:00", "end": "12:00" }],
    "thu": [{ "start": "09:00", "end": "12:00" }],
    "fri": []
  },
  "version": 1,
  "updatedAt": "<Timestamp>"
}
```

**Overrides (optional):** `quran_teacher_profiles/{teacherId}/availability_overrides/{yyyy-MM-dd}` — vacation / custom hours.

**Legacy slots:** `availability/{slotId}` — optional; production path uses rules + client `SlotGenerator`.

### Dashboard vs seed script

- **Real teacher QA:** sign in as teacher → Teacher dashboard → **Edit weekly template** (requires `userId == auth.uid`).
- **Bulk seed `staging_teacher_*`:** `userId` is fake doc id — dashboard save **will not** work. Schedule is seeded by `seed:staging-teachers:apply`; override via Console only if you need custom hours.

---

## Post-seed verification

### Firestore Console

1. `quran_session_market_configs/EG` → `isEnabled: true`; `cities/cairo` → `isEnabled: true`.
2. `quran_teacher_profiles/staging_teacher_01` → `profileCompleteness: complete`, `isPubliclyVisible: true`, `verificationStatus: verified`.
3. `availability_config/schedule` exists with `weeklyRules` using `mon`/`tue`/… keys.
4. Composite index live: `profileCompleteness` + `isPubliclyVisible` + `orderBy displayName` (deploy `firestore.indexes.json` if query fails).

### In-app (staging build)

1. Build with `TILAWA_DISTRIBUTION=staging` (booking on by default).
2. Sign in as **student** (not anonymous).
3. Open QuranTutor browse → expect ≥1 teacher (Arabic names, not filtered as placeholder).
4. Open teacher detail → pick slot ≥ `minNoticeMinutes` ahead → confirm book CTA visible.

### CLI smoke (optional, needs live project + seeded student)

```sh
cd functions
FIREBASE_PROJECT_ID=quran-playera-app npm run quran-sessions:staging-smoke
```

---

## Blockers before Step 2 (booking flags)

- [ ] Markets seeded; student `countryCode`/`cityId` match enabled market (e.g. `EG` / `cairo`).
- [ ] `seed:staging-teachers:apply` run (or real verified teachers with same field set).
- [ ] Browse shows ≥1 teacher; detail shows slots ≥ `minNoticeMinutes` ahead.
- [ ] `quran_session_platform_config/global` has `enabledCallProviders` (e.g. `["external","mock"]`) — Step 2 doc covers client flags; platform doc is separate seed.
- [ ] Test student `users/{uid}.quranSessionsProfile.profileCompleted: true` before booking CF accepts create.
