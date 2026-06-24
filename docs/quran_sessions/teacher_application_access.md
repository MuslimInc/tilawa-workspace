# Teacher application access (remote gating)

Backend source of truth for **who may see** “Become a teacher / Muhaffiz” entry
points. Does **not** remove the application flow for users who already started or
were approved.

## Firestore

### Platform policy

`quran_session_platform_config/global.teacherApplicationAccess`:

```json
{
  "mode": "none",
  "allowlistUserIds": [],
  "rules": {
    "countryCodes": [],
    "roles": [],
    "emails": [],
    "phones": []
  }
}
```

| `mode` | Behavior |
|--------|----------|
| `none` | Hide apply entry for users without an in-flight application (default) |
| `all` | All users may see apply entry |
| `allowlist` | Only `allowlistUserIds` |
| `rules` | Match if **any** rule list contains the user’s country, role, email, or phone |

### Per-user override

`users/{uid}.quranSessionsProfile.canApplyAsTeacher`:

| Value | Meaning |
|-------|---------|
| `true` | Force allow (admin) |
| `false` | Force deny (admin) |
| absent / `null` | Follow platform policy |

Resolution order: **user override → platform policy**.

## App

- Domain: `ResolveTeacherApplicationAccessUseCase` → `canApplyAsTeacher`
- Settings: `TeacherApplicationAccessCubit` + `SettingsTeachingVisibility`
- Existing `TeacherCapability` still drives pending/approved/dashboard UI
- Loading / errors: **fail closed** (hide apply entry)
- Refresh: login/logout, app resume, settings route focus, auth bloc changes

Build-time `teacherApplicationEnabled` remains a deployment kill switch.

## Admin

- **Per user:** Quran Sessions → Users → “Follow policy” cycles
  `policy → allow → deny → policy` via `setTeacherApplicationAccess` CF
- **Global policy:** set `teacherApplicationAccess` on `global` doc (console or CF
  `policy` payload)

## Security

- Clients: read platform config + own user doc
- Writes: admin only (`setTeacherApplicationAccess` or `token.admin` on `users`)
- Rules block client self-grant of `canApplyAsTeacher`
