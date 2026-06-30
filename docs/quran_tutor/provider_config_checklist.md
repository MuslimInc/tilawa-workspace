# QuranTutor — Voice / video provider configuration checklist

**Authority:** Server locks `callProvider` at booking (`functions/src/quranSessions/callProviderResolver.ts`). Client dart-defines control which SDKs are **registered** and UI hints only.

Cross-ref: [production_config.md](./production_config.md) · [ops_qa_runbook.md](./ops_qa_runbook.md) §3.

---

## Provider types

| Provider | Booking `callType` | Join path | Production notes |
|----------|-------------------|-----------|------------------|
| `external` | `externalMeeting` | Opens `meetingLink` / teacher `externalMeetingUrl` in browser | Stable v1 primary |
| `mock` | `voiceCall`, `videoCall` | `MockSessionCallProvider` — placeholder UX, no real RTC | Staging / internal QA only |
| `livekit` | `voiceCall`, `videoCall` | `LiveKitCallProvider` + `issueSessionRtcToken` CF | Staging QA default |
| `agora` | `voiceCall`, `videoCall` | `AgoraCallProvider` + `issueSessionRtcToken` CF | Requires secrets + App ID in build |

**Resolution priority:** `livekit` → `agora` → `mock` (when client does not send `callProvider` hint). Legacy Firestore `webrtc` entries map to `livekit`.

---

## Staging LiveKit project (Tilawa / MeMuslim)

| Item | Value | Where it lives |
|------|-------|----------------|
| Project ID | `p_2n1vvcqjfqy` | LiveKit Cloud console only — **not** used at runtime for JWT minting |
| WebSocket URL | `wss://tilawa-7whzug8z.livekit.cloud` | Client: `kStagingLiveKitUrl` / `TILAWA_LAUNCH_LIVEKIT_URL`; CF secret `LIVEKIT_URL` |
| SIP URI | `sip:2n1vvcqjfqy.sip.livekit.cloud` | Out of scope for v1 Flutter app (telephony / PSTN bridge) |
| API Key | From LiveKit Cloud → Project → Settings → Keys | **Firebase secret `LIVEKIT_API_KEY` only** — never commit |
| API Secret | Same Keys page (shown once at creation) | **Firebase secret `LIVEKIT_API_SECRET` only** — never commit |

Local emulator template: `functions/.env.livekit.local.example` → copy to `.env.livekit.local` (gitignored).

---

## Dart-defines (`TILAWA_LAUNCH_*`)

Source: `AppLaunchConfig.fromEnvironment()`.

| Define | `play_production` default | Non-production default |
|--------|---------------------------|------------------------|
| `TILAWA_LAUNCH_ENABLED_CALL_PROVIDERS` | `external,mock` | `external,mock,livekit` |
| `TILAWA_LAUNCH_LIVEKIT_URL` | empty | empty (auto-filled in staging/debug — see below) |
| `TILAWA_LAUNCH_AGORA_APP_ID` | empty | empty (auto-filled in staging when `agora` enabled) |

### Staging / debug auto-inject

`resolveRtcLaunchConfig()` (`quran_sessions_launch_policy.dart`):

- When `distribution == staging` **or** `kDebugMode`: appends `livekit` to providers if neither `livekit` nor `agora` is listed
- When LiveKit is enabled and URL empty: uses `kStagingLiveKitUrl` (`wss://tilawa-7whzug8z.livekit.cloud`)
- When Agora is enabled and App ID empty: uses `kStagingAgoraAppId`

**Production release builds** do not auto-inject — ops must set defines explicitly for RTC.

---

## Firestore (`quran_session_platform_config/global`)

Field: `enabledCallProviders` — **array of strings**.

| If missing / null | Server defaults to `external` + `mock` (`FREE_BETA_PROVIDERS`) |
| If empty array | CF error `invalid_enabled_call_providers` |
| If `mock` omitted | Voice/video bookings resolve to next RTC provider or fail |

### Recommended per environment

| Environment | Firestore value | Client CSV | Notes |
|-------------|-----------------|------------|-------|
| Staging Free Beta | `["external","mock"]` | `external,mock` | B1 + B2 QA |
| Staging LiveKit QA | `["external","mock","livekit"]` | `external,mock,livekit` | URL auto-fills in staging/debug |
| Staging Agora QA | `["external","mock","agora"]` | `external,mock,agora` + App ID | Two-device Agora join |
| Play internal (stable) | `["external","mock"]` | `external,mock` | No RTC in prod binary path |
| Play production GA | `["external"]` | `external,mock` or `external` | Remove `mock` from Firestore to block server mock |
| Production RTC | `["external","livekit"]` or `["external","agora"]` | matching CSV + credentials | Remove `mock` from both sides |

---

## Client wiring (`QuranSessionsRtcModule`)

Registered only when launch config enables provider:

| Provider | DI registration |
|----------|-----------------|
| `livekit` | `LiveKitRoomPool`, `FirebaseCallTokenProvider` → `issueSessionRtcToken` |
| `agora` | `AgoraRtcEnginePool`, `FirebaseCallTokenProvider` → `issueSessionRtcToken` |
| `external` | `ExternalMeetingCallProvider` (always in router) |
| `mock` | `MockSessionCallProvider` (always in router) |

`RoutingSessionCallProvider` picks implementation by session's stored `callProvider`.

---

## Cloud Functions secrets (LiveKit)

Required for `issueSessionRtcToken` when session `callProvider` is `livekit`:

| Secret | Source |
|--------|--------|
| `LIVEKIT_API_KEY` | LiveKit Cloud → Project → Settings → Keys |
| `LIVEKIT_API_SECRET` | Same page — **required**; shown only once when the key is created |
| `LIVEKIT_URL` | `wss://tilawa-7whzug8z.livekit.cloud` (returned to client as `appId` in token response) |

Set interactively (values are **not** stored in the repo):

```sh
firebase functions:secrets:set LIVEKIT_API_KEY --project <project-id>
# paste API key when prompted

firebase functions:secrets:set LIVEKIT_API_SECRET --project <project-id>
# paste API secret when prompted (from LiveKit console — not the same as API key)

firebase functions:secrets:set LIVEKIT_URL --project <project-id>
# paste: wss://tilawa-7whzug8z.livekit.cloud
```

Deploy after secrets are set:

```sh
firebase deploy --only functions:issueSessionRtcToken,functions:issueDebugLiveKitToken --project <project-id>
```

`issueDebugLiveKitToken` is **debug/staging QA only** (Settings → QA Tools → Test LiveKit video call). A client `not-found` on that tile means this callable was never deployed — deploy it alongside `issueSessionRtcToken`.

Agora secrets (unchanged): `AGORA_APP_ID`, `AGORA_APP_CERTIFICATE`.

---

## Alignment checklist (do before LiveKit QA)

- [ ] Firestore `enabledCallProviders` includes `livekit`
- [ ] `LIVEKIT_API_KEY`, `LIVEKIT_API_SECRET`, and `LIVEKIT_URL` set in Firebase secrets
- [ ] `issueSessionRtcToken` deployed
- [ ] `issueDebugLiveKitToken` deployed (required for Settings → QA Tools LiveKit smoke test)
- [ ] **New booking** after config change (existing sessions keep old `callProvider`)
- [ ] Staging build uses `TILAWA_DISTRIBUTION=staging` (LiveKit URL auto-fills) or explicit `TILAWA_LAUNCH_LIVEKIT_URL`

---

## Example build / run commands

**Staging LiveKit QA** (URL auto-fills; override only if needed):

```sh
cd apps/tilawa
flutter run \
  --dart-define=TILAWA_DISTRIBUTION=staging \
  --dart-define=TILAWA_LAUNCH_QURAN_SESSIONS_BOOKING_ENABLED=true
```

Release APK:

```sh
flutter build apk --release \
  --dart-define=TILAWA_DISTRIBUTION=staging \
  --dart-define=TILAWA_LAUNCH_QURAN_SESSIONS_BOOKING_ENABLED=true \
  --dart-define=TILAWA_LAUNCH_ENABLED_CALL_PROVIDERS=external,mock,livekit
```

Explicit URL override (optional):

```sh
flutter build apk --release \
  --dart-define=TILAWA_DISTRIBUTION=staging \
  --dart-define=TILAWA_LAUNCH_QURAN_SESSIONS_BOOKING_ENABLED=true \
  --dart-define=TILAWA_LAUNCH_LIVEKIT_URL=wss://tilawa-7whzug8z.livekit.cloud
```

**Staging Agora:**

```sh
flutter build apk --release \
  --dart-define=TILAWA_DISTRIBUTION=staging \
  --dart-define=TILAWA_LAUNCH_QURAN_SESSIONS_BOOKING_ENABLED=true \
  --dart-define=TILAWA_LAUNCH_ENABLED_CALL_PROVIDERS=external,mock,agora \
  --dart-define=TILAWA_LAUNCH_AGORA_APP_ID=aacd48a930944ecea29bec112f229eb9
```

**Play production (booking off by default):**

```sh
flutter build appbundle --release \
  --dart-define=TILAWA_DISTRIBUTION=play_production
```
