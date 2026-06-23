# Individual booking + SessionCallProvider — delivery report

See also [group sessions conceptual model](../../docs/quran_sessions_group_sessions.md) and
[Provider Candidate Evaluation: Agora vs WebRTC](./provider-candidate-evaluation.md).

## 1. Implemented

- `SessionCallProvider` boundary with `CallJoinRequest` (role, provider kind, server metadata)
- `RoutingSessionCallProvider` + `MockSessionCallProvider` + `ExternalMeetingCallProvider`
- `JoinSessionUseCase` — domain join path; blocs no longer call SDKs directly
- `SessionModePolicy` + booking UI mode picker with beta/disabled copy (ARB)
- Extended `QuranSession` / Firestore mapping: `bookingType`, `callProvider`, `participants`, `providerSessionId`, `joinToken`
- Backend `callProviderResolver` + `createSessionBooking` validation (individual only, mock for voice/video, reject agora/webrtc client hints)
- DI wired in Firebase + MVP modules

## 2. Postponed intentionally

- Agora / WebRTC SDK integration — stubs implement `SessionCallProvider` but throw `UnimplementedError`; not registered in DI for Free Beta
- Group booking implementation (`bookingType: group` rejected server-side)
- Paid sessions, wallet, payouts (unchanged; still gated)
- Server-issued join tokens for real RTC (field reserved; null in Free Beta mock)

## 3. Provider abstraction

```
JoinSessionUseCase
  → SessionRepository (session metadata)
  → RoutingSessionCallProvider
       ├─ ExternalMeetingCallProvider (joinUrl)
       ├─ MockSessionCallProvider (voice/video Free Beta)
       ├─ AgoraCallProvider (future, optional in router)
       └─ WebRtcCallProvider (future, optional in router)
```

Domain/booking code depends only on `SessionCallProvider` + enums.

## 4. Switch WebRTC ↔ Agora later

1. Implement `AgoraCallProvider` / `WebRtcCallProvider` as `SessionCallProvider`.
2. Register in `RoutingSessionCallProvider(agora: …, webrtc: …)`.
3. Enable provider in `quran_session_platform_config.global.enabledCallProviders`.
4. Backend `callProviderResolver` returns `agora` or `webrtc` + server `joinToken`.
5. No changes to `SubmitSessionBookingUseCase`, lifecycle, or dashboards.

## 5. Group sessions (conceptual)

`participants[]` on session doc; `SessionBookingType.group` enum reserved.
See `docs/quran_sessions_group_sessions.md`.

## 6. Files changed (main)

**packages/quran_sessions/** — entities, boundaries, use cases, booking UI, tests  
**apps/tilawa/** — Firestore mapper, mutation gateway, DI  
**functions/** — `callProviderResolver.ts`, `sessionParticipants.ts`, `createSessionBooking.ts`  
**docs/** — `quran_sessions_group_sessions.md`

## 7. Tests added

- `test/domain/usecases/join_session_usecase_test.dart`
- `test/domain/usecases/submit_session_booking_usecase_test.dart`
- `test/boundaries/routing_session_call_provider_test.dart` — agora/webrtc rejected when not wired
- Updated `my_sessions_bloc_test.dart` join path
- Functions integration: voice/mock metadata, group rejected, agora hint rejected

## 7b. Manual QA runbook

Staging smoke steps: [docs/qa/individual_booking_qa.md](../../docs/qa/individual_booking_qa.md)

## 8. Coverage

Run from repo:

```sh
cd packages/quran_sessions && dart analyze && flutter test test/domain/usecases/join_session_usecase_test.dart test/domain/usecases/submit_session_booking_usecase_test.dart test/presentation/blocs/my_sessions_bloc_test.dart test/boundaries/call_provider_test.dart test/boundaries/routing_session_call_provider_test.dart
cd functions && npm test -- test-integration/createSessionBooking.integration.test.ts
```

Target: 90%+ on touched Dart paths after full suite + `dart run coverage` if required.

## 9. Blockers

- Real RTC needs token-issuing Cloud Function + SDK deps (out of Free Beta scope)
- `TilawaSegmentedControl` has no per-segment disabled state — disabled modes omitted from control when `SessionModePolicy.externalOnly`
- **Stub alignment (2026-06-23):** `AgoraCallProvider` / `WebRtcCallProvider` now implement `SessionCallProvider`; `RoutingSessionCallProvider` rejects agora/webrtc unless explicitly wired (no mock fallback)

## 10. Free Beta Go/No-Go — individual booking

**Go** for external + mock voice/video placeholder path, with existing eligibility, idempotency, epoch guard, and join abstraction wired end-to-end.

**No-Go** for in-app Agora/WebRTC and group sessions until follow-up milestones.
See [provider-candidate-evaluation.md](./provider-candidate-evaluation.md) for the
full Agora vs WebRTC comparison and integration gate.
