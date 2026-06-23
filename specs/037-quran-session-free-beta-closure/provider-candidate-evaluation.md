# Provider Candidate Evaluation: Agora vs WebRTC

Companion to [individual-booking-provider-report.md](./individual-booking-provider-report.md).
Architecture references: `packages/quran_sessions/lib/src/boundaries/call/`,
[`docs/quran_sessions_group_sessions.md`](../../docs/quran_sessions_group_sessions.md),
[`functions/src/quranSessions/callProviderResolver.ts`](../../functions/src/quranSessions/callProviderResolver.ts).

**Scope:** Evaluate `agora_rtc_engine` **6.6.3** and `flutter_webrtc` **1.5.2** as
future implementations behind the existing `SessionCallProvider` boundary.
**No SDK integration in Free Beta** — stubs only (`AgoraCallProvider`,
`WebRtcCallProvider` throw `UnimplementedError`).

**Tilawa context:** Arabic-market, mobile-first Quran teaching; **1:1 individual**
bookings now; **group sessions** reserved in data model; teachers often on
mid-range Android devices; voice-first with optional video; external meeting
links acceptable during beta.

---

## Architecture alignment (current)

```
JoinSessionUseCase
  → SessionRepository (loads callProvider, providerSessionId, joinToken)
  → RoutingSessionCallProvider
       ├─ ExternalMeetingCallProvider   (external)
       ├─ MockSessionCallProvider       (mock — Free Beta voice/video)
       ├─ AgoraCallProvider?            (agora — stub, not registered)
       └─ WebRtcCallProvider?           (webrtc — stub, not registered)
```

**Rule (enforced):** Domain, use cases, and booking UI depend only on
`SessionCallProvider`, `SessionCallProviderKind`, and `CallJoinRequest`.
No Agora/WebRTC/`url_launcher` imports below `boundaries/call/`.

**Free Beta backend** (`callProviderResolver.ts`): only `external` and `mock`;
client hints `agora` / `webrtc` → `unsupported_call_provider`.
`joinToken` is always `null` for mock; field reserved for RTC.

**Gap (document, do not fix in this eval):** `AgoraCallProvider` and
`WebRtcCallProvider` implement legacy `CallProvider` (`joinSession(sessionId)`),
not `SessionCallProvider` (`join(CallJoinRequest)`). Production wiring should
add `SessionCallProvider` adapters (or refactor stubs) before SDK work.

---

## Gateway naming alignment

Codebase uses **Provider** in `packages/quran_sessions`; host app may use
**Gateway** for app-layer SDK wrappers. Intended mapping:

| Conceptual / host-app name | Package class (today) | `SessionCallProviderKind` | SDK dep | Free Beta |
|----------------------------|----------------------|---------------------------|---------|-----------|
| `ExternalMeetingSessionCallGateway` | `ExternalMeetingCallProvider` | `external` | None (`url_launcher` in app) | **Active** |
| `MockSessionCallGateway` | `MockSessionCallProvider` | `mock` | None | **Active** |
| `AgoraSessionCallGateway` | `AgoraCallProvider` (stub) | `agora` | `agora_rtc_engine` ^6.6.3 (app only) | Stub only |
| `WebRtcSessionCallGateway` | `WebRtcCallProvider` (stub) | `webrtc` | `flutter_webrtc` ^1.5.2 (app only) | Stub only |

**Recommended host-app layout (post–Free Beta):**

- Implement `AgoraSessionCallGateway` / `WebRtcSessionCallGateway` under
  `apps/tilawa/lib/features/quran_sessions/data/call/` (or `boundaries/call/`).
- Classes implement `SessionCallProvider`; register in
  `RoutingSessionCallProvider(agora: …, webrtc: …)` via DI modules.
- `CallTokenProvider` stays app-injected; tokens never minted in
  `packages/quran_sessions`.

---

## Comparison table (20 criteria)

| # | Criteria | Agora `agora_rtc_engine` 6.6.3 | WebRTC `flutter_webrtc` 1.5.2 | Notes |
|---|----------|----------------------------------|-------------------------------|-------|
| 1 | **Flutter support / stability** | Official Agora plugin; wraps Native SDK 4.x; 6.6.3 published Apr 2026; ~878 pub points; active GitHub (AgoraIO-Extensions). Web target alpha/incomplete. | Community plugin (flutter-webrtc org); 1.5.2 Jun 2026; broad platform matrix; frequent native bumps (libwebrtc m144). More integration variance across OEMs. | Tilawa targets **Android + iOS** only for v1 RTC — both viable on mobile. Agora more predictable for a small team. |
| 2 | **Android support** | First-class; documented permissions, ProGuard guidance. | Strong; requires `minSdk` ≥ 23, Java 8, ProGuard rules for release; recent fixes for Qualcomm/Hisi buffers, rotation, swipe-kill. | Arabic-market devices skew low/mid-tier Android — test matrix still required for either path. |
| 3 | **iOS support** | First-class; documented camera/mic privacy strings; release-mode symbol-stripping caveats in docs. | Strong; Podfile `ONLY_ACTIVE_ARCH` note for WebRTC.xframework; audio-session ownership hooks in recent releases. | Both need `NSCameraUsageDescription` / `NSMicrophoneUsageDescription` for video/voice. |
| 4 | **Audio calls** | Voice Calling SKU; AEC, AGC, ANS included in packages. | Full audio via `getUserMedia` + `RTCPeerConnection`; quality depends on app tuning. | Quran sessions are **voice-primary** — Agora’s bundled audio processing is a plus for echo-heavy phone speakers. |
| 5 | **Video calls** | Video SDK; resolution-tiered billing. | Video supported on Android/iOS; simulcast/unified-plan supported. | Video optional for beta pedagogy; both support teacher camera + student camera for 1:1. |
| 6 | **Permissions** | Runtime mic (voice) + camera (video); Android manifest + iOS Info.plist per Agora docs. | Same platform permissions; plugin does not grant them — app must request before `getUserMedia`. | Align with existing Tilawa permission patterns in app layer only. |
| 7 | **Token / channel security** | Channel name + short-lived **RTC token** (App ID + Certificate on server); role publisher/subscriber. | No built-in channel model — security = your signaling auth + TURN creds + room IDs. | Tilawa already models `providerSessionId` + `joinToken` server-issued — maps cleanly to Agora; WebRTC needs broader server design. |
| 8 | **Backend token generation** | Agora token builder (Node/Go/Java/etc.) or middleware `POST /token/getNew`; store App Certificate in Secret Manager. | Issue TURN credentials (e.g. coturn REST) + session/room JWT; no single vendor recipe. | **New Cloud Function(s)** required for either; Agora path is narrower and documented. |
| 9 | **Signaling requirements** | **Minimal** — Agora SD-RTN handles media path; app joins channel with token. | **Mandatory custom stack** — WebSocket/HTTP for SDP offer/answer, ICE candidates, reconnection. | WebRTC signaling is the largest hidden cost for Tilawa. |
| 10 | **Cost / pricing** | Free tier **10,000 standard minutes/month** (new projects from Aug 2025); audio ~$0.99/1k min; video tiers higher; cloud recording extra. | No per-minute vendor fee; pay for **TURN/SFU VMs**, bandwidth, ops. Can be cheaper at scale or more expensive if under-provisioned. | Free Beta volume fits Agora free minutes; model unit economics before group scale. |
| 11 | **Scalability 1:1** | Excellent; core product sweet spot. | Excellent for 1:1 mesh P2P; no SFU needed for two peers. | Current product scope — tie. |
| 12 | **Future group sessions** | Native multi-user channels; host/audience patterns; cloud proxy for restrictive networks (paid). | P2P does not scale to N-way; need **SFU** (LiveKit, mediasoup, Janus) + client work; `participants[]` UI. | [`docs/quran_sessions_group_sessions.md`](../../docs/quran_sessions_group_sessions.md) — Agora lower lift for teacher + many students. |
| 13 | **Implementation complexity** | **Low–medium:** engine init, join channel, token fetch, basic UI. | **High:** signaling server, peer lifecycle, reconnection, TURN, iOS/Android edge cases. | Matches stub comments: Agora V2, WebRTC V4 fallback. |
| 14 | **Low-end Android reliability** | Vendor-optimized stacks; used widely in emerging markets; adaptive bitrate built in. | Depends on P2P topology and device WebRTC build; more QA burden on fragmented OEMs. | Important for MENA student/teacher devices — favors Agora unless cost forces self-host. |
| 15 | **Network quality handling** | Built-in QoS, last-mile tuning, optional cloud proxy. | ICE/STUN/TURN + app logic; no vendor QoS layer. | Unstable mobile data common — Agora reduces bespoke networking code. |
| 16 | **Recording / moderation (future)** | Cloud Recording, content moderation APIs (add-on cost). | Roll your own or integrate third-party recorder; no turnkey in plugin. | Compliance/moderation for children's Quran teaching may matter later — Agora productized path exists. |
| 17 | **Maintenance risk** | Tied to Agora release cadence and breaking changes (6.x ↔ Native 4.x already happened). | Plugin + **your** signaling/TURN/SFU ops; libwebrtc version churn. | Smaller team → lower ops surface with Agora. |
| 18 | **Vendor lock-in** | **High** — channel APIs, tokens, console, pricing. | **Low** — standards-based; portable to other SFUs. | WebRTC is strategic escape hatch if Agora pricing or regional policy blocks. |
| 19 | **Migration difficulty** | Harder to leave Agora once in production (SDK + server tokens). | Easier to swap SFU/TURN; harder initial build. | Abstraction already isolates provider kind — migration is bounded to boundary + resolver. |
| 20 | **Free Beta vs Production suitability** | **Production RTC** candidate; **not** Free Beta (needs SDK, token CF, QA, store permissions). | Same — production option if lock-in/cost unacceptable; not beta-ready. | Free Beta: **external + mock** only (already shipped). |

---

## Recommendations (short technical)

### Better for Free Beta?

**Neither.** Ship **external meeting links** + **mock** in-app placeholder
(already wired). Validates booking, join flow, lifecycle, and teacher UX
without RTC cost, permissions friction, or token infrastructure.

### Better for Production (in-app voice/video)?

**Agora first** for Tilawa’s constraints: 1:1 voice-first, mobile-heavy Arabic
market, small engineering team, server-issued `joinToken` already modeled.
`flutter_webrtc` remains a **planned fallback** if unit economics or vendor
dependency becomes unacceptable — not the default path.

### Better for future group Quran sessions?

**Agora** — multi-participant channels and commercial SFU without operating
mediasoup/LiveKit. WebRTC-only group needs dedicated SFU infrastructure and
signaling redesign; see group doc `participants[]` + capacity.

### Start with external meeting links first?

**Yes.** Already supported (`ExternalMeetingCallProvider`, teacher
`externalMeetingUrl`, platform default). Lowest risk for Free Beta teachers who
already use Zoom/Google Meet/WhatsApp; zero SDK surface.

### Postpone Agora/WebRTC until after Free Beta?

**Yes.** Rationale:

1. Free Beta go/no-go already **No-Go** for in-app RTC (report §10).
2. `callProviderResolver` rejects client `agora`/`webrtc` hints.
3. Stubs intentionally throw — no `pubspec` SDK deps.
4. Token-issuing Cloud Function + call UI + device QA is a **separate milestone**.
5. Mock path proves `JoinSessionUseCase` end-to-end.

### Backend changes for Agora

| Area | Work |
|------|------|
| `callProviderResolver` | When `enabledCallProviders` includes `agora`, return `callProvider: "agora"`, `providerSessionId` = channel name (e.g. `sessionId`), `joinToken: null` at booking (token minted at join time) or short-lived token if policy requires. |
| New callable / HTTP | `issueAgoraRtcToken(sessionId, uid, role)` — Agora RTC token builder; secrets: App ID, App Certificate. |
| `createSessionBooking` | Allow `voiceCall`/`videoCall` → `agora` when platform config enables it; stop rejecting server-side agora once ready. |
| Firestore | Populate `joinToken` at join (or refresh via callable); never client-generated. |
| Platform config | `quran_session_platform_config.global.enabledCallProviders: ["external","mock","agora"]`. |
| Observability | Log channel join failures; alert on token errors. |

### Backend changes for WebRTC

| Area | Work |
|------|------|
| Signaling service | WebSocket (or Firebase RTDB) for SDP/ICE exchange per `sessionId` + `participants[]`. |
| TURN/STUN | Deploy coturn or managed TURN; issue time-limited credentials via Cloud Function. |
| `callProviderResolver` | Return `webrtc`, `providerSessionId` = room id, `joinToken` = TURN creds or signaling JWT. |
| SFU (group) | Required before group — not for 1:1 mesh only. |
| Ops | Monitor TURN relay bandwidth, signaling uptime, ICE failure rates. |

### Flutter permissions / config

| | Agora (`agora_rtc_engine` 6.6.3) | WebRTC (`flutter_webrtc` 1.5.2) |
|---|----------------------------------|----------------------------------|
| **Android manifest** | `RECORD_AUDIO`, `CAMERA`, `INTERNET`, `MODIFY_AUDIO_SETTINGS`, `BLUETOOTH_CONNECT` (as per Agora 4.x Android guide). | `RECORD_AUDIO`, `CAMERA`, `INTERNET`, `ACCESS_NETWORK_STATE`; `minSdkVersion` ≥ 23. |
| **Android build** | ProGuard keep rules per Agora docs for release. | ProGuard rules in plugin README; Java 8 `compileOptions`. |
| **iOS Info.plist** | `NSMicrophoneUsageDescription`, `NSCameraUsageDescription` (localized AR/EN). | Same privacy strings. |
| **iOS build** | Release symbol stripping workaround if calls fail in release. | `ONLY_ACTIVE_ARCH = YES` in Podfile per plugin note. |
| **Runtime** | Request permissions before `RtcEngine` join; handle denial → `QuranSessionsFailure` UI. | Request before `navigator.mediaDevices.getUserMedia` equivalent. |
| **Dependency location** | `apps/tilawa/pubspec.yaml` only — **not** `packages/quran_sessions`. | Same. |

---

## Final Go/No-Go: integrate either package now?

| Decision | **No-Go** for Free Beta |
|----------|-------------------------|
| **Why** | Product scope is external + mock; backend blocks RTC providers; stubs unregistered in DI; token CF missing; adds store review surface (mic/camera), binary size, and QA matrix without beta user value. |
| **When to revisit** | After Free Beta closure milestone: (1) token Cloud Function, (2) `SessionCallProvider` adapter for chosen SDK, (3) enable `agora` in platform config, (4) pilot on staging with real devices in target regions. |
| **Default production pick** | **Agora** unless a pricing/lock-in spike triggers WebRTC/SFU evaluation. |
| **Prerequisite fix** | Align `AgoraCallProvider` / `WebRtcCallProvider` with `SessionCallProvider` + `CallJoinRequest` before adding SDK deps. |

---

## References

- [agora_rtc_engine 6.6.3 on pub.dev](https://pub.dev/packages/agora_rtc_engine)
- [flutter_webrtc 1.5.2 on pub.dev](https://pub.dev/packages/flutter_webrtc)
- [Agora Voice Calling pricing](https://docs.agora.io/en/voice-calling/overview/pricing)
- [Agora token middleware](https://docs.agora.io/en/voice-calling/token-authentication/middleware-token-server)
