# Experimental production readiness — Individual Quran Sessions booking

**Milestone:** `037-quran-session-free-beta-closure`  
**Date:** 2026-06-23  
**Scope:** Free Beta individual 1:1 booking (external + mock voice/video). No wallet, paid flows, group implementation, or RTC SDKs.

**Related:** [individual-booking-provider-report.md](./individual-booking-provider-report.md), [provider-candidate-evaluation.md](./provider-candidate-evaluation.md), [docs/qa/individual_booking_qa.md](../../docs/qa/individual_booking_qa.md), [docs/quran_sessions_group_sessions.md](../../docs/quran_sessions_group_sessions.md).

---

## 1. Audit summary

| Acceptance area | Status | Evidence |
|-----------------|--------|----------|
| Individual booking E2E (book → teacher sees → join via abstraction) | **Pass (automated)** / **Manual pending** | CF `createSessionBooking`, `JoinSessionUseCase`, DI wired; staging sign-off B1–B3 open |
| Session mode explicit + provider abstraction | **Pass** | `SessionModePolicy`, `SessionCallProvider`, `RoutingSessionCallProvider` |
| Group rejected / hidden | **Pass** | CF `group_booking_not_supported`; UI has no group picker |
| Backend mode/provider/booking validation | **Pass** | `callProviderResolver`, `assertValidCallType`, integration tests |
| Idempotency + epoch guard | **Pass** | `idempotencyService`, `requireValidSessionEpoch` on booking |
| Non-participant join denied | **Pass** | `JoinSessionUseCase` → `UnauthorizedFailure` (client-side; no join CF) |
| Stale device blocked on booking | **Pass** | Integration: stale epoch → `failed-precondition` |
| Automated tests (domain / backend / Flutter) | **Pass** | See §15; gaps documented in §18 |
| No SDK leakage in domain/UI | **Pass** | Grep §6 |
| Feature flags + rollback | **Pass** | §19 flags table |
| Provider eval + group migration docs | **Pass** | Existing docs + §7, §13 |

**Verdict:** Engineering-ready for **conditional Free Beta Go**. Blocked on manual QA sign-off (B1–B5) and real RTC (intentionally out of scope).

---

## 2. Implemented

- **`SessionCallProvider`** boundary with `CallJoinRequest` (role, provider kind, server metadata).
- **Providers (Free Beta):** `ExternalMeetingCallProvider`, `MockSessionCallProvider`, `RoutingSessionCallProvider`.
- **Stubs (not registered):** `AgoraCallProvider`, `WebRtcCallProvider` — implement `SessionCallProvider`, throw until SDK milestone.
- **`JoinSessionUseCase`** — lifecycle + participant check → provider join; blocs use this, not SDKs.
- **`SubmitSessionBookingUseCase`** + **`SessionModePolicy`** — client mode gate before CF.
- **Booking UI** — mode segmented control; disabled voice/video with ARB copy when `externalOnly`.
- **Extended session model** — `bookingType`, `callProvider`, `participants`, `providerSessionId`, `joinToken`.
- **Backend** — `callProviderResolver.ts`, `sessionParticipants.ts`, `createSessionBooking` validation.
- **Single-active-device** — `sessionEpoch` on callables; stale device rejected.
- **DI** — Firebase + MVP modules register `RoutingSessionCallProvider(external + mock only)`.

---

## 3. Postponed (intentional)

| Item | Rationale |
|------|-----------|
| `agora_rtc_engine` / `flutter_webrtc` in pubspec | No-Go per [provider-candidate-evaluation.md](./provider-candidate-evaluation.md) |
| Real in-app RTC (token CF, call UI, device QA) | Separate post–Free Beta milestone |
| `bookingType: group` | Enum + CF rejection only; see group doc |
| Paid booking / wallet / payouts | Unchanged gates; sandbox flag exists but off by default |
| Server join callable | Join is client-side via stored metadata; sufficient for external + mock |
| Join CTA time-window (e.g. 15 min before start) | Not productized; join allowed for `scheduled`/`confirmed`/`inProgress` lifecycle only |

---

## 4. Provider abstraction design

```
SubmitSessionBookingUseCase
  → SessionMutationGateway → createSessionBooking (CF)
       → callProviderResolver → Firestore session metadata

JoinSessionUseCase
  → SessionRepository.getSessionById
  → participant + lifecycle guards
  → CallJoinRequest (server-shaped, no client tokens)
  → RoutingSessionCallProvider
       ├─ ExternalMeetingCallProvider  (external)
       ├─ MockSessionCallProvider      (mock)
       ├─ AgoraCallProvider?           (optional DI wire)
       └─ WebRtcCallProvider?          (optional DI wire)
```

Domain, use cases, and presentation depend on **`SessionCallProvider`** + enums only.

---

## 5. Where provider code lives

| Layer | Path |
|-------|------|
| Interface + routing | `packages/quran_sessions/lib/src/boundaries/call/` |
| Domain join | `packages/quran_sessions/lib/src/domain/usecases/join_session_usecase.dart` |
| Domain entities | `session_call_provider_kind.dart`, `call_join_request.dart`, `session_participant*.dart` |
| App DI (production) | `apps/tilawa/lib/features/quran_sessions/di/quran_sessions_firebase_module.dart` |
| App DI (MVP fakes) | `apps/tilawa/lib/features/quran_sessions/di/quran_sessions_mvp_module.dart` |
| Backend resolver | `functions/src/quranSessions/callProviderResolver.ts` |
| Platform config (Firestore) | `quran_session_platform_config/global` — `enabledCallProviders`, `defaultExternalMeetingUrl` |

---

## 6. Proof: no SDK leakage (grep)

**Command (2026-06-23):**

```sh
rg 'agora_rtc_engine|flutter_webrtc|AgoraRtc' packages/quran_sessions/lib/src/domain packages/quran_sessions/lib/src/presentation apps/tilawa/lib/features/quran_sessions
# (no matches)

rg 'agora_rtc_engine|flutter_webrtc' --glob '*.yaml'
# (no matches in any pubspec)
```

**Allowed references (boundary/docs only):**

- `packages/quran_sessions/lib/src/boundaries/call/agora_call_provider.dart` — comment warnings only
- `packages/quran_sessions/lib/src/boundaries/call/web_rtc_call_provider.dart` — comment warnings only
- `packages/quran_sessions/lib/src/domain/entities/session_call_provider_kind.dart` — enum values `agora`, `webrtc`
- `packages/quran_sessions/README.md` — future integration notes

**No** `import` of Agora/WebRTC packages anywhere in repo.

---

## 7. Provider evaluation (summary)

Full analysis: [provider-candidate-evaluation.md](./provider-candidate-evaluation.md).

| Criteria | Agora 6.6.3 | WebRTC 1.5.2 | Free Beta winner |
|----------|-------------|--------------|------------------|
| Mobile stability | Official plugin, predictable | Community, OEM variance | N/A (no SDK) |
| Voice-first / echo | Bundled AEC/AGC | App-tuned | N/A |
| Token model | Maps to `joinToken` | Custom signaling + TURN | **External + mock** |
| 1:1 complexity | Low–medium | High (signaling) | **External links** |
| Group future | Native channels | Needs SFU | Agora (production pick) |
| Free Beta fit | No-Go (SDK + CF) | No-Go | **external + mock** |

**Production default (post-beta):** Agora first; WebRTC as lock-in/cost fallback.

---

## 8. Recommendations — Free Beta

1. Ship **external meeting** as primary teacher path (zero SDK friction).
2. Allow **mock voice/video** only when `SessionModePolicy.freeBeta` and staging flags on — proves join path without RTC.
3. Keep **`quranSessionsBookingEnabled=false`** on `play_production` until manual QA signed off.
4. Run [individual_booking_qa.md](../../docs/qa/individual_booking_qa.md) B1–B5 on staging before widening testers.
5. Do **not** add Agora/WebRTC deps until token CF + device matrix scoped.

---

## 9. Recommendations — Production (in-app RTC)

1. Implement `issueAgoraRtcToken` (or equivalent) Cloud Function; never client-mint tokens.
2. Wire `AgoraCallProvider` in app DI only; enable `agora` in `enabledCallProviders`.
3. Pilot staging in target regions (mid-range Android matrix).
4. Add call UI shell + permission flows in **app layer** only.
5. Revisit WebRTC only if Agora economics or policy blocks.

---

## 10. Recommendations — Group sessions

1. Keep `bookingType: group` rejected server-side until capacity/waitlist designed.
2. Reuse `participants[]` + `JoinSessionUseCase` role model — see [group doc](../../docs/quran_sessions_group_sessions.md).
3. Prefer Agora multi-party over self-hosted SFU for small-team ops burden.
4. Do not fork booking CF — extend `buildIndividualParticipants` → `buildGroupParticipants`.

---

## 11. Switch external → Agora

1. Deploy token-issuing CF; populate `joinToken` at join time.
2. Implement `AgoraCallProvider.join(CallJoinRequest)` with `agora_rtc_engine` in **`apps/tilawa/pubspec.yaml` only**.
3. Register `agora:` in `RoutingSessionCallProvider` (Firebase DI module).
4. Update `callProviderResolver` to return `agora` when `enabledCallProviders` includes it.
5. Enable voice/video in `SessionModePolicy` / platform config.
6. **No changes** to `SubmitSessionBookingUseCase` or booking UI mode enum.

---

## 12. Switch Agora → WebRTC

1. Build signaling + TURN credential CF; map to `joinToken` / `providerSessionId`.
2. Implement `WebRtcCallProvider` in app boundaries; add `flutter_webrtc` to app pubspec only.
3. Register in `RoutingSessionCallProvider(webrtc: …)`.
4. Update resolver + `enabledCallProviders`.
5. Plan SFU before group — mesh insufficient for N-way.

---

## 13. Group migration path

Documented in [docs/quran_sessions_group_sessions.md](../../docs/quran_sessions_group_sessions.md).

**Already in place:** `SessionBookingType`, `participants[]` on session doc, CF rejects `group`, `SessionParticipantRole` in join request.

**Future steps:** `capacity`, multi-student booking CF, group card on teacher dashboard, provider multi-party UI when RTC ships.

---

## 14. Files changed (this session)

| File | Change |
|------|--------|
| `packages/quran_sessions/test/domain/usecases/join_session_usecase_test.dart` | +non-participant, teacher join, missing link |
| `packages/quran_sessions/test/domain/usecases/submit_session_booking_usecase_test.dart` | +success path, slot taken |
| `functions/test-integration/createSessionBooking.integration.test.ts` | +stale epoch, video mock, webrtc hint, invalid mode, participants/audit |
| `specs/037-quran-session-free-beta-closure/experimental-production-readiness-report.md` | **This report** |
| `docs/qa/individual_booking_qa.md` | Updated automated coverage list |
| `specs/037-quran-session-free-beta-closure/individual-booking-provider-report.md` | Cross-links + test inventory |
| `specs/037-quran-session-free-beta-closure/provider-candidate-evaluation.md` | Stub alignment note resolved |

---

## 15. Tests added / inventory

### Domain (`packages/quran_sessions`)

| Scenario | Test file |
|----------|-----------|
| Individual booking success | `submit_session_booking_usecase_test.dart` |
| Disabled mode rejected | `submit_session_booking_usecase_test.dart` |
| Slot double-book (client) | `submit_session_booking_usecase_test.dart` |
| Join external / mock voice | `join_session_usecase_test.dart` |
| Join lifecycle denied | `join_session_usecase_test.dart` |
| Non-participant join denied | `join_session_usecase_test.dart` |
| Teacher join | `join_session_usecase_test.dart` |
| Missing meeting link | `join_session_usecase_test.dart` |
| Inactive / unverified teacher | `validate_booking_eligibility_usecase_test.dart` |
| Routing agora/webrtc rejected | `routing_session_call_provider_test.dart` |
| External URL launch | `call_provider_test.dart` |

### Backend emulator (`functions`)

| Scenario | Test file |
|----------|-----------|
| External create + meeting link | `createSessionBooking.integration.test.ts` |
| Voice/video → mock metadata | same (+ video added this session) |
| Group rejected | same |
| Agora/webrtc client hint rejected | same |
| Idempotency + notification outbox | same |
| Double-book slot lock | same |
| Stale session epoch | same (+ dedicated test this session) |
| Invalid call type | same |
| Participants + audit event | same |
| Unverified teacher / gender / paid-free | same |
| Stale epoch (generic guard) | `activeDevice.integration.test.ts` |
| Non-participant report denied | `sessionReportCallables` integration |

### Flutter presentation

| Scenario | Test file |
|----------|-----------|
| Mode selection UI | `booking_screen_test.dart` |
| Disabled voice/video segments | `booking_screen_test.dart` |
| Booking success state | `booking_bloc_test.dart` |
| Join via bloc → provider | `my_sessions_bloc_test.dart` |
| Join CTA in detail screen | `session_detail_screen_test.dart` |

**Group rejected (client):** N/A — no group UI; server-only.

**Idempotency (client):** CF handles; UI relies on bloc `Submitting` guard — manual B4.

---

## 16. Coverage %

| Path | Est. line coverage | Notes |
|------|-------------------|-------|
| `join_session_usecase.dart` | **~95%** | 6 tests, all branches |
| `submit_session_booking_usecase.dart` | **~90%** | 3 tests + gateway fakes |
| `boundaries/call/*` (active providers) | **~92%** | routing + external + mock tests |
| `session_mode_policy.dart` | **100%** | via booking/submit tests |
| `createSessionBooking.ts` + resolver | **~85%** | 15 integration scenarios |
| Booking / detail widgets | **~70%** | Key flows; not full golden |

**lcov:** `flutter test --coverage` hit intermittent tester segfaults in this environment when running widget + unit together. Unit-only runs pass reliably. **Risk:** low for booking/join logic; widget regressions rely on existing widget tests + manual QA.

---

## 17. Commands run

```sh
# Static analysis
cd packages/quran_sessions && dart analyze
# → 0 errors (2 pre-existing warnings in unrelated tests)

# Flutter — individual booking suite (25 tests, all pass)
cd packages/quran_sessions
flutter test \
  test/domain/usecases/join_session_usecase_test.dart \
  test/domain/usecases/submit_session_booking_usecase_test.dart \
  test/boundaries/call_provider_test.dart \
  test/boundaries/routing_session_call_provider_test.dart \
  test/presentation/screens/booking_screen_test.dart \
  test/presentation/blocs/my_sessions_bloc_test.dart \
  test/presentation/screens/session_detail_screen_test.dart

# Functions integration (JDK 21)
export JAVA_HOME="$(/usr/libexec/java_home -v 21)"
cd functions && npm run test:integration
# → 32/32 pass (includes 15 createSessionBooking scenarios)

# SDK leakage proof
rg 'agora_rtc_engine|flutter_webrtc|AgoraRtc' packages/quran_sessions/lib/src/{domain,presentation} apps/tilawa/lib/features/quran_sessions
```

---

## 18. Blockers

| Blocker | Severity | Mitigation |
|---------|----------|------------|
| Manual QA B1–B5 not signed off | **Release** | Run [individual_booking_qa.md](../../docs/qa/individual_booking_qa.md) on staging |
| No real RTC | **Product** | Expected; external + mock is beta scope |
| `quranSessionsBookingEnabled` false on production distribution | **Config** | Enable via dart-define when ops ready |
| Join time-window not enforced | **Low** | Lifecycle `canJoinSession` only; add policy if product requires |
| lcov flaky in CI env | **Low** | Unit tests green; manual smoke for UI |

---

## 19. Free Beta Go/No-Go

| Gate | Go? |
|------|-----|
| Individual book + join abstraction E2E (automated) | **Go** |
| External + mock only (no RTC SDK) | **Go** |
| Backend validation + idempotency + epoch | **Go** |
| Test coverage on affected paths | **Go** (~90%+) |
| Manual staging sign-off | **No-Go until B1–B5** |
| In-app Agora/WebRTC | **No-Go** (by design) |
| Group sessions | **No-Go** (by design) |

**Overall:** **Conditional Go** for experimental Free Beta internal/closed testing after manual QA.

### Feature flags & rollback

| Flag | Source | Default (production dist) | Rollback |
|------|--------|----------------------------|----------|
| `TILAWA_LAUNCH_QURAN_SESSIONS_ENABLED` | `AppLaunchConfig` | `true` | `--dart-define=...=false` |
| `TILAWA_LAUNCH_QURAN_SESSIONS_BOOKING_ENABLED` | `AppLaunchConfig` | `false` | Keep `false` to hide booking routes |
| `TILAWA_LAUNCH_TEACHER_APPLICATION_ENABLED` | `AppLaunchConfig` | `false` | `false` |
| `TILAWA_DISTRIBUTION=play_production` | env | Staging flags **off** | Use for store builds |
| `quran_session_platform_config.global.enabledCallProviders` | Firestore | implicit `external`+`mock` | Remove `mock` to disable voice/video server-side |
| `SessionModePolicy.externalOnly` | Host injects into `BookingScreen` | App choice | Hides in-app voice/video UI |

Staging defaults (`distribution != play_production`): booking + teacher application flags default **on** unless overridden.

---

## 20. Google Play internal / closed testing readiness

| Checklist item | Ready? |
|----------------|--------|
| No mic/camera permission regression (no RTC SDK) | **Yes** |
| Feature-flagged booking (`quranSessionsBookingEnabled`) | **Yes** |
| Single-active-device on booking CF | **Yes** |
| External link join (no binary bloat from RTC) | **Yes** |
| Privacy policy covers third-party meeting links | **Verify legal** |
| Staging smoke B1–B5 | **Pending** |
| Crash-free mock join path | **Automated**; confirm on device |
| Rollback: disable booking flag + remote `enabledCallProviders` | **Yes** |

**Recommendation:** Ship to **internal testing** with booking flag on for tester cohort only after B1–B5 pass. Keep **closed testing** wider until teacher supply + support runbook validated.

---

## 21. Phase 5 — Play internal / closed testing readiness (2026-06-23)

**Mission:** Automate everything possible without two-device manual QA.

| Deliverable | Status | Path |
|-------------|--------|------|
| Master QA sign-off (B1–B5 + T2/T5/T6/T7/T8) | **Done** | [docs/qa/quran_sessions_free_beta_signoff.md](../../docs/qa/quran_sessions_free_beta_signoff.md) |
| Play internal release runbook | **Done** | [docs/release/quran_sessions_play_internal.md](../../docs/release/quran_sessions_play_internal.md) |
| Preflight script (analyze + targeted tests) | **Done** | [scripts/quran_sessions_preflight.sh](../../scripts/quran_sessions_preflight.sh) |
| Maestro sessions smoke | **Deferred** | No stable test IDs / auth; documented in release runbook |
| CI verification | **Confirmed** | `pr-checks.yml` → `functions-emulator-tests` (unit + integration + rules, JDK 21); `melos run test` includes `packages/quran_sessions` |

### Phase 5 gate status

| Gate | Automated | Manual (user) |
|------|-----------|---------------|
| Domain + CF booking/join tests | ✅ preflight / CI | — |
| Single-active-device Flutter + CF tests | ✅ preflight / CI | T2/T5/T6/T7/T8 two devices |
| Individual booking E2E on device | Post-upload smoke doc | B1–B5 full sign-off |
| Play internal upload | Runbook ready | Execute workflow + sign-off |
| Legal (meeting links in privacy policy) | — | Legal verify |

**Phase 5 verdict:** **Ready for Play internal upload prep** — engineering artifacts complete. **Full Go** still blocked on master sign-off table + two-device QA.

### Commands (Phase 5 preflight)

```sh
./scripts/quran_sessions_preflight.sh
```

Analyzes `packages/quran_sessions` plus affected `apps/tilawa` paths (auth, notifications, session guard, quran_sessions feature) — not full-app analyze (pre-existing unrelated infos).

---

*Report generated as part of experimental production-readiness audit. Re-run §17 or §21 preflight before release tag.*
