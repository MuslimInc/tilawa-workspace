# Email & password auth flow

## Screens

| Screen | Route | Purpose |
|--------|-------|---------|
| Login (existing) | `/login` | Google + link to email sign-in / register |
| Email login | `/login/email` | Email, password, forgot password |
| Register | `/login/register` | Three-step email registration wizard |
| Forgot password | `/login/forgot-password` | Password reset email |
| Profile completion (Learn Quran) | `/sessions/profile/complete?learnQuran=true` | Quran Sessions fields before hub/booking |

## Registration (general app account only)

1. User opens **Register** from login screen.
2. Three-step wizard: **Account** → **Basic profile** → **Review & create**.
   - Account: email, password, confirm password.
   - Basic profile: display name, preferred app language.
   - Review: summary, then **Create account**.
3. `EmailRegistrationCubit` validates each step; data kept in memory until final submit.
4. Final **Create account** → `RegisterWithEmailUseCase` → Firebase `createUserWithEmailAndPassword`.
5. On success:
   - `UserRepository.saveCompleteEmailRegistration` writes the **general** user doc
     (`profileCompleted: true` at top level) plus an **incomplete**
     `quranSessionsProfile` shell (`profileCompleted: false`).
   - Verification email sent (best-effort, non-blocking).
   - Post-auth navigation → **Home** (same as Google sign-in).
6. On auth failure: typed `EmailAuthFailureKey` → localized toast.
7. On Firestore failure after auth: retry on registration screen.

Quran Sessions fields (gender, DOB, country, city, learning goals, guardian)
are **not** collected during registration.

## Login

1. User opens **Sign in with email** from login screen.
2. Validation → `SignInWithEmailUseCase`.
3. Firebase `signInWithEmailAndPassword`.
4. On success: same post-auth path as Google (device token, language sync) → **Home**.
5. Forgot password → reset email flow.

## Profile concepts

| Layer | Firestore path | `profileCompleted` | Required fields |
|-------|----------------|-------------------|-----------------|
| General app | `users/{uid}` | Top-level; `true` after email reg or Google when display name present | displayName, languageCode (email reg) |
| Quran Sessions | `users/{uid}.quranSessionsProfile` | Nested; `true` only after Learn Quran completion flow | gender, DOB, countryCode, cityId |

## Learn Quran gate (Quran Sessions only)

- **Home dashboard entry** and **direct hub routes** call
  `ensureQuranSessionsProfileReady` before showing Learn Quran.
- Incomplete → profile completion with Learn Quran messaging
  (`?learnQuran=true`).
- **Before booking:** `ValidateBookingEligibilityUseCase` still blocks incomplete
  profiles (`ProfileIncompleteFailure`).
- **Child accounts:** same booking path as adults; teacher `canTeachChildren` gate only at booking.

## Post-auth navigation

Google and email sign-in both resolve to **Home**. Mandatory Quran profile
completion is no longer part of global auth.

## Auth states

| State | When |
|-------|------|
| `unauthenticated` | No session |
| `loading` | Sign-in/register in flight |
| `authenticated` | Firebase session active |
| `error` | Typed failure key in `message` |
| `noGoogleAccounts` | Google-only |

Email verification does not block `authenticated`; optional future
`emailNotVerified` state documented in audit.

## Architecture

```
Presentation (screens, EmailAuthFormCubit, AuthBloc)
    → Use cases (SignInWithEmail, RegisterWithEmail, SendPasswordReset)
        → AuthRepository
            → EmailPasswordAuthGateway (domain)
                → FirebaseEmailPasswordAuthGateway (data)
```

Firebase details stay in `data/mappers/firebase_auth_exception_mapper.dart`.

## Migration notes (`profileCompleted` split)

- **Existing users** with `quranSessionsProfile.profileCompleted: true` from the
  old registration flow: Quran Sessions eligibility unchanged (`UserProfile.isComplete`).
- **New email registrations** write top-level `profileCompleted: true` and
  nested `quranSessionsProfile.profileCompleted: false`.
- **Post-auth routing** no longer reads `UserProfile.isComplete`; use Learn Quran
  entry gates and booking eligibility instead.
- Optional backfill: set top-level `profileCompleted: true` for legacy users who
  already have `displayName` on the user doc.
