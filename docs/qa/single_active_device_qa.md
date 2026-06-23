# Single Active Device — Two-Device QA Runbook

**Scope:** Free Beta single-active-device enforcement (no wallet/payment).  
**Prereqs:** Two physical devices (or one device + emulator) with staging build, push enabled, same test account.

**Build:** staging distribution (`TILAWA_DISTRIBUTION` ≠ `play_production`), Quran Sessions flags on.

**Phase status (2026-06-23):** Automated phases 1–3 complete. **Manual sign-off below blocks production Go.**

---

## T2 — Login second device

| Step | Device A | Device B | Expected |
|------|----------|----------|----------|
| 1 | Sign in as test user | — | Home loads |
| 2 | — | Sign in **same** Google account | B becomes active |
| 3 | Observe A | — | A shows “signed in elsewhere” dialog → login screen |
| 4 | Check FCM (optional) | — | A received `session_revoked` data push |

**Pass:** Only B stays signed in; A forced out within ~30s (FCM) or on next resume.

---

## T5 — A offline at B login

| Step | Device A | Device B | Expected |
|------|----------|----------|----------|
| 1 | Sign in, then **airplane mode** | — | A offline |
| 2 | — | Sign in same account | B active |
| 3 | Disable airplane, **resume** Tilawa on A | — | A signs out + dialog on resume |

**Pass:** A cannot keep browsing after foreground; no silent stale session.

---

## T6 — A mid-session booking

| Step | Device A | Device B | Expected |
|------|----------|----------|----------|
| 1 | Sign in, open Quran Sessions booking flow (slot picker or confirm) | — | Flow open |
| 2 | — | Sign in same account | B active |
| 3 | On A, attempt book / confirm | — | CF rejects or UI redirects; A signs out |

**Pass:** Stale device cannot complete booking after B login.

---

## T7 — Teacher approval push

| Step | Device A | Device B | Expected |
|------|----------|----------|----------|
| 1 | Sign in as **pending teacher** applicant on A | — | Application submitted |
| 2 | — | Sign in same account on B | B active; A revoked |
| 3 | Admin approves application | — | Push arrives on **B only** (not A) |

**Pass:** `reviewTeacherApplication` notification targets `notifications.activeFcmToken` on B.

---

## T8 — Re-login same device after B logout

| Step | Device A | Device B | Expected |
|------|----------|----------|----------|
| 1 | (revoked from T2/T5) | Signed in | B active |
| 2 | — | Sign out voluntarily | B cleared |
| 3 | Sign in on A | — | A becomes active again (`epoch` may bump) |
| 4 | — | Sign in same account | B wins; A revoked again |

**Pass:** Voluntary sign-out on B does not block A re-activation; last login still wins.

---

## Sign-off

| Scenario | Tester | Date | Pass |
|----------|--------|------|------|
| T2 | | | ⬜ |
| T5 | | | ⬜ |
| T6 | | | ⬜ |
| T7 | | | ⬜ |
| T8 | | | ⬜ |

**Recorder:** _______________

---

## Go/No-Go (manual)

| Gate | Status |
|------|--------|
| T2/T5/T6/T7/T8 all pass on staging | ⬜ Pending |
| No wallet/payment regressions observed | ⬜ Pending |
| **Verdict** | **Conditional Go** until sign-off complete |

---

## Automated coverage (CI / local)

```sh
# JDK 21+ required for Firestore emulator
export JAVA_HOME="$(/usr/libexec/java_home -v 21)"   # macOS
cd functions
npm ci
npm test                    # unit (106+)
npm run test:integration    # registerActiveDevice + epoch + booking integration
npm run test:rules          # activeDevice.rules.test.ts
npm run test:emulator       # both emulator suites
```

Flutter session suite:

```sh
cd apps/tilawa
dart analyze
flutter test test/features/auth test/features/notifications/data test/router/quran_sessions_session_guard_test.dart
flutter test --coverage test/features/auth test/features/notifications/data test/router/quran_sessions_session_guard_test.dart
```

### Coverage snapshot (affected paths)

| File | Lines % | Met 90% |
|------|---------|---------|
| `session_validity_cubit.dart` | 96.7% | Y |
| `register_active_device_use_case.dart` | 100% | Y |
| `quran_sessions_session_guard.dart` | 100% | Y |
| `pending_session_revoke_store.dart` | 100% | Y |
| `fcm_session_revoked_message.dart` | 100% | Y |
| `session_revoked_navigation_listener.dart` | 96.9% | Y |
| `fcmTokenService.ts` | 98.8% | Y |
| `sessionAuth.ts` | 95.5% | Y |
| `registerActiveDevice.ts` | 93.5% | Y |
