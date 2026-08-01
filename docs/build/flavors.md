# Tilawa build flavors

Flutter flavors live under `apps/tilawa` with env JSON in `apps/tilawa/env/`.

| Flavor | Env file | `TILAWA_DISTRIBUTION` | Typical use |
|--------|----------|------------------------|-------------|
| `development` | `env/development.json` | `local` | Local engineering |
| `staging` | `env/staging.json` | `staging` | Staging Firebase (`quran-playera-app`) |
| `production` | `env/production.json` | `play_production` | Store / production builds |

VS Code launch profiles: `.vscode/launch.json` (cwd `apps/tilawa`).

**Dart defines from JSON:** pass `--dart-define-from-file=env/<file>.json`. Flutter accepts **multiple** `--dart-define-from-file` flags; later files override earlier keys. Prefer a small gitignored override file on top of the committed flavor JSON.

Cross-ref: [provider_config_checklist.md](../quran_tutor/provider_config_checklist.md) · [app_environment.dart](../../apps/tilawa/lib/core/bootstrap/app_environment.dart)

---

## Video session QA (staging debug)

Use this when staging Firestore has `enabledCallProviders: ["mock", "agora"]` and
`sessionsMode: videoOnly` — the default **MeMuslim Staging** profile registers
LiveKit only, so joining an Agora session shows:

> In-app Agora calls are not enabled in this build…

### Required client flags

| Define | Value | Notes |
|--------|-------|-------|
| `TILAWA_DISTRIBUTION` | `staging` | From `env/staging.json` |
| `TILAWA_LAUNCH_QURAN_SESSIONS_ENABLED` | `true` | Booking + sessions hub |
| `TILAWA_LAUNCH_QURAN_SESSIONS_BOOKING_ENABLED` | `true` | Student booking |
| `TILAWA_LAUNCH_LEARN_QURAN_STUDENT_FEATURE_ENABLED` | `true` | Learn Quran entry |
| `TILAWA_LAUNCH_ENABLED_CALL_PROVIDERS` | `external,mock,agora` | Must include `agora`; omit `livekit` to match staging server config |
| `TILAWA_LAUNCH_AGORA_APP_ID` | staging public App ID | **Optional in debug/staging** — when empty and `agora` is enabled, `resolveRtcLaunchConfig()` auto-fills `kStagingAgoraAppId` |

Production env files must **not** include `agora` or `livekit` in
`TILAWA_LAUNCH_ENABLED_CALL_PROVIDERS`.

### Where to find the Agora App ID

The staging **public** App ID (not the certificate) is referenced in source as
`kStagingAgoraAppId` in
[`quran_sessions_launch_policy.dart`](../../apps/tilawa/lib/features/quran_sessions/quran_sessions_launch_policy.dart).
The same value is stored as Firebase secret `AGORA_APP_ID` for Cloud Functions
token minting (`issueSessionRtcToken`). Use Agora Console or your team vault —
**never commit the value** in env JSON tracked by git.

### Create local env file (no secrets in repo)

1. Copy the example:

   ```sh
   cd apps/tilawa
   cp env/staging.video.local.json.example env/staging.video.local.json
   ```

2. Edit `env/staging.video.local.json`:
   - Replace `YOUR_AGORA_APP_ID` with the staging App ID, **or**
   - Remove the `TILAWA_LAUNCH_AGORA_APP_ID` line to rely on the built-in
     staging default (debug/staging only).

3. `env/staging.video.local.json` is gitignored — do not commit it.

**Minimal override (two-file launch):** you can keep only the RTC keys in the
local file when using **MeMuslim Staging (Video QA)** (loads `staging.json`
first, then the local override):

```json
{
  "TILAWA_LAUNCH_ENABLED_CALL_PROVIDERS": "external,mock,agora",
  "TILAWA_LAUNCH_AGORA_APP_ID": "YOUR_AGORA_APP_ID"
}
```

**Standalone (one file):** use the full example as-is with a single
`--dart-define-from-file=env/staging.video.local.json`.

### VS Code

Launch profile: **MeMuslim Staging (Video QA)**  
Requires `env/staging.video.local.json` (create from example above).

### CLI equivalent

```sh
cd apps/tilawa
flutter run --flavor staging \
  --dart-define-from-file=env/staging.json \
  --dart-define-from-file=env/staging.video.local.json
```

Cold restart after changing dart-defines.

### Server alignment

Before booking or joining:

- [ ] Firestore `quran_session_platform_config/global.enabledCallProviders`
      includes `agora` (staging default: `["mock", "agora"]`)
- [ ] `sessionMode` is `videoOnly` (voice bookings rejected server-side)
- [ ] Firebase secrets `AGORA_APP_ID` + `AGORA_APP_CERTIFICATE` set;
      `issueSessionRtcToken` deployed
- [ ] **Book a new session** after config changes — existing sessions keep
      their stored `callProvider`

Client `TILAWA_LAUNCH_ENABLED_CALL_PROVIDERS` must include `agora` so
`QuranSessionsRtcModule` registers `AgoraCallProvider`. Join routing uses the
session's stored provider (`RoutingSessionCallProvider`), not the booking UI hint.

### Two-device test (teacher + student, same staging Firebase)

Accounts and profile requirements:
[maestro-device-qa-setup.md](../quran-sessions/maestro-device-qa-setup.md).

Both devices: install debug build via **MeMuslim Staging (Video QA)** (or CLI
above). Staging Firebase project `quran-playera-app`.

| Step | Student device | Teacher device | Expected |
|------|----------------|----------------|----------|
| 1 | Sign in (student account) | Sign in (verified teacher) | Home loads |
| 2 | Learn Quran → pick teacher → **Video** session → book slot | — | Booking succeeds; Firestore `callType: videoCall`, `callProvider: agora` |
| 3 | — | Teacher dashboard → open session | Session detail shows video / Agora |
| 4 | My Sessions → open session → **Join** | Same session → **Join** | Agora in-app call shell; camera/mic prompts |
| 5 | Verify A/V both ways | Verify A/V both ways | Two-way video; no `agora_not_registered` error |

**Join window:** Maestro staging accounts can join outside the normal window —
see [staging_qa_join_window_bypass.md](../quran_sessions/staging_qa_join_window_bypass.md).
Other accounts must join within 15 minutes before `startsAt` through `endsAt`.

**Troubleshooting**

| Symptom | Fix |
|---------|-----|
| `agora_not_registered` | Rebuild with `agora` in `TILAWA_LAUNCH_ENABLED_CALL_PROVIDERS` |
| Token / credentials error | Check Firebase `AGORA_APP_*` secrets + CF deploy |
| Mock shell instead of video | Session booked when Firestore had no `agora`; book a **new** session |
| LiveKit error on join | Session has `callProvider: livekit` but staging server uses Agora — book new session on current platform config |
