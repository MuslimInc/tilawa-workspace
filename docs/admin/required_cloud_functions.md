# Required Cloud Functions (Admin)

| Callable | Purpose |
|----------|---------|
| `reviewTeacherApplication` | approve / reject / suspend / revoke application |
| `moderateTeacherProfile` | activate / deactivate teacher profile |
| `moderateQuranSessionsUser` | suspend / reactivate QS account status |

All require `{ admin: true }` on the caller ID token.

Deploy: `cd functions && npm run build && firebase deploy --only functions`
