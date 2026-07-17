# iOS App Check — Debug / Simulator Setup

**Firebase project:** `quran-playera-app`

| Flavor | Bundle ID | Firebase iOS app ID |
|--------|-----------|---------------------|
| development | `com.tilawa.app.dev` | `1:181575856185:ios:4c3a8e674c6138d0381de8` |
| staging | `com.tilawa.app.staging` | `1:181575856185:ios:122febc64df470f2381de8` |
| production (MeMuslim / TestFlight) | `com.memuslim.app` | `1:181575856185:ios:c2b2bf0966057dfd381de8` |

Legacy `com.tilawa.app` (`…:ios:3f02220381ba118d381de8`) is not the MeMuslim
TestFlight target — register **App Check** for `com.memuslim.app` separately.

Use this when Google Sign-In succeeds but sign-in ends with
`authDeviceRegistrationFailed`, or Xcode logs show:

- `App not registered: 1:181575856185:ios:3f02220381ba118d381de8`
- `DeviceCheck token exchange 400 FAILED_PRECONDITION`
- `FirebaseAuth/... placeholder App Check token`

---

## Root cause (typical)

1. **iOS app not registered in App Check** — Firebase rejects DeviceCheck /
   debug token exchange until the app exists under App Check.
2. **Simulator / debug used production attestation** — DeviceCheck and App
   Attest do not work on the iOS Simulator. Non-release builds must use the
   **App Check debug provider** (see `app_startup_tasks.dart`).
3. **Device registration needs a valid App Check token** when App Check
   enforcement is enabled for Cloud Functions, Firestore, or Authentication in
   the Firebase Console. `registerActiveDevice` runs immediately after Google
   sign-in; a rejected token surfaces as `authDeviceRegistrationFailed`.

Release Android/iOS production behavior is unchanged: Play Integrity and
App Attest + DeviceCheck only in **release** builds.

---

## Firebase Console steps (one-time per project)

### 1. Register the iOS app in App Check

1. Open [Firebase Console](https://console.firebase.google.com/) → project
   **quran-playera-app**.
2. **Build** → **App Check**.
3. If the iOS app you are testing is missing (e.g. `com.memuslim.app` for
   TestFlight), click **Register** and select that iOS app.
4. For **production** attestation, enable **Device Check** (and optionally App
   Attest) for that app. Save.

### 2. Add a debug token (simulator / local dev)

1. Run the app in **Debug** or **Profile** from Xcode or:

   ```sh
   cd apps/tilawa
   flutter run --dart-define=TILAWA_DISTRIBUTION=staging
   ```

2. Find the debug token in logs:
   - Flutter: `[AppCheck] Register this debug token in Firebase Console…`
   - Xcode native: search for `Firebase App Check Debug Token`
3. **App Check** → **Apps** → iOS app → **Manage debug tokens** → **Add debug
   token** → paste → Save.

Repeat when the token changes (new simulator, clean install, or new machine).

### 3. Confirm enforcement scope (staging)

Under **App Check** → **APIs**, note which products enforce App Check:

| API | Staging recommendation |
|-----|------------------------|
| Cloud Functions | OK to enforce after debug token registered; `registerActiveDevice` uses `enforceAppCheck` only when `QURAN_SESSIONS_ENFORCE_APP_CHECK=true` at deploy |
| Cloud Firestore | If enforced, debug token required for client writes (e.g. `users/{uid}` on sign-in) |
| Authentication | If enforced, debug token required for sign-in flows |

For local simulator dev, either register the debug token **or** set enforcement
to **Unenforced** for the APIs you are not testing.

---

## Verify

1. Clean run on iOS Simulator (Debug + `TILAWA_DISTRIBUTION=staging`).
2. Xcode / Flutter logs: no `App not registered` or `FAILED_PRECONDITION` for
   DeviceCheck; App Check token is not a placeholder.
3. Google Sign-In completes → home screen (no `authDeviceRegistrationFailed`).
4. Optional: Firebase Console → App Check → **Metrics** shows successful
   debug token validations.

---

## Related

- Client activation: `apps/tilawa/lib/core/bootstrap/app_startup_tasks.dart`
- Device registration callable: `functions/src/registerActiveDevice.ts`
- Staging CF enforcement runbook:
  [app_check_staging_verification.md](../quran_sessions/app_check_staging_verification.md)

