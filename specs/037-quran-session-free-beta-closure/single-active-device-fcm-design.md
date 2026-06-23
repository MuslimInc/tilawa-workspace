# Single Active Device — FCM Token Storage & Session Invalidation

**Status:** Implemented (P0 Free Beta) — Phase 3 complete 2026-06-23  
**Scope:** Whole Tilawa app auth + notifications; Quran Sessions CF enforcement  
**Product rule:** One active device per user/teacher. New login → new token active; old devices lose access + notifications.

### Phase completion

| Phase | Scope | Status | Owner |
|-------|--------|--------|-------|
| **1** | Architecture + `registerActiveDevice`, epoch guards, FCM targeting | ✅ Complete | Automated |
| **2** | CI JDK21 emulator job, integration/rules tests, background `session_revoked`, QA runbook | ✅ Complete | Automated |
| **3** | Coverage gap closure (90%+), widget/cubit tests, checklist + Go/No-Go | ✅ Complete | Automated |
| **Go** | Two-device manual QA T2/T5/T6/T7/T8 | ⏸ Pending | **Manual QA** |

### Implementation status

| Area | Status | Tests |
|------|--------|-------|
| `registerActiveDevice` CF + embedded `session` / `notifications` | ✅ Shipped | `registerActiveDevice.test.ts`, `registerActiveDevice.integration.test.ts`, `fcmTokenMigration.test.ts` |
| CF epoch guards on Quran Sessions callables | ✅ Shipped | `sessionAuthCallable.test.ts`, `sessionAuthHelpers.test.ts`, integration epoch tests |
| Client register + epoch cache | ✅ Shipped | `register_active_device_use_case_test.dart`, `sync_device_token_use_case_test.dart` |
| FCM `session_revoked` foreground | ✅ Shipped | `notifications_repository_impl_test.dart`, `fcm_session_revoked_message_test.dart` |
| FCM `session_revoked` background → resume sign-out | ✅ Shipped | `pending_session_revoke_store_test.dart`, `firebase_messaging_background_handler_test.dart`, `SessionValidityCubit` |
| `SessionValidityCubit` + resume epoch check | ✅ Shipped | `session_validity_cubit_test.dart` |
| GoRouter `/sessions/*` guard | ✅ Shipped | `quran_sessions_session_guard_test.dart` |
| Rules lockdown (`fcm_tokens` write deny) | ✅ Deployed | `activeDevice.rules.test.ts` (CI) |
| `sendPushToUsers` → single `activeFcmToken` | ✅ Shipped | `fcmTokenService.test.ts`, `fcmTokenService.sendPush.test.ts` |
| FCM token migration script | ✅ Applied staging | `fcmTokenMigration.test.ts` |
| App Check on `registerActiveDevice` | ⏸ Deferred P1 | Client activates App Check; CF `enforceAppCheck: false` — **do not enable globally without flag** |
| Two-device manual QA T2/T5/T6/T7/T8 | ⏸ User | `docs/qa/single_active_device_qa.md` |

**CI:** `.github/workflows/pr-checks.yml` job `functions-emulator-tests` (JDK 21, `npm run test:integration` + `test:rules`). Flutter: `flutter test test/features/auth test/features/notifications/data test/router/quran_sessions_session_guard_test.dart`.

### Coverage (affected paths, 2026-06-23)

Measured with `flutter test --coverage` (Flutter) and `npx c8` + emulator integration (Functions). Target: **90–100%**.

| File | Lines % | Target met |
|------|---------|------------|
| `session_validity_cubit.dart` | 96.7% | Y |
| `register_active_device_use_case.dart` | 100% | Y |
| `quran_sessions_session_guard.dart` | 100% | Y |
| `pending_session_revoke_store.dart` | 100% | Y |
| `fcm_session_revoked_message.dart` | 100% | Y |
| `session_revoked_navigation_listener.dart` | 96.9% | Y |
| `persistBackgroundSessionRevokeIfNeeded` (`app_startup.dart`) | 100% | Y |
| `fcmTokenService.ts` | 98.8% | Y |
| `sessionAuth.ts` | 95.5% | Y |
| `registerActiveDevice.ts` (unit validation + emulator integration) | 93.5% | Y |

### Test matrix T1–T10

| Scenario | Automated | Manual |
|----------|-----------|--------|
| T1 Fresh login same device | ✅ `registerActiveDevice.integration.test.ts` | — |
| T2 Login second device | — | ⬜ User |
| T3 Token refresh same device | ✅ integration + use-case tests | — |
| T4 Sign out voluntary | ✅ signOut integration + use-case | — |
| T5 A offline at B login | — | ⬜ User |
| T6 A mid-session booking | ✅ epoch integration + GoRouter guard | ⬜ User |
| T7 Teacher approval push | ✅ `sendPushToUsers` unit test | ⬜ User |
| T8 Re-login same device after B | — | ⬜ User |
| T9 Delete account | ✅ existing auth tests (out of scope wallet) | — |
| T10 Invalid FCM token | ✅ `clearInvalidActiveFcmTokens` tests | — |

### Free Beta Go/No-Go

| Criterion | Verdict |
|-----------|---------|
| Automated unit + integration + rules tests green | ✅ Go |
| Coverage ≥90% on affected paths | ✅ Go |
| App Check **not** enabled globally (P1 flag) | ✅ Go (deferred) |
| Two-device manual QA T2/T5/T6/T7/T8 signed off | ⏸ **Conditional Go** — ship after manual sign-off |

**Overall:** **Conditional Go** — automated gate passed; manual two-device QA required before production Free Beta.

### Manual QA sign-off

| Scenario | Tester | Date | Pass |
|----------|--------|------|------|
| T2 | | | ⬜ |
| T5 | | | ⬜ |
| T6 | | | ⬜ |
| T7 | | | ⬜ |
| T8 | | | ⬜ |

**Recorder:** _______________

---

## Current state (Tilawa)

| Area | Today | Gap |
|------|-------|-----|
| Token storage | `users/{uid}/fcm_tokens/{token}` — doc ID = token string; fields: `token`, `createdAt`, `platform` | Multi-device tokens accumulate; CF reads **all** subcollection docs |
| Client registration | Direct Firestore write in `UserRepositoryImpl.saveDeviceToken` | No server authority; no cross-device revoke |
| Sync | `SyncDeviceTokenUseCase` + `TokenSyncCache` (SharedPreferences) | Cleans **local** prior token/user only, not other devices |
| Triggers | `AuthBloc` sign-in, `FCMService` auth + `onTokenRefresh` | Same user on Device B does not invalidate Device A |
| Sign-out | `SignOut` → `removeCurrentTokenForUser` | Correct for voluntary logout only |
| Push delivery | `sendPushToUsers` / `collectFcmTokens` — subcollection `.get()` per user | N reads per user; sends to **all** tokens |
| Session security | `requireAuthenticatedUid` — Firebase Auth UID only | No device/session binding |
| Rules | `fcm_tokens`: owner read/write | Client can add arbitrary tokens |
| Invalidation patterns | None (`revokeRefreshTokens`, `sessionEpoch`, `activeDeviceId` absent) | Access remains until ID token expiry (~1h) |
| Cost pattern precedent | `TeacherCapabilityRefreshNotifier` — FCM → one-shot refresh, **no** Firestore listener | Reuse for `session_revoked` UX |

**Key paths today:**

```33:44:apps/tilawa/lib/features/auth/data/repositories/user_repository_impl.dart
  Future<void> saveDeviceToken(String userId, String token) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('fcm_tokens')
        .doc(token)
        .set({
          'token': token,
          'createdAt': FieldValue.serverTimestamp(),
          'platform': Platform.isAndroid ? 'android' : 'ios',
        });
  }
```

```3:27:functions/src/quranSessions/fcmTokenService.ts
export async function collectFcmTokens(
  db: FirebaseFirestore.Firestore,
  userIds: string[],
): Promise<string[]> {
  // ... batches users, fcm_tokens subcollection .get() per user
}
```

```334:336:firestore.rules
      match /fcm_tokens/{tokenId} {
        allow read, write: if isOwner(userId);
      }
```

---

## 1. Recommended data model

**Choice: embedded fields on `users/{uid}`** (not subcollection for active token).  
**Reason:** 1 doc read per push target vs N subcollection reads; aligns with cost goal.

### `users/{uid}` — new maps (server-authoritative)

```typescript
// Pseudotype — implement in CF + rules tests
session: {
  epoch: number,              // monotonic int; +1 on each new active device
  activeDeviceId: string,     // Firebase Installations ID (FID), stable per install
  registeredAt: Timestamp,
  platform: "android" | "ios" | "web",
  appVersion?: string,        // optional telemetry
}

notifications: {
  activeFcmToken: string,     // single token for push
  tokenUpdatedAt: Timestamp,
  platform: "android" | "ios" | "web",
}
```

### Token storage fields (requirement 1)

| Field | Location | Writer | Purpose |
|-------|----------|--------|---------|
| `notifications.activeFcmToken` | `users/{uid}` | CF only | Push target (1 read) |
| `notifications.tokenUpdatedAt` | `users/{uid}` | CF only | Audit, stale-token debug |
| `notifications.platform` | `users/{uid}` | CF only | APNS vs Android payload tuning |
| `session.epoch` | `users/{uid}` | CF only | Access invalidation |
| `session.activeDeviceId` | `users/{uid}` | CF only | Identity of winning device |
| `session.registeredAt` | `users/{uid}` | CF only | Support / audit |
| `session.platform` | `users/{uid}` | CF only | Analytics |
| `session.appVersion` | `users/{uid}` | CF optional | Crash correlation |

### Client-local (not Firestore)

Extend `TokenSyncCache` → `SessionLocalStore`:

| Key | Purpose |
|-----|---------|
| `last_synced_fcm_token` | existing |
| `last_synced_fcm_user_id` | existing |
| `session_epoch` | compare vs server |
| `active_device_id` | FID cached at register |

### Legacy `fcm_tokens` subcollection

- **Phase out** for delivery; CF deletes all docs on `registerActiveDevice`.
- Keep path temporarily for migration script; deny client writes in rules.
- Do **not** use subcollection for “devices history” in P0 (cost).

### Why not separate `users/{uid}/devices/{deviceId}` collection?

- Extra reads on every push + session check.
- Embedded + epoch is enough for single-active-device.
- Revisit if product needs device list UI (P1).

---

## 2. Recommended session invalidation strategy

**Primary: `session.epoch` + client enforcement**  
**Secondary: `revokeRefreshTokens(uid)` on new device registration**  
**Tertiary: FCM data message `session_revoked` to superseded token**  
**CF enforcement: epoch check on sensitive callables**

### Rationale

| Approach | Pros | Cons | Tilawa fit |
|----------|------|------|------------|
| Auth revocation only | Strong; built-in | ID token valid ~1h; no instant UI | Fallback, not primary |
| Session epoch | Instant after 1 field read; cheap | Needs client + CF checks | **Primary** |
| `activeDeviceId` only | Simple | Token refresh can look like new device if mishandled | Pair with FID |
| CF-only enforcement | Secure mutations | Firestore reads still work until blocked | Required for Quran Sessions |
| FCM-only | Cheap push | **Does not revoke API access** | UX only — rejected as sole strategy |

### Single active device flow (requirement 2)

```
Device B (new login)
  → Google sign-in (Firebase Auth)
  → registerActiveDevice CF { deviceId, fcmToken, platform, appVersion? }
      TX:
        read users/{uid}.session
        if deviceId != activeDeviceId:
          session.epoch += 1
          session.activeDeviceId = deviceId
          notifications.activeFcmToken = fcmToken
          delete all fcm_tokens/* (legacy)
        else:
          update token only (same device, token refresh)
        revokeRefreshTokens(uid)   // when device changed only
        if previousToken: send data push session_revoked
      return { epoch, activeDeviceId }
  → client persists epoch + deviceId locally

Device A (old)
  → FCM session_revoked → SessionRevokedNotifier → SignOut + dialog
  → OR app resume / before CF call: get users/{uid} session.epoch
      if local epoch < server: force sign-out
  → CF createSessionBooking: requireSessionEpoch(request, uid) → failed-precondition
```

### Access invalidation (requirement 3)

Not FCM-only. Layers:

1. **Immediate UX:** FCM `session_revoked` → `AuthBloc` sign-out (mirror `TeacherCapabilityRefreshNotifier`).
2. **Auth layer:** `revokeRefreshTokens` — old device cannot refresh; periodic `getIdToken(true)` fails.
3. **App layer:** epoch mismatch on resume + pre-callable check.
4. **Server layer:** `requireValidSessionEpoch` in `sessionAuth.ts` for all Quran Sessions callables.

### Notification targeting (requirement 4)

Change `sendPushToUsers`:

```typescript
// Before: subcollection .get() → all tokens
// After: users/{uid}.notifications.activeFcmToken (batch get with FieldMask)
```

- `sendEachForMulticast` with 1 token per user (or `send` for single).
- `reviewTeacherApplication`, `deliverSessionNotification`, `index.ts` campaign sender — same helper.
- Invalid token → CF clears `notifications.activeFcmToken` only.

---

## 3. Recommended Firestore rules (sketch)

```javascript
function sessionFieldsUnchanged() {
  let before = resource.data;
  let after = request.resource.data;
  return after.get('session', {}) == before.get('session', {})
      && after.get('notifications', {}) == before.get('notifications', {});
}

match /users/{userId} {
  allow update: if isAdmin()
    || (isOwner(userId)
        && quranSessionsProfileModerationUnchanged()
        && sessionFieldsUnchanged());

  match /fcm_tokens/{tokenId} {
    allow read: if isOwner(userId);   // migration read-only optional
    allow write: if false;             // CF Admin SDK only
  }
}
```

- Client **cannot** write `session.*` or `notifications.*`.
- Client **may read** `session.epoch` + `session.activeDeviceId` for local compare (or CF returns epoch in `registerActiveDevice` response only — stricter).
- `create` on users: `session` / `notifications` absent or defaults only.

**Rules tests:** new `functions/test-rules/activeDevice.rules.test.ts` — owner cannot bump epoch, cannot write `activeFcmToken`, cannot write `fcm_tokens`.

---

## 4. Files likely to change

### Cloud Functions

| Path | Change |
|------|--------|
| `functions/src/registerActiveDevice.ts` | **New** callable |
| `functions/src/quranSessions/fcmTokenService.ts` | Read embedded token; `getActiveFcmToken(db, uid)` |
| `functions/src/quranSessions/sessionAuth.ts` | `requireValidSessionEpoch(request, uid)` |
| `functions/src/index.ts` | `collectTokens` migration; export callable |
| `functions/src/reviewTeacherApplication.ts` | Uses new token helper (no logic change) |
| `functions/src/quranSessions/deliverSessionNotification.ts` | Same |
| All `functions/src/quranSessions/*Callables.ts` | Epoch guard at top |
| `functions/test/registerActiveDevice.test.ts` | **New** |
| `functions/test/quranSessions/fcmTokenService.test.ts` | **New** |
| `functions/test-rules/activeDevice.rules.test.ts` | **New** |

### Flutter app — auth / notifications

| Path | Change |
|------|--------|
| `apps/tilawa/lib/features/auth/domain/usecases/sync_device_token_use_case.dart` | Delegate to `RegisterActiveDeviceUseCase` |
| `apps/tilawa/lib/features/auth/domain/usecases/register_active_device_use_case.dart` | **New** |
| `apps/tilawa/lib/features/auth/data/repositories/user_repository_impl.dart` | Remove direct `fcm_tokens` writes |
| `apps/tilawa/lib/features/auth/domain/services/token_sync_cache.dart` | Add epoch + deviceId |
| `apps/tilawa/lib/features/auth/data/services/token_sync_cache_impl.dart` | Persist new keys |
| `apps/tilawa/lib/features/auth/data/datasources/active_device_remote_data_source.dart` | **New** — `httpsCallable('registerActiveDevice')` |
| `apps/tilawa/lib/features/notifications/data/datasources/notifications_remote_data_source.dart` | Remove `saveToken` Firestore write |
| `apps/tilawa/lib/features/notifications/data/services/fcm_service.dart` | Call register after token refresh |
| `apps/tilawa/lib/features/auth/presentation/bloc/auth_bloc.dart` | Register on sign-in |
| `apps/tilawa/lib/core/services/device_token_service.dart` | Optional: expose FID via new `DeviceIdentityService` |
| `apps/tilawa/lib/core/di/external_dependencies_module.dart` | Register new deps; add `firebase_app_installations` |
| `apps/tilawa/lib/core/bootstrap/app_startup_tasks.dart` | Session validity check on resume (lightweight) |

### Session revoked UX (mirror teacher capability pattern)

| Path | Change |
|------|--------|
| `apps/tilawa/lib/features/auth/domain/services/session_revoked_notifier.dart` | **New** (like `TeacherCapabilityRefreshNotifier`) |
| `apps/tilawa/lib/features/notifications/data/repositories/notifications_repository_impl.dart` | Handle `session_revoked` in foreground |
| `apps/tilawa/lib/features/auth/presentation/cubit/session_validity_cubit.dart` | **New** — resume epoch check |
| `apps/tilawa/lib/tilawa_app.dart` | Mount global listener / dialog host |

### Rules & docs

| Path | Change |
|------|--------|
| `firestore.rules` | Session + notifications immutability; lock `fcm_tokens` |
| `docs/quran_sessions_firestore_data_model.md` | Document new fields |
| `specs/037-quran-session-free-beta-closure/single-active-device-fcm-design.md` | This spec |

### Migration

| Path | Change |
|------|--------|
| `functions/scripts/migrateFcmTokensToActiveField.ts` | **New** — pick newest token per user, set embedded, delete subcollection |

---

## 5. Tests to add

### Unit — Flutter

| Test | Covers |
|------|--------|
| `register_active_device_use_case_test.dart` | CF success → cache epoch; `Either` failure paths |
| `sync_device_token_use_case_test.dart` | Routes to register; no direct Firestore |
| `session_revoked_notifier_test.dart` | Dedupes FCM retries |
| `session_validity_cubit_test.dart` | Epoch mismatch → emit revoked |
| `fcm_service_test.dart` | Token refresh calls register |
| `auth_bloc_test.dart` | Sign-in triggers register |
| `notifications_repository_impl_test.dart` | `session_revoked` foreground handler |

### Unit — Functions

| Test | Covers |
|------|--------|
| `registerActiveDevice.test.ts` | New device bumps epoch, revokes, sends push; same device token-only update |
| `fcmTokenService.test.ts` | Reads embedded token; handles missing |
| `sessionAuth.test.ts` | `requireValidSessionEpoch` rejects stale |

### Rules

| Test | Covers |
|------|--------|
| `activeDevice.rules.test.ts` | Owner cannot write session/notifications/fcm_tokens |

### Integration

| Test | Covers |
|------|--------|
| `functions/test-integration/activeDevice.integration.test.ts` | Emulator: register A → register B → A epoch stale |
| `apps/tilawa` emulator test (optional P1) | Callable + sign-out flow |

### Test matrix (requirement 6)

| Scenario | Device A | Device B | Expected |
|----------|----------|----------|----------|
| T1 Fresh login same device | — | login | epoch unchanged; token updated |
| T2 Login second device | logged in | login | A revoked; B active; push to B only |
| T3 Token refresh same device | logged in | — | epoch unchanged; new FCM token |
| T4 Sign out voluntary | sign out | — | token cleared; epoch unchanged |
| T5 A offline at B login | offline | login | A signs out on resume / next CF |
| T6 A mid-session booking | booking open | login | CF fails on A; UI redirects |
| T7 Teacher approval push | old device | B active | push only to B |
| T8 Re-login same device after B | B logout, A login | — | A becomes active again |
| T9 Delete account | — | — | tokens + session cleared |
| T10 Invalid FCM token | — | — | CF clears `activeFcmToken` |

---

## 6. Risks and limitations

| Risk | Impact | Mitigation |
|------|--------|------------|
| **ID token grace period** | A works up to ~1h without epoch check | Resume check + pre-callable check + CF epoch guard |
| **FCM not delivered** | A stays until resume | Epoch check on resume; optional periodic check (P1, no listener) |
| **Token refresh ≠ new device** | False revoke if deviceId unstable | Use **Firebase Installations ID**, not FCM token as device id |
| **Multi-tab (web)** | Same FID → OK; different browsers → last wins | Document; web P1 |
| **iOS background** | Delayed FCM / resume | `WidgetsBindingObserver` epoch check (existing pattern in Settings) |
| **Android OEM kill** | Same | Resume check |
| **Offline old device** | Stale local state | CF rejects; Firestore reads for own profile still possible — **sensitive collections already CF-only** |
| **Admin panel (`tilawa_admin`)** | Same Google account on 2 browsers kicks one | P1: exempt `admin` claim from epoch check OR separate admin service accounts |
| **Web FCM** | Limited / no GMS | P1; gate register on `kIsWeb` |
| **Prayer local notifications** | Unaffected | Session revoke does not cancel scheduled local alarms |
| **Cost regression** | Epoch polling | **No listeners**; FCM-triggered + resume + pre-callable only |
| **Migration** | Users with 0 or many tokens | Script: newest `createdAt` wins; empty → register on next app open |
| **`enforceAppCheck: false`** | Callable abuse | P1 prod: enable on `registerActiveDevice` |

---

## 7. P0 Free Beta vs P1

### P0 (Free Beta) — justify

| Item | Why P0 |
|------|--------|
| `registerActiveDevice` CF + embedded `notifications.activeFcmToken` | Product rule; fixes multi-push; **reduces Firestore reads on every notification** |
| `session.epoch` + CF guard on Quran Sessions callables | Teachers/students must not operate from 2 devices during beta |
| Client revoke flow (FCM + resume epoch check) | User-visible security; avoids “ghost teacher” on old phone |
| Rules lockdown (`fcm_tokens` write deny) | Closes spoof-token attack |
| `sendPushToUsers` migration | `reviewTeacherApplication` + session notifications must hit **active** device only |
| Migration script for existing tokens | Avoid “No FCM tokens found” after deploy |

### P1 — justify defer

| Item | Why P1 |
|------|--------|
| App Check on `registerActiveDevice` | Staging uses `enforceAppCheck: false` today; prod gate |
| Web single-device | Mobile-first beta |
| Admin multi-session exemption | Low volume; use dedicated admin accounts short-term |
| Device management UI (“Logged in on Pixel 7”) | No product ask |
| `fcm_tokens` subcollection removal audit trail | Cleanup after stable migration |
| Background periodic epoch poll (WorkManager) | Resume + FCM sufficient for beta |
| Custom claims `sessionEpoch` | Firestore field enough |

---

## User requirements 1–8 (explicit)

### 1. Token storage fields
See §1 table — embedded `notifications.*` + `session.*` on `users/{uid}`.

### 2. Single active device flow
See §2 diagram — `registerActiveDevice` on sign-in + token refresh.

### 3. Access invalidation (not FCM-only)
Epoch + `revokeRefreshTokens` + CF callable guards + client sign-out.

### 4. Notification targeting
Single `activeFcmToken` read; update `fcmTokenService.ts` + `index.ts` campaign path.

### 5. Security (CF-controlled registration)
Remove client Firestore token writes; callable owns all `session` / `notifications` mutations.

### 6. Test matrix
See §5 table T1–T10.

### 7. UX ARB string keys (suggestion)

```json
"authSignedInElsewhereTitle": "Signed in on another device",
"authSignedInElsewhereBody": "Your account was opened on another device. Sign in again to continue on this device.",
"authSignedInElsewhereAction": "Sign in again"
```

Arabic (`app_ar.arb`): mirror tone of existing auth errors — calm, no blame.

Wire via `TilawaFeedbackHost` or dialog from `SessionValidityCubit` listening to `SessionRevokedNotifier`.

### 8. Clean architecture layers

```
presentation/
  SessionValidityCubit / dialog
  AuthBloc → triggers register on success
  NotificationsRepositoryImpl → FCM session_revoked

domain/
  RegisterActiveDeviceUseCase → Either<Failure, SessionRegistration>
  CheckSessionValidityUseCase → Either<Failure, bool>
  SessionRevokedNotifier (domain service)
  SessionLocalStore (extends TokenSyncCache contract)

data/
  ActiveDeviceRemoteDataSource → FirebaseFunctions httpsCallable
  Remove Firestore writes from UserRepositoryImpl token methods
  DeviceIdentityService → FID + platform

CF (server)
  registerActiveDevice.ts
  sessionAuth.requireValidSessionEpoch
  fcmTokenService.getActiveFcmToken
```

Follow existing patterns: **get_it** `@injectable`, **Cubit** for UI state, **Either** for use cases, **CF callables** `us-central1`, cost-safe **FCM → Notifier → one-shot refresh** (same as `TeacherCapabilityRefreshNotifier`).

---

## Cost note

| Operation | Today | Proposed |
|-----------|-------|----------|
| Push to 1 user | 1+ subcollection reads (N docs) | 1 `users/{uid}` field read |
| Session validity | None | 0 ongoing; 1 field read on resume / pre-callable |
| Realtime listener | N/A | **Avoid** — use FCM + resume |

---

## Summary

Design centers on **embedded `session.epoch` + `notifications.activeFcmToken`** on `users/{uid}`, **`registerActiveDevice` callable** (replacing client `fcm_tokens` writes), **epoch guards in Quran Sessions CFs**, and **FCM `session_revoked` + resume check** mirroring the teacher-capability pattern. P0 covers beta security + notification cost; P1 covers App Check, web, admin exemptions.
