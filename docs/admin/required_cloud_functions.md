# Required Cloud Functions (Admin)

| Callable | Purpose |
|----------|---------|
| `reviewTeacherApplication` | approve / reject / suspend / revoke application |
| `moderateTeacherProfile` | activate / deactivate teacher profile |
| `moderateQuranSessionsUser` | suspend / reactivate QS account status |
| `lookupUserAdminClaims` | resolve which user IDs have `{ admin: true }` (users list badges) |
| `lookupDuplicateAccountsByEmail` | find duplicate Auth + Firestore-only accounts sharing an email |
| `requestUserDeletion` | schedule admin-initiated account deletion |
| `requestDuplicateAccountsDeletion` | delete duplicate accounts (Auth: soft-delete; Firestore-only: immediate purge) |
| `purgeFirestoreOrphanUser` | hard-purge a single Firestore-only user doc (no Auth account) |
| `cancelUserDeletion` | cancel a pending deletion |

All require `{ admin: true }` on the caller ID token.

Deploy: `cd functions && npm run build && firebase deploy --only functions`


