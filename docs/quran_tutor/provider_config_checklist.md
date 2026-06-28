# QuranTutor — Voice / video provider configuration checklist

**Authority:** Server locks `callProvider` at booking (`functions/src/quranSessions/callProviderResolver.ts`). Client dart-defines control which SDKs are **registered** and UI hints only.

Cross-ref: [production_config.md](./production_config.md) · [ops_qa_runbook.md](./ops_qa_runbook.md) §3.

---

## Provider types

| Provider | Booking `callType` | Join path | Production notes |
|----------|-------------------|-----------|------------------|
| `external` | `externalMeeting` | Opens `meetingLink` / teacher `externalMeetingUrl` in browser | Stable v1 primary |
| `mock` | `voiceCall`, `videoCall` | `MockSessionCallProvider` — placeholder UX, no real RTC | Staging / internal QA only |
| `agora` | `voiceCall`, `videoCall` | `AgoraCallProvider` + `issueSessionRtcToken` CF | Requires secrets + App ID in build |
| `webrtc` | `voiceCall`, `videoCall` | `WebRtcCallProvider` + signaling URL | Requires `TILAWA_LAUNCH_WEBRTC_SIGNALING_URL` |

**Resolution priority:** `agora` → `webrtc` → `mock` (when client does not send `callProvider` hint).

---

## Dart-defines (`TILAWA_LAUNCH_*`)

Source: `AppLaunchConfig.fromEnvironment()`.

| Define | `play_production` default | Non-production default |
|--------|---------------------------|------------------------|
| `TILAWA_LAUNCH_ENABLED_CALL_PROVIDERS` | `external,mock` | `external,mock,agora` |
| `TILAWA_LAUNCH_AGORA_APP_ID` | empty | empty (auto-filled in staging/debug — see below) |
| `TILAWA_LAUNCH_WEBRTC_SIGNALING_URL` | empty | empty |

### Staging / debug auto-inject

`resolveRtcLaunchConfig()` (`quran_sessions_launch_policy.dart`):

- When `distribution == staging` **or** `kDebugMode`: appends `agora` to providers if missing
- When Agora App ID empty: uses `kStagingAgoraAppId` (`aacd48a930944ecea29bec112f229eb9`)

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
| Staging Agora QA | `["external","mock","agora"]` | `external,mock,agora` + App ID | Two-device Agora join |
| Play internal (stable) | `["external","mock"]` | `external,mock` | No Agora in prod binary path |
| Play production GA | `["external"]` | `external,mock` or `external` | Remove `mock` from Firestore to block server mock |
| Production RTC | `["external","agora"]` | `external,agora` + App ID | Remove `mock` from both sides |

---

## Client wiring (`QuranSessionsRtcModule`)

Registered only when launch config enables provider:

| Provider | DI registration |
|----------|-----------------|
| `agora` | `AgoraRtcEnginePool`, `FirebaseCallTokenProvider` → `issueSessionRtcToken` |
| `webrtc` | `WebRtcCallProvider` with signaling URL |
| `external` | `ExternalMeetingCallProvider` (always in router) |
| `mock` | `MockSessionCallProvider` (always in router) |

`RoutingSessionCallProvider` picks implementation by session's stored `callProvider`.

---

## UI booking policy

`sessionModePolicyFromLaunchConfig` → `SessionModePolicy.voiceVideoUseMockProvider`:

- `true` when client hint is `mock` (no Agora + no WebRTC URL on prod build)
- Booking screen shows voice/video segments when `SessionModePolicy.freeBeta` and types enabled

`SessionModePolicy.externalOnly` hides voice/video when teacher has no external URL policy applied.

---

## Cloud Functions secrets

| Secret | Used by |
|--------|---------|
| `AGORA_APP_ID` | `issueSessionRtcToken` |
| `AGORA_APP_CERTIFICATE` | Token minting |

Set:

```sh
firebase functions:secrets:set AGORA_APP_ID AGORA_APP_CERTIFICATE --project <project-id>
```

Deploy:

```sh
firebase deploy --only functions:issueSessionRtcToken --project <project-id>
```

---

## Alignment checklist (do before RTC QA)

- [ ] Firestore `enabledCallProviders` includes intended RTC provider
- [ ] Release APK built with matching `TILAWA_LAUNCH_ENABLED_CALL_PROVIDERS`
- [ ] `TILAWA_LAUNCH_AGORA_APP_ID` set for production Agora (staging ID only for staging)
- [ ] CF secrets deployed; `issueSessionRtcToken` callable live
- [ ] **New booking** after config change (existing sessions keep old `callProvider`)
- [ ] Cancel mock-only sessions when switching staging → Agora path

---

## Missing config — expected failures

| Misconfiguration | Failure mode |
|------------------|--------------|
| Book voice/video, Firestore has only `external` | `unsupported_call_provider` from CF |
| Session `callProvider: agora`, client lacks Agora in defines / empty App ID | Join fails; may fall back to mock hint on UI only — join still calls Agora path |
| Agora session, secrets missing | `issueSessionRtcToken` error at join |
| `webrtc` in Firestore, empty signaling URL | WebRTC provider not constructed; booking may still pick `webrtc` server-side → join broken |
| Prod Firestore still has `mock`, ops thinks RTC live | Students get mock sessions — **mock leak** |

---

## Mock leak prevention (release)

1. Remove `mock` from Firestore `enabledCallProviders` for production wide release
2. Ship `play_production` with `external` only (or `external,agora` when RTC ready)
3. Do not set `TILAWA_QURAN_SESSIONS_BACKEND=fake` on shipped builds
4. Verify sample session doc after test booking: `callProvider` matches intent

---

## Example release build commands

**Staging Free Beta (external + mock):**

```sh
cd apps/tilawa
flutter build apk --release \
  --dart-define=TILAWA_DISTRIBUTION=staging \
  --dart-define=TILAWA_LAUNCH_QURAN_SESSIONS_BOOKING_ENABLED=true \
  --dart-define=TILAWA_LAUNCH_ENABLED_CALL_PROVIDERS=external,mock
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
# Booking: add --dart-define=TILAWA_LAUNCH_QURAN_SESSIONS_BOOKING_ENABLED=true when ops ready
```
