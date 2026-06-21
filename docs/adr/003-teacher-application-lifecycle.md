# ADR-003: Teacher as a Verified Profile, Not a User Role

**Status:** Accepted  
**Date:** 2026-06-21  
**Deciders:** Engineering team

---

## Context

Quran Sessions requires distinguishing between users who learn Quran (students)
and users who teach Quran (teachers). The naive model — `user.role = teacher` —
has several problems:

- A teacher is still a student in other contexts (they may book sessions with
  other teachers).
- Role mutation is destructive: flipping `role = student → teacher` loses
  the student state and cannot be undone cleanly.
- Teaching is not a system access role — it is a marketplace capability that
  requires verification, approval, and its own lifecycle.
- An admin reviewing a teacher application should not be confused with a
  teacher having admin system access.

Admin and moderator access are orthogonal to teacher capability and must not
be modeled on the same axis.

---

## Decision

**Teacher is a verified profile, not a user role.**

### 1. UserRole is system access only

```dart
enum UserRole { student, admin, moderator }
```

- `student` is the default for every new user.
- `admin` and `moderator` are platform-level access roles, granted by the
  engineering team — not self-assigned.
- `teacher` is removed from `UserRole`. It is not a system role.

### 2. TeacherApplication is the onboarding lifecycle object

Every user who wants to teach submits a `TeacherApplication`. This is a private,
admin-facing entity. It carries sensitive data (phone number, contact method)
and the full application lifecycle state.

State machine:

```
none
 └─→ draft          (user starts application)
       └─→ pending  (user submits)
             ├─→ approved  (admin approves → TeacherProfile created)
             └─→ rejected  (admin rejects → re-application after cooldown)

approved
 ├─→ suspended  (admin suspends temporarily)
 └─→ revoked    (admin revokes permanently)
```

### 3. TeacherProfile is the public projection

A `TeacherProfile` is created **only** when a `TeacherApplication` reaches
`approved`. It is the student-facing entity — structurally incapable of
exposing phone numbers, admin notes, or any sensitive application data.

The `ApproveTeacherApplicationUseCase` is the single path that creates a
`TeacherProfile`. No other code may create one.

### 4. Phone number rules

- Phone number is mandatory before an application can advance to `pending`.
- Phone must be stored in **E.164 format** (e.g. `+201234567890`).
- **MVP:** format-only validation (regex). No OTP verification.
- **Deferred:** OTP verification is a post-MVP item. It must be implemented
  before the platform scales teacher onboarding. See §Deferred Decisions.
- Phone number visibility:
  - Teacher themselves
  - Authorized admin/moderator
  - **Never:** teacher list, teacher profile screen, booking screen, student
    sessions screen

### 5. Re-application policy

| Event | Policy |
|---|---|
| Application rejected | Re-application allowed after **30-day cooldown** |
| Application revoked | Re-application **not allowed** (permanent) |
| Max re-application attempts | Unlimited in MVP — product decision deferred |
| Cooldown starts | From `reviewedAt` timestamp on the rejected application |

These values are defined in `FakeMvpTeacherApplicationRepository`
(`_cooldownDays = 30`) and must match the backend implementation when
Firebase is wired.

### 6. Permission rules

Enforced in the domain/application layer (use cases), not in the UI:

| State | Can appear in teacher list? | Can accept bookings? |
|---|---|---|
| No application / draft | No | No |
| Pending | No | No |
| Approved + active | Yes | Yes |
| Approved + inactive | No | No |
| Rejected | No | No |
| Suspended | No | No |
| Revoked | No | No |

---

## Consequences

### Positive

- `UserProfile` stays clean — no teacher-specific fields pollute the base
  user model.
- `TeacherApplication` and `TeacherProfile` have independent lifecycles and
  clear privacy boundaries.
- The model supports a user being both a student (booking sessions) and an
  approved teacher simultaneously.
- Admin and moderator roles remain orthogonal — a moderator is not a teacher.
- The `TeacherProfile` is structurally safe to pass to student-facing screens.

### Negative / Trade-offs

- More domain objects. An operation that "approves a teacher" now touches two
  entities: `TeacherApplication` (status → approved) + `TeacherProfile` (create).
- The `ApproveTeacherApplicationUseCase` must be a two-phase operation
  coordinated at the use-case level.
- Checking "is this user a teacher?" requires a repository call
  (`TeacherProfileRepository.getProfileByUserId`) rather than a simple enum check.

---

## Deferred Decisions

| Decision | Why deferred | Owner |
|---|---|---|
| OTP phone verification | Adds SDK complexity; admin human-verification sufficient for MVP | Backend team, post-MVP |
| Max re-application attempts | Product policy not finalized | Product |
| Appeal process for revocation | Out of MVP scope | Product |
| Teacher self-deactivation flow | No screen; deactivate/reactivate via admin MVP | Engineering |
| TeacherProfile display name sourcing | Defaults to empty string on creation; needs teacher onboarding screen | Engineering |

---

## Implementation

### New entities

- `packages/quran_sessions/lib/src/domain/entities/teacher_application.dart`
- `packages/quran_sessions/lib/src/domain/entities/teacher_profile.dart`

### New repository interfaces

- `packages/quran_sessions/lib/src/domain/repositories/teacher_application_repository.dart`
- `packages/quran_sessions/lib/src/domain/repositories/teacher_profile_repository.dart`

### New use cases

| Use Case | Description |
|---|---|
| `StartTeacherApplicationUseCase` | Creates a draft application |
| `SaveTeacherApplicationDraftUseCase` | Persists draft without submitting |
| `SubmitTeacherApplicationUseCase` | Advances draft to pending; validates phone + completeness |
| `GetTeacherApplicationStatusUseCase` | Returns current application for a user |
| `ApproveTeacherApplicationUseCase` | Admin: approves + creates TeacherProfile |
| `RejectTeacherApplicationUseCase` | Admin: rejects with reason |
| `SuspendTeacherProfileUseCase` | Admin: suspends application + deactivates profile |
| `RevokeTeacherProfileUseCase` | Admin: permanently revokes application + deactivates profile |

### New failures

See `packages/quran_sessions/lib/src/domain/failures/quran_sessions_failure.dart`:

- `TeacherApplicationNotFoundFailure`
- `TeacherApplicationAlreadyPendingFailure`
- `TeacherApplicationRejectedFailure`
- `TeacherApplicationSuspendedFailure`
- `TeacherApplicationRevokedFailure`
- `TeacherPhoneNumberRequiredFailure`
- `InvalidTeacherPhoneNumberFailure`
- `TeacherApplicationIncompleteFailure`
- `ReapplicationTooSoonFailure`
- `TeacherProfileNotApprovedFailure`
- `TeacherProfileNotActiveFailure`

### MVP fake implementations

- `apps/tilawa/lib/features/quran_sessions/data/fake_mvp_teacher_application_repository.dart`
- `apps/tilawa/lib/features/quran_sessions/data/fake_mvp_teacher_profile_repository.dart`

Both are wired in `QuranSessionsMvpModule`.

---

## Related

- [ADR-001: Quran Player Root Overlay Route](001-quran-player-root-overlay-route.md)
- [ADR-002: Quran Sessions Backend-Agnostic Architecture](002-quran-sessions-backend-agnostic-architecture.md)
- [`packages/quran_sessions/lib/src/domain/entities/teacher_application.dart`](../../packages/quran_sessions/lib/src/domain/entities/teacher_application.dart)
- [`packages/quran_sessions/lib/src/domain/entities/teacher_profile.dart`](../../packages/quran_sessions/lib/src/domain/entities/teacher_profile.dart)
