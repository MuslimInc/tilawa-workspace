# Individual Booking — Staging QA Runbook

**Scope:** Free Beta individual session booking (external meeting + mock voice/video).
No wallet/payment, group sessions, or in-app Agora/WebRTC.

**Prereqs:** Staging build (`TILAWA_DISTRIBUTION` ≠ `play_production`), Quran Sessions
enabled, test student + verified teacher accounts with complete profiles.

**Related:** [Single Active Device QA](./single_active_device_qa.md) (stale-device booking),
[Individual booking delivery report](../../specs/037-quran-session-free-beta-closure/individual-booking-provider-report.md).

**Phase status (2026-06-23):** Automated unit/integration coverage in place.
**Manual sign-off below blocks Free Beta Go for booking.**

---

## B1 — Student: external meeting booking

| Step | Action | Expected |
|------|--------|----------|
| 1 | Sign in as test **student** | Home loads |
| 2 | Quran Sessions → browse teachers → open verified teacher | Teacher profile loads |
| 3 | Tap **Book session** | Slot picker + mode control visible |
| 4 | Select **External meeting**, pick available slot | Confirm enabled |
| 5 | Tap **Confirm booking** | Success toast; session appears in My Sessions |
| 6 | Open session detail → tap **Join** | External browser/app opens teacher meeting URL |

**Pass:** Session doc has `callProvider: external`, `joinUrl` populated; join opens link.

---

## B2 — Student: mock voice/video (when enabled)

| Step | Action | Expected |
|------|--------|----------|
| 1 | On booking screen, select **Voice** or **Video** (if shown) | Mode selectable when `SessionModePolicy.freeBeta` |
| 2 | Confirm booking | Success; session in My Sessions |
| 3 | Open detail → **Join** | Mock join succeeds (no SDK crash); placeholder UX / no real RTC |

**Pass:** Session has `callProvider: mock`; join does not open external URL.

**Note:** When host uses `SessionModePolicy.externalOnly`, voice/video segments are
hidden — skip B2 or verify disabled copy only.

---

## B3 — Teacher: upcoming session

| Step | Action | Expected |
|------|--------|----------|
| 1 | Sign in as **teacher** who received B1/B2 booking | Teacher dashboard loads |
| 2 | Open upcoming / scheduled sessions | New session listed with correct time + student |
| 3 | Open session detail | Matches student booking (mode, lifecycle `scheduled`) |

**Pass:** Teacher sees same session id; can view metadata (join rules per role).

---

## B4 — Idempotency / double-tap confirm

| Step | Action | Expected |
|------|--------|----------|
| 1 | Start booking flow; select slot + mode | Confirm enabled |
| 2 | Rapidly double-tap **Confirm booking** | Single session created |
| 3 | Check My Sessions + Firestore | One session doc; no duplicate bookings |

**Pass:** Second tap ignored or returns same outcome; no duplicate charge/slot lock errors.

---

## B5 — Stale device blocked on booking

| Step | Device A | Device B | Expected |
|------|----------|----------|----------|
| 1 | Student signed in; open booking confirm | — | Flow open |
| 2 | — | Same account signs in | B active; A revoked |
| 3 | A taps confirm | — | CF rejects or UI signs out; no new session |

**Pass:** Same as [T6 in single-active-device QA](./single_active_device_qa.md#t6--a-mid-session-booking).

---

## Sign-off

| Scenario | Tester | Date | Pass |
|----------|--------|------|------|
| B1 External booking + join | | | ⬜ |
| B2 Mock voice/video | | | ⬜ |
| B3 Teacher upcoming | | | ⬜ |
| B4 Idempotency | | | ⬜ |
| B5 Stale device | | | ⬜ |

**Recorder:** _______________

---

## Go/No-Go (manual)

| Gate | Status |
|------|--------|
| B1–B5 pass on staging | ⬜ Pending |
| External + mock only (no Agora/WebRTC SDK) | ⬜ Verified |
| No wallet/payment/group regressions | ⬜ Pending |
| **Verdict** | **Conditional Go** until sign-off complete |

---

## Automated coverage (CI / local)

```sh
cd packages/quran_sessions
dart analyze
flutter test test/domain/usecases/submit_session_booking_usecase_test.dart
flutter test test/domain/usecases/join_session_usecase_test.dart
flutter test test/boundaries/call_provider_test.dart
flutter test test/boundaries/routing_session_call_provider_test.dart
flutter test test/presentation/screens/booking_screen_test.dart
```

```sh
# JDK 21+ for Firestore emulator
export JAVA_HOME="$(/usr/libexec/java_home -v 21)"   # macOS
cd functions
npm run test:integration -- test-integration/createSessionBooking.integration.test.ts
```

Integration tests cover: mock voice metadata, group rejected, agora/webrtc client hint rejected.
