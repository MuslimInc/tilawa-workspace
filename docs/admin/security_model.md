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

Script (single Auth record per email):

```sh
cd functions
ADMIN_EMAIL=operator@example.com ADMIN_PASSWORD='…' npm run admin:create-user
```

**Duplicate Auth accounts:** `getUserByEmail` returns one UID. If the same email
has multiple Auth UIDs (see **Quran Sessions → Duplicate accounts** in
tilawa-admin), set `{ admin: true }` on the UID you sign in with — or on every
UID that should show the admin badge in the users list. Example (Admin SDK):

```ts
await getAuth().setCustomUserClaims("<uid>", { admin: true });
```

After changing claims, the user must sign out and sign in again (or refresh the
ID token) for badges and callables to see the update.

