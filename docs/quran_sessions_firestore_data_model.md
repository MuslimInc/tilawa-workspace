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

| Field | Type |
|-------|------|
| `countryCode`, `countryName`, `currencyCode` | string |
| `defaultCityId` | string |
| `minimumStudentAgeYears`, `minimumTeacherAgeYears` | int |
| `minSessionPrice`, `maxSessionPrice` | number |
| `platformCommissionPercent` | number |
| `isEnabled` | bool |

#### Subcollection `cities/{cityId}`

| Field | Type |
|-------|------|
| `cityId`, `cityName`, `timezone`, `currencyCode` | string |
| `isEnabled` | bool |
| `minSessionPrice`, `maxSessionPrice` | number? |

### `quran_session_platform_config/global`

Global safety policy (mirrors `QuranSessionSafetyPolicy`):

- `childAgeThreshold`, `minimumStudentAgeYears`, `minimumTeacherAgeYears`
- Gender-combination flags, recording, guardian approval

### `quran_teacher_applications/{applicationId}`

Private onboarding data. **Phone number lives here only** — never on public teacher profile.

### `quran_teacher_profiles/{teacherId}`

Public teacher projection after admin approval.

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

- `quran_teacher_applications`: `userId` ASC, `updatedAt` DESC
- `quran_sessions`: `studentId` ASC, `startsAt` DESC
- `quran_bookings`: `studentId` ASC, `createdAt` DESC
- `quran_teacher_profiles`: `verificationStatus` ASC, `isActive` ASC, `displayName` ASC

## Security rules checklist

See [quran_sessions_firestore_security_rules.md](quran_sessions_firestore_security_rules.md).
