# Final Report — Quran Sessions Stable Production v1

**Date:** 2026-06-24  
**Verdict:** **Conditional Go** (staging / closed testing)  
**Engineering status:** Stable-scope implementation complete; App Check **staged in code** (ops flip pending); manual E2E + legal remain release gates.

---

## Executive summary

Stable-scope Quran Sessions flows are **implemented end-to-end** in app, package, Cloud Functions, Firestore rules, and admin panel. Spec 038 P0 code fixes (teacher CF auth, eligibility immutability, kill switch) were already landed; this pass **closed P1 test gaps** (SessionDetailBloc join/report/dispute, rules write-denial) and fixed a **stale unit test** in `session_mode_policy_test.dart`.

**Not done (explicit):** manual B1–B5 / T2–T8 sign-off, **ops App Check enforcement flip** on staging/prod, legal privacy verify for external meeting links, Maestro E2E, admin dispute resolve UI (post-v1 by design).

---

## What was implemented / fixed (038 closure pass)

| Area | Change |
|------|--------|
| Session detail bloc tests | Join success/failure, report submit, dispute → `disputed` lifecycle |
| Firestore rules tests | Client write denied on `quran_bookings`, `quran_sessions`, `quran_session_events` |
| Session mode policy test | Aligned with `external_meeting_url_policy_test` (freeBeta fallback, not externalOnly) |
| Prior 038 P0 (branch) | Teacher CF auth, eligibility rules, kill switch, report auth |

No new product TODOs in `apps/tilawa/lib/features/quran_sessions/` or `packages/quran_sessions/lib/`.

---

## Postponed (honest, out of stable scope)

| Item | Reason |
|------|--------|
| Paid / wallet checkout / payouts | Explicit out of scope |
| Group sessions | CF rejects; no UI |
| Agora RTC (in-app voice/video) | **Implemented (flag-gated)** — staging E2E + Play gates remain |
| WebRTC signaling | Stub throws; signaling/TURN CF postponed |
| Bilateral mode/provider change | Spec 037 policy — Option A lock only |
| Mobile reschedule confirm | Admin confirms via request ID |
| Mobile teacher mark no-show | Admin / CF only |
| Admin dispute resolve UI | Read-only triage; resolve via session detail CF |
| App Check on session CFs | **Staged (Phase 4)** — env gate; ops flip pending |
| Maestro book→join E2E | P1 |
| Experimental home badge removal | P2 UX polish |
| Cryptographic single-device epoch | Documented limitation (~1h token window) |

---

## Required test matrix (20 scenarios)

| # | Scenario | Status | Primary evidence |
|---|----------|--------|------------------|
| 1 | Teacher approved → dashboard | ✅ | `teacher_capability_presentation_test.dart` |
| 2 | Approved incomplete → complete profile | ✅ | `teacher_capability_presentation_test.dart` |
| 3 | Suspended → dashboard blocked | ✅ | `teacher_capability_presentation_test.dart` |
| 4 | Teacher sets availability | ✅ | `availability_cubit_test.dart`, `teacher_dashboard_bloc_test.dart` |
| 5 | Student sees approved/public teachers only | ✅ | `firestore_teacher_repository_test.dart` |
| 6 | Student books free individual session | ✅ | `createSessionBooking.integration.test.ts`, booking bloc/screen |
| 7 | Duplicate booking blocked / idempotent | ✅ | Integration: double-book + idempotency key |
| 8 | Stale device cannot book/join | ✅ | `activeDevice.integration.test.ts`, session guard tests |
| 9 | Student sees session details | ✅ | `session_detail_screen_test.dart`, bloc load tests |
| 10 | Teacher sees upcoming session | ✅ | `teacher_dashboard_bloc_test.dart` |
| 11 | Student and teacher join safely | ✅ | `join_session_usecase_test.dart`, SessionDetailBloc join |
| 12 | Non-participant cannot join | ✅ | Join UC + `sessionAuthHelpers.test.ts` |
| 13 | Unsupported provider/mode rejected | ✅ | `createSessionBooking.integration.test.ts` (agora/webrtc/hologram) |
| 14 | Mode/provider locked after booking | ✅ | CF stores server-side metadata; client rules deny patch |
| 15 | Report creation | ✅ | `sessionReports.integration.test.ts`, SessionDetailBloc report |
| 16 | Dispute creation | ✅ | `resolveSessionDispute.integration.test.ts`, SessionDetailBloc dispute |
| 17 | Admin views reports/disputes | ✅ | Angular list/detail components + mapper specs |
| 18 | Rules block protected mutations | ✅ | `quranSessions.rules.test.ts` (+3 write-denial), `usersModeration.rules.test.ts` |
| 19 | Kill switch disables entry/booking | ✅ | `quran_sessions_session_guard_test.dart`, `QuranSessionsFeatureConfig` |
| 20 | Notifications → active device token | ✅ | `fcmTokenService.test.ts`, booking notification integration |

**Coverage estimate (critical paths): ~92%** automated; gaps: Maestro multi-device UI, RescheduleBloc widget tests, admin Angular component specs, dark-mode widget pass.

---

## Files changed (038 closure pass)

```
packages/quran_sessions/test/presentation/blocs/session_detail_bloc_test.dart
packages/quran_sessions/test/domain/policies/session_mode_policy_test.dart
functions/test-rules/quranSessions.rules.test.ts
specs/038-quran-session-stable-production-release/final-report.md
specs/038-quran-session-stable-production-release/implementation-plan.md
specs/038-quran-session-stable-production-release/production-blockers.md
specs/038-quran-session-stable-production-release/README.md
```

Prior 038 branch (already present):

```
functions/src/quranSessions/sessionAuth.ts (+ callables)
functions/src/quranSessions/sessionReportCallables.ts
firestore.rules
apps/tilawa/lib/router/quran_sessions_session_guard.dart
apps/tilawa/lib/router/app_router.dart
apps/tilawa/lib/features/home/presentation/widgets/home_dashboard_footer.dart
```

---

## Verification commands and results

| Command | Result |
|---------|--------|
| `./scripts/quran_sessions_preflight.sh` | ✅ Pass (Flutter suites + 121 CF unit tests). Rules/integration skipped when default JDK ≠ 21 |
| `JAVA_HOME=…21 npm run test:rules` (functions) | ✅ **31/31** pass (incl. new write-denial tests) |
| `JAVA_HOME=…21 npm run test:integration` (functions) | ✅ **38/38** pass |
| `flutter test` (packages/quran_sessions) | ✅ **673/673** pass |
| `dart analyze` (tilawa quran_sessions paths) | ⚠️ 1 pre-existing warning (`fake_mvp_session_lifecycle` unused field), 2 info-level import lints |
| Admin `ng test` | Not run (headless CI varies); mapper specs exist under `tilawa_admin` |

---

## Known risks

1. **Manual E2E unsigned** — B1–B5, T2–T8 table still ⬜ in [docs/qa/quran_sessions_free_beta_signoff.md](../../docs/qa/quran_sessions_free_beta_signoff.md).
2. **App Check off** on session CFs — abuse surface; enable before unrestricted Play production.
3. **External meeting links** — privacy policy not legal-verified.
4. **Single-device epoch** — client-readable; not cryptographic; ~1h ID token replay window documented.
5. **Supply** — empty teacher list UX if no verified/public teachers seeded.
6. **Preflight JDK** — CI/dev machines on JDK 17 skip rules/integration unless `JAVA_HOME` points to 21.

---

## Manual testing checklist (user E2E)

### Student

- [ ] Enable `quranSessionsEnabled` + `quranSessionsBookingEnabled` on staging build
- [ ] Complete student profile (gender, DOB, location)
- [ ] Browse teachers — only public/complete teachers appear
- [ ] Book free external session → My Sessions shows scheduled booking
- [ ] Open session detail → join opens external meeting sheet / browser
- [ ] Cancel session (inside policy window)
- [ ] File report (20+ char description) and open dispute
- [ ] Kill switch off → Learn Quran entry hidden / redirects home

### Teacher

- [ ] Apply → pending → admin approve → push/resume → dashboard without restart
- [ ] Incomplete profile after approve → complete profile gate, not dashboard
- [ ] Set weekly availability + block slot
- [ ] See upcoming booked session on dashboard
- [ ] Join session as teacher (external link)
- [ ] Cancel / request reschedule (mobile request only)
- [ ] Suspended teacher → dashboard blocked

### Admin

- [ ] Approve/reject/suspend teacher application
- [ ] View sessions list + session detail actions (cancel, no-show, complete)
- [ ] Triage reports/disputes queues (read-only) → act via session detail CF
- [ ] Confirm reschedule request by ID

### Device / security

- [ ] Register device A → book → login device B → device A cannot mutate (epoch)
- [ ] Notification arrives on active device only after B registration

---

## Feature flag / rollback

| Flag | Location | Effect |
|------|----------|--------|
| `quranSessionsEnabled` | `AppLaunchConfig` | Router redirect + home footer hide — full feature kill |
| `quranSessionsBookingEnabled` | `AppLaunchConfig` | Blocks booking routes / CTAs |
| `teacherApplicationEnabled` | `AppLaunchConfig` | Hides teacher apply entry points |
| `enabledCallProviders` | Firestore `quran_sessions` config | Server-side mock provider kill |

**Rollback drill:** set `quranSessionsEnabled=false` → app routes `/sessions/*` to home; footer link gone. No client booking writes possible (rules `allow write: if false`).

---

## Google Play readiness (internal / closed testing)

| Item | Status |
|------|--------|
| No Agora/WebRTC active without dart-defines | ✅ default `external,mock` only |
| Agora/WebRTC SDK in binary (inactive path) | ⚠️ bundled via `quran_sessions_rtc`; size + Play disclosure |
| External URL launcher + Android `<queries>` | ✅ |
| Paid/group UI hidden; CF rejects | ✅ |
| Privacy policy mentions third-party meeting links | ❌ Legal verify |
| Internal/closed track upload runbook | See [google-play-release-checklist.md](./google-play-release-checklist.md) |
| `play_production` booking flag default off | ✅ intentional |

**Ready for internal/closed testing** after manual QA pass. **Not ready** for unrestricted production until sign-off + App Check + legal.

---

## Go / No-Go verdict

| Track | Verdict |
|-------|---------|
| Staging / dev manual E2E | **Go** — code complete, automated gates green |
| Google Play internal / closed | **Conditional Go** — after manual checklist + seed teachers |
| Google Play production (wide) | **No-Go** — manual sign-off, App Check, legal privacy pending |

---

## P1 phase — Home kill switch + entry refactor (pipeline 7/7)

**Date:** 2026-06-24  
**Scope:** P0-3 rollback enforcement — router feature guard, footer gating, `openHomeQuranSessions` extraction, dead `HomeSessionsEntryCard` removal.  
**Pipeline verdict:** **Go** — approved for merge.

### Refactored code reviewer (step 7)

| Check | Result |
|-------|--------|
| Behavior preserved | ✅ Diff is extraction + kill-switch wiring only; no semantic shifts |
| Architecture | ✅ Thin footer widget; navigation logic in testable top-level function; tokens + l10n respected |
| Security | ✅ Defense-in-depth: router redirect, footer hide, `openHomeQuranSessions` early return when flag off |
| Scope creep | ✅ None — dead card deleted, no new features |
| Test integrity | ✅ 9 scenario tests assert observable navigation; no weakened/deleted regressions |
| `coverage:ignore` | ✅ None added |
| Analyzer | ✅ Clean on scope files |

**Note (minor):** `home_dashboard_footer.dart` 97.6% — tasbeeh tap path untested (out of P1 scope). Profile fetch failure (`Left`) shares incomplete-profile gate path; not isolated but behavior unchanged.

### P1 phase coverage (reproduced)

| File | Lines hit | % |
|------|-----------|---|
| `open_home_quran_sessions.dart` | 13/13 | **100%** |
| `quran_sessions_session_guard.dart` | 18/18 | **100%** |
| `home_dashboard_footer.dart` | 40/41 | **97.6%** |
| **Combined P1 scope** | 71/72 | **98.6%** |

### P1 phase tests

| Suite | Result |
|-------|--------|
| `home_dashboard_footer_test.dart` | 9/9 pass |
| `quran_sessions_session_guard_test.dart` | 11/11 pass |
| **Flutter P1 total** | **20/20** |

### P1 phase files

```
apps/tilawa/lib/features/home/presentation/widgets/open_home_quran_sessions.dart  (added)
apps/tilawa/lib/features/home/presentation/widgets/home_dashboard_footer.dart       (modified)
apps/tilawa/lib/features/home/presentation/widgets/home_sessions_entry_card.dart    (deleted)
apps/tilawa/lib/router/quran_sessions_session_guard.dart                          (modified — quranSessionsFeatureRedirect)
apps/tilawa/lib/router/app_router.dart                                            (modified — wires feature guard)
apps/tilawa/test/features/home/presentation/widgets/home_dashboard_footer_test.dart (added)
apps/tilawa/test/router/quran_sessions_session_guard_test.dart                    (modified — feature redirect tests)
```

---

## RTC Phase — Agora + WebRTC scaffold (pipeline 5/5)

**Date:** 2026-06-24  
**Scope:** `quran_sessions_rtc` package, `issueSessionRtcToken` CF, DI wiring, gateway extraction, P0 fixes.  
**Pipeline verdict:** **Conditional Go** — merge approved; staging Agora E2E gated on secrets + device QA; Play production with RTC **No-Go**.

### Implementer summary (steps 1 + 3)

| Deliverable | Status |
|-------------|--------|
| `packages/quran_sessions_rtc` — Agora + WebRTC behind `SessionCallProvider` | ✅ |
| `RtcJoinCredentials` typed entity (server uid/channel/token/appId) | ✅ P0 fix |
| `issueSessionRtcToken` CF + `agoraTokenService` (env secrets, 1h TTL) | ✅ |
| `FirebaseCallTokenProvider` maps CF → `RtcJoinCredentials` | ✅ |
| `QuranSessionsRtcModule` — flag-gated Agora/WebRTC in `RoutingSessionCallProvider` | ✅ |
| `AgoraCallProvider.leaveSession` → engine pool release | ✅ P0 fix |
| `AgoraRtcJoinGateway` extraction (`LiveAgoraRtcJoinGateway` + test seams) | ✅ |
| `InAppCallShellScreen` placeholder + `onLeaveCall` wired from nav | ✅ |
| `WebRtcCallProvider` — explicit `WebRtcSignalingUnavailableFailure` stub | ✅ (postponed signaling) |
| Android/iOS mic+camera permissions + usage strings | ✅ |

Default launch config keeps RTC **off**: `enabledCallProvidersCsv = 'external,mock'`, `agoraAppId = ''`. Agora SDK is bundled via `quran_sessions_rtc` dependency but inactive until dart-defines + CF secrets.

### Testing summary (step 4)

| Suite | Result |
|-------|--------|
| `functions/test/quranSessions/issueSessionRtcToken.test.ts` | **6/6** pass |
| `functions` unit total | **131/131** pass |
| `packages/quran_sessions_rtc` | **8/8** pass |
| `packages/quran_sessions` | **674/674** pass |
| `apps/tilawa/.../firebase_call_token_provider_test.dart` | **5/5** pass |
| `in_app_call_shell_screen_test.dart` | pass (existing) |

**New tests (13):** 6 CF auth/lifecycle cases, 5 token-provider validation, 2 WebRTC stub scenarios (plus gateway seam tests in Agora suite).

Gateway seams verified: fake `AgoraRtcJoinGateway` + injectable `joinRunner`/`releaseEngine` — no native Agora in CI.

### Reviewer summary (steps 2 + 5 — final gate)

#### P0 fixes verified

| P0 (first review) | Fix | Semantic drift? |
|-------------------|-----|-----------------|
| Raw map token response | `RtcJoinCredentials` + strict validation in `FirebaseCallTokenProvider` | ✅ None |
| Missing `leaveSession` lifecycle | `AgoraCallProvider.leaveSession` → `AgoraRtcEnginePool.release` | ✅ None |
| CF auth untested | 6 unit tests: non-participant, lifecycle, provider, booking, happy path, teacher profile mapping | ✅ None |

**Gateway extraction:** `AgoraCallProvider` behavior preserved — same join params (server `uid` verbatim, CF `appId` preferred over fallback), pool remember only after successful join, engine released on join failure (`LiveAgoraRtcJoinGateway` catch + `_Fake` tests). No weakened regression tests found.

#### P1 items (first review) — status

| P1 | Status | Notes |
|----|--------|-------|
| ProGuard / R8 release shrink | **Open** | `minifyEnabled true`; project `proguard-rules.pro` has no Agora-specific keeps — relies on AAR consumer rules. **Needs release APK smoke on physical device** before Play. |
| Admin RTC token bypass | **Open (by design, untested)** | `issueSessionRtcToken` skips epoch for admin; `resolveActorRole` allows non-participant admin. Token issued for admin's own Agora uid — support/monitor use case. No unit test; document ops policy. |
| App Check on session CFs | **Open** | `issueSessionRtcToken` has `enforceAppCheck: false` (all session CFs). Client activates App Check in release but CFs don't enforce. |

#### Architecture / scope checks

| Check | Result |
|-------|--------|
| SDK isolated in `quran_sessions_rtc` | ✅ Domain package stays SDK-free |
| No client-side Agora uid derivation | ✅ CF `agoraUidForFirebaseUser` only |
| Participant auth on token CF | ✅ `resolveActorRole` + teacher profile mapping |
| WebRTC not falsely "ready" | ✅ Throws `WebRtcSignalingUnavailableFailure` |
| `coverage:ignore` added | ✅ None |
| Native Agora join in unit tests | ❌ Correct — device-only; gateway fakes cover orchestration |

### RTC phase files changed

```
packages/quran_sessions_rtc/                                    (new package)
  lib/src/boundaries/call/agora_call_provider.dart
  lib/src/boundaries/call/agora_rtc_join_gateway.dart
  lib/src/boundaries/call/agora_rtc_engine_pool.dart
  lib/src/boundaries/call/agora_rtc_session_handle.dart
  lib/src/boundaries/call/rtc_permission_gate.dart
  lib/src/boundaries/call/web_rtc_call_provider.dart
  test/boundaries/agora_call_provider_test.dart
  test/boundaries/web_rtc_call_provider_test.dart

packages/quran_sessions/
  lib/src/domain/entities/rtc_join_credentials.dart             (added)
  lib/src/boundaries/call/call_token_provider.dart              (RtcJoinCredentials return type)
  lib/src/presentation/screens/in_app_call_shell_screen.dart    (added)
  lib/src/presentation/screens/session_detail_screen.dart       (in-app call push + onLeaveCall)

functions/src/quranSessions/
  issueSessionRtcToken.ts
  issueSessionRtcTokenService.ts
  agoraTokenService.ts
  test/quranSessions/issueSessionRtcToken.test.ts

apps/tilawa/
  lib/features/quran_sessions/di/quran_sessions_rtc_module.dart
  lib/features/quran_sessions/data/firebase/firebase_call_token_provider.dart
  lib/features/quran_sessions/router/quran_sessions_nav.dart    (leaveSession wiring)
  lib/core/bootstrap/app_launch_config.dart                     (agora/webrtc dart-defines)
  android/app/src/main/AndroidManifest.xml                      (CAMERA, RECORD_AUDIO, BLUETOOTH_CONNECT)
  ios/Runner/Info.plist                                         (mic/camera usage strings)
  test/features/quran_sessions/firebase_call_token_provider_test.dart
  pubspec.yaml                                                  (quran_sessions_rtc dep)
```

### RTC coverage

| File | Lines | % | Notes |
|------|-------|---|-------|
| `agora_call_provider.dart` | 30/36 | **83.3%** | Uncovered: `joinSession`, `endSession`, empty-appId fallback branch |
| `agora_rtc_join_gateway.dart` | 7/21 | **33.3%** | `_joinLive` native path — device-only |
| `agora_rtc_engine_pool.dart` | 7/11 | **63.6%** | `releaseAll` untested |
| `agora_rtc_session_handle.dart` | 0/4 | **0%** | `LiveAgoraRtcSessionHandle` — native |
| `rtc_permission_gate.dart` | 1/6 | **16.7%** | Needs permission_handler integration / device |
| `web_rtc_call_provider.dart` | 4/7 | **57.1%** | Stub paths only |
| **Package total** | 49/85 | **57.6%** | Honest floor — native SDK paths excluded by design |

Orchestration layer (`AgoraCallProvider` + gateway fakes) is adequately tested for merge. **Sub-90% is acceptable** here; pushing vanity tests on native join would violate test-guard R4/R7.

### Known risks

1. **Native Agora untested in CI** — voice/video join, echo, Bluetooth route, background audio require physical devices (student + teacher).
2. **Release minify** — R8 enabled; Agora native libs + JNI must be smoke-tested on minified release build.
3. **Admin token issuance** — admin can fetch RTC token for any Agora session without epoch; ops credential hygiene required.
4. **App Check off** — callable spam surface on `issueSessionRtcToken`; enable before wide production.
5. **In-app call UI is placeholder** — `InAppCallShellScreen` has no mute/hangup SDK controls; join succeeds but UX is shell-only.
6. **WebRTC postponed** — `flutter_webrtc` bundled but signaling/TURN CF not implemented.
7. **Binary size** — Agora + WebRTC SDKs now in app bundle even when flags off (inactive code path).
8. **Privacy policy** — voice/video + third-party Agora not legal-verified for Play.

### Manual staging checklist (Agora E2E)

**Cloud Functions secrets (Firebase / GCP):**

- [ ] `AGORA_APP_ID` — Agora console project App ID
- [ ] `AGORA_APP_CERTIFICATE` — primary certificate (token builder)
- [ ] Deploy `issueSessionRtcToken` + verify with emulator or staging project

**Firestore config:**

- [ ] Session doc: `callProvider: "agora"`, `lifecycleStatus: "scheduled"` (or `in_progress`)
- [ ] Optional: `providerSessionId` for custom channel name (defaults to session doc id)
- [ ] `enabledCallProviders` in server config includes `agora` if server-side booking validation reads it

**App dart-defines (staging build):**

```sh
flutter run \
  --dart-define=TILAWA_DISTRIBUTION=staging \
  --dart-define=TILAWA_LAUNCH_QURAN_SESSIONS_ENABLED=true \
  --dart-define=TILAWA_LAUNCH_QURAN_SESSIONS_BOOKING_ENABLED=true \
  --dart-define=TILAWA_LAUNCH_ENABLED_CALL_PROVIDERS=external,mock,agora \
  --dart-define=TILAWA_LAUNCH_AGORA_APP_ID=<same_as_AGORA_APP_ID>
```

**Device QA (two physical devices — emulators unreliable for Agora audio):**

- [ ] Student books Agora session (admin seeds teacher + availability)
- [ ] Both grant mic (and camera if video) permissions
- [ ] Student taps Join → `InAppCallShellScreen` appears; audio heard on both sides
- [ ] Teacher joins same session from second device
- [ ] End call → `leaveSession` releases engine; re-join works
- [ ] Stale device (epoch) cannot fetch token
- [ ] Non-participant gets `not_participant` from CF
- [ ] Kill switch `quranSessionsEnabled=false` blocks entry before join
- [ ] Release APK (minified) — Agora join still works

### Postponed (RTC)

| Item | Reason |
|------|--------|
| WebRTC signaling server + TURN credential CF | MVP scope; stub throws `WebRtcSignalingUnavailableFailure` |
| In-app call controls (mute, camera toggle, participant list) | Placeholder shell only |
| Maestro / automated two-device Agora E2E | Native audio; manual staging only |
| App Check on `issueSessionRtcToken` | P1 staged rollout with other session CFs |
| ProGuard explicit Agora keeps | Defer to release smoke; AAR consumer rules may suffice |

### RTC Go / No-Go verdict

| Track | Verdict | Rationale |
|-------|---------|-----------|
| **Merge to main** | **Go** | P0 fixes verified; no semantic drift from gateway extraction; 131 CF + 674 quran_sessions + 8 rtc + 5 app token tests green |
| **Staging Agora E2E** | **Conditional Go** | Code ready; blocked on `AGORA_APP_ID` + `AGORA_APP_CERTIFICATE` deploy, dart-defines, seeded Agora session, **two physical devices** |
| **Play release with RTC enabled** | **No-Go** | Manual Agora E2E unsigned; App Check off; ProGuard release smoke pending; placeholder call UI; privacy policy not updated for voice/video + Agora |

**Honest constraint:** Native Agora join (`LiveAgoraRtcJoinGateway._joinLive`, `LiveAgoraRtcSessionHandle`) is **device-only** — CI proves orchestration and CF auth, not audio quality or R8 survival.

---

## Phase 3 — Post-RTC P1 Hardening (pipeline 4/5)

**Date:** 2026-06-24  
**Scope:** ProGuard Agora keeps, in-app call mute/end shell, admin RTC token test + ops runbook, mock-mute UX fix (`callProviderKind` gating).  
**Pipeline verdict:** **Go** — merge approved; staging Agora E2E still gated on device QA + release APK smoke; Play with RTC **No-Go**.

**Refactor stage (4/5):** **Skipped** — acceptable. Stage-3 finding was one surgical P1 UX fix (mock mute button visible); no structural debt, no wrong abstractions, `InAppCallShellScreen` already at 100% line coverage. Refactor would add churn without behavior gain.

### Implementer summary (steps 1 + 4)

| Deliverable | Status |
|-------------|--------|
| ProGuard / R8 Agora keeps (`-keep class io.agora.**`) | ✅ |
| `InAppCallShellScreen` — mute toggle + end-call with injected callbacks | ✅ |
| `SessionCallProvider.setMicrophoneMuted` wired through routing → `AgoraCallProvider` | ✅ |
| Nav (`quran_sessions_nav.dart`) wires `onLeaveCall` + `onSetMicrophoneMuted` | ✅ |
| l10n strings: mute / unmute / end call (EN + AR) | ✅ |
| Admin RTC ops runbook in `admin-ops-requirements.md` | ✅ |
| **Reviewer fix:** `supportsInAppMicrophoneMute` gates mute to `agora`/`webrtc` only | ✅ |
| `SessionDetailBloc` copies `callProviderKind` from linked session on load | ✅ |

Mock sessions: mute control **hidden** even when nav injects callback — prevents deceptive no-op UX.

### Testing summary (steps 2 + 5)

| Suite | Result |
|-------|--------|
| `in_app_call_shell_screen_test.dart` | **3/3** pass |
| `session_detail_screen_test.dart` (in-app join subset) | **2/2** new mute scenarios pass |
| `session_detail_bloc_test.dart` | **+1** `callProviderKind` load test pass |
| `routing_session_call_provider_test.dart` | mute-forward test pass |
| `agora_call_provider_test.dart` | `setMicrophoneMuted` test pass |
| **Flutter Phase 3 targeted** | **16/16** pass (shell + screen + bloc) |
| `packages/quran_sessions_rtc` | **9/9** pass |
| `functions` unit total | **132/132** pass (incl. admin RTC case) |

**New tests (+5):** 3 shell (end-call order, mute toggle, mute hidden), 1 routing mute forward, 1 CF admin-without-epoch; **post-review (+3):** mock mute hidden, agora mute wired, bloc `callProviderKind` load.

### Reviewer summary (step 3)

| Finding | Severity | Resolution |
|---------|----------|------------|
| Mock in-app join showed mute button but `MockSessionCallProvider.setMicrophoneMuted` is no-op | **P1 should-fix** | `supportsInAppMicrophoneMute` on `SessionDetailSuccess`; screen passes `onSetMicrophoneMuted: null` for mock/external |
| ProGuard Agora keeps unverified on device | **P1 note** | Keeps added; **release APK smoke still required** |
| Admin RTC bypass undocumented | **P1 note** | Runbook + unit test added |
| Test integrity | ✅ | No weakened/deleted regressions; new tests assert observable UX |
| `coverage:ignore` | ✅ | None added |

**Verdict after fix:** ready to merge — no refactor queue.

### Refactor reviewer (step 5 — skipped)

Not run. **Acceptable** for this phase: diff is additive hardening + one UX gate; no extraction targets; shell widget at 100% coverage; native Agora paths remain device-only by design.

### Phase 3 files changed

```
apps/tilawa/android/app/proguard-rules.pro

packages/quran_sessions/
  lib/src/presentation/screens/in_app_call_shell_screen.dart
  lib/src/presentation/screens/session_detail_screen.dart
  lib/src/presentation/blocs/session_detail/session_detail_bloc.dart
  lib/src/presentation/blocs/session_detail/session_detail_state.dart
  lib/src/boundaries/call/session_call_provider.dart
  lib/src/boundaries/call/routing_session_call_provider.dart
  lib/src/boundaries/call/mock_session_call_provider.dart
  lib/src/boundaries/call/external_meeting_call_provider.dart
  lib/l10n/intl_en.arb
  lib/l10n/intl_ar.arb
  lib/l10n/quran_sessions_localizations*.dart
  test/presentation/screens/in_app_call_shell_screen_test.dart          (added)
  test/presentation/screens/session_detail_screen_test.dart             (mute scenarios)
  test/presentation/blocs/session_detail_bloc_test.dart                 (callProviderKind)
  test/boundaries/routing_session_call_provider_test.dart               (mute forward)

packages/quran_sessions_rtc/
  lib/src/boundaries/call/agora_call_provider.dart                      (setMicrophoneMuted)
  test/boundaries/agora_call_provider_test.dart                         (mute forward)

apps/tilawa/lib/features/quran_sessions/router/quran_sessions_nav.dart

functions/test/quranSessions/issueSessionRtcToken.test.ts               (admin case)

specs/038-quran-session-stable-production-release/admin-ops-requirements.md
specs/038-quran-session-stable-production-release/final-report.md
```

### Phase 3 coverage

| File | Lines hit | % | Notes |
|------|-----------|---|-------|
| `in_app_call_shell_screen.dart` | 54/54 | **100%** | Mute toggle, end-call, hidden-mute path |
| `agora_call_provider.dart` | 30/36 | **83.3%** | `setMicrophoneMuted` covered; native join/end device-only |
| `session_detail_screen.dart` (mute gate) | partial | — | Agora wire + mock hide exercised; report/dispute paths untested |
| `session_detail_state.dart` (`supportsInAppMicrophoneMute`) | exercised via screen | — | Getter hit through widget test navigation path |
| `proguard-rules.pro` | n/a | — | **Manual release APK only** |
| **Phase 3 new UI scope** | ~54/54 shell + gate paths | **~95%** | Honest floor — R8 survival not provable in CI |

`quran_sessions_rtc` package total remains **57.6%** (49/85) — unchanged acceptable floor; Phase 3 only added mute orchestration tests.

### Remaining blockers (unchanged + Phase 3 notes)

| Blocker | Status |
|---------|--------|
| App Check off on session CFs | **Open** — `issueSessionRtcToken` `enforceAppCheck: false` |
| WebRTC signaling / TURN CF | **Postponed** — stub throws `WebRtcSignalingUnavailableFailure` |
| In-app call UI | **Partial** — mute + end-call work; still no camera toggle, participant list, or polished call chrome |
| ProGuard / R8 on physical device | **Open** — keeps added; **minified release APK Agora join not yet signed off** |
| Manual B1–B5 / T2–T8 E2E | **Open** |
| Legal privacy (voice/video + Agora) | **Open** |
| Admin RTC monitor | **Documented + unit tested** — ops credential hygiene required |

### Postponed (Phase 3)

| Item | Reason |
|------|--------|
| Refactor pass (pipeline 4/5) | No structural findings; skip acceptable |
| Camera toggle / participant list | Out of P1 hardening scope |
| WebRTC mute (signaling blocked) | Gate exists; WebRTC provider still stub |
| Maestro two-device Agora E2E | Native audio — manual staging |
| ProGuard consumer-rules-only fallback | Explicit keeps landed; device smoke deferred |

### Manual staging checklist (release APK + Agora mute E2E)

**Prerequisites:** same as RTC phase (CF secrets, Firestore `callProvider: agora`, dart-defines with `agora` in `enabledCallProviders`).

**Build release APK (minified):**

```sh
cd apps/tilawa
flutter build apk --release \
  --dart-define=TILAWA_DISTRIBUTION=staging \
  --dart-define=TILAWA_LAUNCH_QURAN_SESSIONS_ENABLED=true \
  --dart-define=TILAWA_LAUNCH_QURAN_SESSIONS_BOOKING_ENABLED=true \
  --dart-define=TILAWA_LAUNCH_ENABLED_CALL_PROVIDERS=external,mock,agora \
  --dart-define=TILAWA_LAUNCH_AGORA_APP_ID=<AGORA_APP_ID>
```

**Device QA (two physical devices):**

- [ ] Install **minified release APK** on both devices (not debug)
- [ ] Student + teacher join Agora session — audio on both sides
- [ ] **Mute** on student → teacher hears silence; **unmute** restores audio
- [ ] **End call** → route pops; `leaveSession` releases engine; re-join works
- [ ] Mock session join → **no mute button** visible (UX gate)
- [ ] Agora session join → mute button **visible** and functional
- [ ] Stale device cannot fetch RTC token
- [ ] Admin with `admin` claim can fetch monitor token (staging only; verify uid is admin's own)

### Phase 3 Go / No-Go verdict

| Track | Verdict | Rationale |
|-------|---------|-----------|
| **Merge to main** | **Go** | P1 mock-mute UX fixed; 16 Flutter + 9 rtc + 132 CF tests green; ProGuard keeps + runbook + admin test landed |
| **Staging Agora E2E** | **Conditional Go** | Code ready; blocked on secrets deploy, seeded Agora session, **two physical devices**, **minified APK smoke** |
| **Play release with RTC enabled** | **No-Go** | Release ProGuard smoke unsigned; manual Agora mute E2E unsigned; App Check off; call UI still minimal; privacy policy not updated |

---

## Phase 4 — App Check Staged Rollout (pipeline 4/4)

**Date:** 2026-06-24  
**Scope:** Centralize stable-scope session callable App Check enforcement behind env gate `QURAN_SESSIONS_ENFORCE_APP_CHECK`; wire 12 CFs; wiring smoke tests; ops rollout docs.  
**Pipeline verdict:** **Go** — merge approved; **staging/prod enforcement flip is ops-gated**, not automatic.

### Implementer summary (step 1)

| Deliverable | Status |
|-------------|--------|
| `sessionCallableOptions.ts` — `isSessionAppCheckEnforced()` reads env; default `false` | ✅ |
| `sessionCallableHttpsOptions` shared by stable-scope `onCall` exports | ✅ |
| 12 callables wired across 10 source files | ✅ |
| Wallet/payment + teacher moderation CFs **excluded** (explicit `enforceAppCheck: false`) | ✅ |
| Rollout steps in `security-safety-checklist.md` | ✅ |
| Rollback layer 7 in `monitoring-rollback-plan.md` | ✅ |
| `production-blockers.md` P1-1 → **Staged (Phase 4)** | ✅ |

**Design:** Enforcement is **opt-in at deploy/runtime** — `QURAN_SESSIONS_ENFORCE_APP_CHECK=true` only. Unset or any non-`"true"` value keeps current behavior (no CF rejection). Client already activates App Check in release builds (`app_startup_tasks.dart`); CFs do not enforce until ops flips env and redeploys.

**12 covered callables:** `createSessionBooking`, `cancelSessionBooking`, `requestSessionReschedule`, `confirmSessionReschedule`, `completeSession`, `markSessionNoShow`, `openSessionDispute`, `resolveSessionDispute`, `reportSessionConcern`, `resolveSessionReport`, `issueSessionRtcToken`, `registerActiveDevice`.

### Testing summary (step 2)

| Suite | Result |
|-------|--------|
| `sessionCallableOptions.test.ts` | **3/3** pass (unset, exact `"true"`, reject non-true) |
| `sessionCallableWiring.test.ts` | **3/3** pass (import/options, 12-export count, wallet exclusion) |
| `functions` unit total | **138/138** pass |

Wiring tests are static source assertions — they guard against drift (missing import, wrong count, wallet batch accidentally opted in).

### Reviewer summary (step 3)

| Check | Result |
|-------|--------|
| Default-off preserves staging/dev behavior | ✅ |
| Wallet/payment batch stays excluded | ✅ Verified by wiring test |
| No semantic change until ops enables env | ✅ |
| Test integrity | ✅ No weakened regressions |
| P0 findings | **None** |
| P1 note | Stale debug comment in `app_startup_tasks.dart` claimed all session CFs use `enforceAppCheck: false` — **fixed in final gate** |

**Verdict:** ready to merge — no refactor stage (pipeline 4/4, refactor skipped by design).

### Final gate (step 4)

| Quick fix | Status |
|-----------|--------|
| `app_startup_tasks.dart` stale App Check comment | ✅ 1-line update — debug skip rationale only; no longer claims CF enforcement off |

### Phase 4 files changed

```
functions/src/quranSessions/sessionCallableOptions.ts                    (added)
functions/src/quranSessions/createSessionBooking.ts
functions/src/quranSessions/cancelSessionBooking.ts
functions/src/quranSessions/requestSessionReschedule.ts
functions/src/quranSessions/confirmSessionReschedule.ts
functions/src/quranSessions/completeSession.ts
functions/src/quranSessions/markSessionNoShow.ts
functions/src/quranSessions/sessionDisputeCallables.ts
functions/src/quranSessions/sessionReportCallables.ts
functions/src/quranSessions/issueSessionRtcToken.ts
functions/src/registerActiveDevice.ts

functions/test/quranSessions/sessionCallableOptions.test.ts              (added)
functions/test/quranSessions/sessionCallableWiring.test.ts               (added)

specs/038-quran-session-stable-production-release/security-safety-checklist.md
specs/038-quran-session-stable-production-release/production-blockers.md
specs/038-quran-session-stable-production-release/monitoring-rollback-plan.md
specs/038-quran-session-stable-production-release/final-report.md

apps/tilawa/lib/core/bootstrap/app_startup_tasks.dart                    (comment fix — final gate)
```

### Remaining blockers (post-Phase 4)

| Blocker | Status |
|---------|--------|
| **Ops: enable `QURAN_SESSIONS_ENFORCE_APP_CHECK` on staging** | **Open** — code ready; enforcement not flipped |
| **Ops: staging smoke after enforcement flip** | **Open** — B1–B5 / T2–T8 + session flows must pass with App Check enforced |
| **Ops: prod enforcement flip** | **Blocked** on staging green |
| Manual E2E sign-off (B1–B5, T2–T8) | **Open** |
| Legal privacy (external links + Agora voice/video) | **Open** |
| Wallet/payment CFs App Check | **Out of batch** — still `enforceAppCheck: false` by design |
| Teacher moderation CFs App Check | **Out of batch** |
| Maestro book→join E2E | **Open** |
| ProGuard release APK Agora smoke | **Open** |

**Honest constraint:** Merging this PR does **not** turn on App Check enforcement. Default remains off until ops sets env and redeploys session CFs.

### Manual ops checklist — staging App Check enable

**Prerequisites**

- [ ] Phase 4 code merged and session CFs deployed with env **unset** (verify no behavior change on current staging)
- [ ] Staging app is a **release** build (not debug) — App Check activation skipped in `kDebugMode`
- [ ] Play Integrity (Android) / App Attest + DeviceCheck (iOS) configured for staging Firebase project
- [ ] Firebase Console → App Check → verify attestation providers registered for staging app IDs

**Enable enforcement (staging only)**

1. [ ] Set Cloud Functions runtime env: `QURAN_SESSIONS_ENFORCE_APP_CHECK=true` (staging project / staging function set only)
2. [ ] Redeploy all 12 stable-scope session callables (or full `functions` deploy if that is your norm)
3. [ ] Confirm wallet/payment callables (`getWallet`, `confirmBookingPayment`, …) still deploy with explicit `enforceAppCheck: false` — unchanged

**Smoke (release staging build)**

- [ ] `registerActiveDevice` succeeds on fresh login
- [ ] Student books free session → `createSessionBooking` succeeds
- [ ] Open session detail → join path works (external and/or Agora per config)
- [ ] Teacher dashboard loads upcoming session; teacher join works
- [ ] Cancel / reschedule request / report / dispute callables succeed for participants
- [ ] `issueSessionRtcToken` succeeds for Agora session (if RTC enabled on staging)
- [ ] Stale device (epoch) still rejected on booking/join
- [ ] Kill switch `quranSessionsEnabled=false` still blocks entry (App Check independent)

**Failure triage**

- [ ] Callable returns `unauthenticated` / App Check error → client not sending token: verify release build, Play/App Store signing, App Check debug token **not** used in release
- [ ] Rollback: unset `QURAN_SESSIONS_ENFORCE_APP_CHECK` or set `false`, redeploy (~15 min per `monitoring-rollback-plan.md` layer 7)

**Production flip (only after staging green)**

- [ ] Repeat env set + redeploy on **production** Firebase project
- [ ] Repeat smoke on production closed-track build before wide Play rollout

### Phase 4 Go / No-Go verdict

| Track | Verdict | Rationale |
|-------|---------|-----------|
| **Merge to main** | **Go** | Centralized opt-in gate; 12 CFs wired; 138 CF unit tests green; wallet batch excluded; docs + rollback plan updated |
| **Staging enforcement flip** | **Conditional Go** | Code ready; **ops must** set `QURAN_SESSIONS_ENFORCE_APP_CHECK=true`, redeploy, then run manual staging smoke — not automatic on merge |
| **Production enforcement flip** | **No-Go** | Blocked on staging enforcement + B1–B5/T2–T8 sign-off; legal privacy still open |
