# Quran Sessions Admin Security Model

## Authentication

- Firebase Auth email/password for admin operators.
- Custom claim `{ admin: true }` required for shell routes and callables.

## Authorization

| Resource | Client read (admin) | Client write | Server write |
|----------|--------------------|--------------|--------------|
| `quran_teacher_applications` | ✅ admin claim | ❌ moderation | `reviewTeacherApplication` |
| `quran_teacher_profiles` | ✅ signed in | ❌ | `reviewTeacherApplication`, `moderateTeacherProfile` |
| `users` (+ `quranSessionsProfile`) | ✅ admin claim (read) | ❌ other users | `moderateQuranSessionsUser` |

## Rules

Deploy from repo root: `firebase deploy --only firestore:rules`

## Assigning admin claim

Use Firebase Admin SDK or Console custom claims tool for operator UIDs.
Document operator roster outside the repo.
