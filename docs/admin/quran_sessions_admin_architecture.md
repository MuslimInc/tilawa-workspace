# Quran Sessions Admin Architecture

> Angular admin (`apps/tilawa_admin`) for Quran Sessions moderation.

## Layers

```
Component → Facade → Use Case → Repository Interface → Firebase Implementation
                                      ↘ ModerationGateway (callable functions)
```

Components never import `@angular/fire/firestore` or `@angular/fire/functions`.

## DI tokens

| Token | Firebase implementation |
|-------|-------------------------|
| `TEACHER_APPLICATION_REPOSITORY` | `FirebaseTeacherApplicationRepository` |
| `TEACHER_PROFILE_REPOSITORY` | `FirebaseTeacherProfileRepository` |
| `QURAN_SESSIONS_USER_REPOSITORY` | `FirebaseQuranSessionsUserRepository` |
| `MODERATION_GATEWAY` | `FirebaseModerationGateway` |
| `SESSION_READ_REPOSITORY` | `FirebaseSessionReadRepository` |
| `SESSION_AUDIT_REPOSITORY` | `FirebaseSessionAuditRepository` |
| `SESSION_MODERATION_GATEWAY` | `FirebaseSessionModerationGateway` |
| `AUTH_SESSION_REPOSITORY` | `FirebaseAuthSessionRepository` |

## Routes

| Path | Feature |
|------|---------|
| `/quran-sessions/teacher-applications` | Application queue |
| `/quran-sessions/teacher-applications/:id` | Detail + moderation |
| `/quran-sessions/teachers` | Teacher profiles |
| `/quran-sessions/users` | Quran Sessions users |
| `/quran-sessions/sessions` | Session bookings list |
| `/quran-sessions/sessions/:id` | Session detail + moderation |

All shell routes require Firebase Auth + `{ admin: true }` custom claim.

## Future backend migration

Replace Firebase repository/gateway implementations and `app.config.ts` providers.
Facades, use cases, components, and routes stay unchanged.

See [future_backend_migration_strategy.md](./future_backend_migration_strategy.md).
