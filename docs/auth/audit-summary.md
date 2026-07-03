# Auth audit summary (Tilawa mobile app)

Date: 2026-07-03

## Firebase Auth integration

- **SDK:** `firebase_auth ^6.5.1` in `apps/tilawa`.
- **Provider wiring:** `GoogleAuthProviderImpl` is registered as the sole
  `AuthProviderInterface` implementation. It owns `FirebaseAuth` session
  lifecycle (`authStateChanges`, `currentUser`, `signOut`).
- **Repository:** `AuthRepositoryImpl` delegates Google sign-in to the provider
  and pre-warms Credential Manager via `GoogleSignInPrepareDataSource`.
- **State:** `AuthBloc` (HydratedBloc) persists authenticated user JSON locally.
  States: `initial`, `loading`, `authenticated`, `unauthenticated`, `error`,
  `noGoogleAccounts`.
- **Gap (pre-change):** No email/password provider, gateway, or UI.

## Google Sign-In flow

1. Login screen dispatches `SignInWithGoogleEvent` via `LoginGoogleSignInCubit`
   launch gate (offline / App Check / UI readiness).
2. `SignInWithGoogleUseCase` → `AuthRepository.signInWithGoogle()` →
   `GoogleAuthProviderImpl.signIn()`.
3. Platform paths: Android Credential Manager (with OEM fallbacks), iOS
   lightweight + `authenticate()` fallback.
4. On success: `UserRepository.saveUserData` (Firestore merge on `users/{uid}`),
   device token registration, language sync, navigate home.
5. Google Sign-In is **not weakened** by email/password work — separate gateway
  and UI entry; shared Firebase session only.

## User profile creation flow

- **App profile:** `UserRepositoryImpl.saveUserData` merges
  `email`, `displayName`, `photoUrl`, `lastSignInTime`, `createdAt` into
  `users/{uid}`.
- **Quran Sessions profile:** `FirestoreUserProfileDataSource.getOrCreateProfile`
  creates `quranSessionsProfile` shell with `profileCompleted: false` on first
  access (not at auth time).
- **Profile completion:** `ProfileCompletionScreen` + `ProfileCompletionBloc`
  in `packages/quran_sessions`. Sets gender, DOB, country, city, learning goals;
  writes `profileCompleted: true` when required fields present.
- **Booking gate:** `ValidateBookingEligibilityUseCase` returns
  `ProfileIncompleteFailure` when `student.isComplete` is false.

## Duplicate emails / accounts

- **Firebase Auth** enforces one UID per email per project.
- **Pre-change risk:** Google sign-in and Firestore `saveUserData` both use
  `SetOptions(merge: true)` on `users/{uid}` keyed by Firebase UID — no duplicate
  Firestore docs for the same Firebase user.
- **Cross-provider same email:** Firebase returns
  `account-exists-with-different-credential` (Google after email/password) or
  `email-already-in-use` (register). Pre-change: raw Firebase messages surfaced
  to UI for Google path only.
- **Policy implemented:** See [duplicate-email-policy.md](./duplicate-email-policy.md).

## Account deletion and linking

- **Deletion:** `DeleteAccount` use case calls Cloud Function
  `requestSelfAccountDeletion`, clears device token + premium cache, then
  `signOut`. Does not call `AuthProvider.deleteAccount()` directly.
- **Provider deleteAccount:** Google-only re-auth via account chooser when
  `requires-recent-login`.
- **Linking:** No silent account linking in mobile app. Explicit provider
  conflict messages only.

## Security notes

- Passwords never stored in Firestore or repo — Firebase Auth only.
- App Check + `ServerActionGuard` gate Google sign-in and delete account.
- Email/password flows use the same guards where applicable.
- Verification email sent after registration (non-blocking for app entry).
- Rate limits mapped to typed `tooManyRequests` failure.

## Remaining risks

- Email/password re-auth for direct Firebase `user.delete()` not exposed in
  self-service delete flow (Cloud Function handles deletion).
- Account linking UI (merge Google + password) deferred — conflict messages only.
- Email verification not enforced before Quran Sessions booking (optional future
  gate).
