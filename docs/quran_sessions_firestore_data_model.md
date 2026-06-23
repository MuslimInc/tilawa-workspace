# Quran Sessions — Firestore Data Model

> Backend implementation detail. Domain entities in `packages/quran_sessions` remain
> backend-agnostic. See [ADR-002](adr/002-quran-sessions-backend-agnostic-architecture.md).

## Collections

### `users/{uid}`

Top-level user document (shared with Tilawa auth). Quran Sessions stores profile
data under the nested map `quranSessionsProfile`:

| Field | Type | Notes |
|-------|------|-------|
| `role` | string | `student`, `admin`, `moderator` |
| `gender` | string? | `male`, `female` |
| `dateOfBirth` | timestamp | Required for booking |
| `countryCode` | string? | ISO 3166-1 alpha-2 |
| `countryName` | string? | Display |
| `cityId` | string? | Machine id within market |
| `cityName` | string? | Display |
| `currencyCode` | string? | ISO 4217 |
| `timezone` | string? | IANA |
| `accountStatus` | string | `active`, `underReview`, `suspended`, `blocked` |
| `profileCompleted` | bool | Derived gate for entry |
| `createdAt` / `updatedAt` | timestamp | |

### `quran_session_market_configs/{countryCode}`

Document ID = ISO country code (e.g. `EG`). Direct lookup — do not scan all docs
to resolve a single country.

| Field | Type | Notes |
|-------|------|-------|
| `countryCode` | string | Same as document ID |
| `countryName` / `countryNameAr` | string | Arabic display |
| `countryNameEn` | string? | English |
| `currencyCode` | string | ISO 4217 |
| `timezone` | string | IANA |
| `phoneCode` | string? | E.g. `+20` |
| `flagEmoji` | string? | UI |
| `defaultCityId` | string | |
| `minimumStudentAgeYears`, `minimumTeacherAgeYears` | int | |
| `minSessionPrice`, `maxSessionPrice` | number | |
| `platformCommissionPercent` | number | |
| `isEnabled` | bool | List queries filter `true` |
| `sortOrder` | int | Ascending list order |
| `updatedAt` | timestamp | |

#### Subcollection `cities/{cityId}`

Document ID = stable slug (e.g. `cairo`).

| Field | Type | Notes |
|-------|------|-------|
| `cityId` | string | Same as document ID |
| `cityName` / `cityNameAr` | string | Arabic |
| `cityNameEn` | string? | English |
| `timezone`, `currencyCode` | string | |
| `isEnabled` | bool | |
| `sortOrder` | int | |
| `updatedAt` | timestamp | |

Seed data: see [quran_sessions_market_config_sources.md](quran_sessions_market_config_sources.md).

### `quran_session_platform_config/global`

Global safety policy (mirrors `QuranSessionSafetyPolicy`):

- `childAgeThreshold`, `minimumStudentAgeYears`, `minimumTeacherAgeYears`
- Gender-combination flags, recording, guardian approval

### `quran_teacher_applications/{applicationId}`

Private onboarding data. **Phone number lives here only** — never on public teacher profile.

| Field | Type | Notes |
|-------|------|-------|
| `publicDisplayName` | string? | Intended public marketplace name (never from bio) |
| `teacherDisplayName` | string? | Teacher-preferred label |
| `status`, `userId`, `bio`, … | | See application lifecycle docs |

### `quran_teacher_profiles/{teacherId}`

Public teacher projection after admin approval.

| Field | Type | Notes |
|-------|------|-------|
| `profileCompleteness` | string | `complete` \| `incomplete` |
| `isPubliclyVisible` | bool | Public discovery gate |
| `displayName`, `publicBio`, `userId`, … | | See teacher profile entity |

#### Subcollection `availability/{slotId}`

| Field | Type |
|-------|------|
| `startsAt`, `endsAt` | timestamp |
| `isBooked` | bool |
| `status` | string |

### `quran_bookings/{bookingId}`

Student bookings. Created in a transaction with slot lock + session doc.

### `quran_sessions/{sessionId}`

Scheduled sessions linked by `bookingId`.

## Required composite indexes

Deploy from the repo root:

```sh
firebase deploy --only firestore:indexes
```

Or use the **Create index** link in the Firestore error log (fastest for a single index).

Index definitions live in [`firestore.indexes.json`](../firestore.indexes.json).

- `quran_session_market_configs`: `isEnabled` ASC, `sortOrder` ASC
- `quran_session_market_configs/{country}/cities`: `isEnabled` ASC, `sortOrder` ASC
- `quran_teacher_applications`: `userId` ASC, `updatedAt` DESC
- `quran_sessions`: `studentId` ASC, `startsAt` DESC
- `quran_sessions`: `teacherId` ASC, `startsAt` DESC
- `quran_bookings`: `studentId` ASC, `createdAt` DESC
- `quran_teacher_profiles`: `verificationStatus` ASC, `isActive` ASC, `displayName` ASC (legacy list)
- `quran_teacher_profiles`: `verificationStatus` ASC, `isActive` ASC, `profileCompleteness` ASC, `isPubliclyVisible` ASC (public discovery)

Migration: [`docs/admin/teacher_profile_migration.md`](admin/teacher_profile_migration.md).

For query shapes, monitoring, and performance recommendations see
[firestore_query_optimization.md](firestore_query_optimization.md).

## Security rules checklist

See [quran_sessions_firestore_security_rules.md](quran_sessions_firestore_security_rules.md).
