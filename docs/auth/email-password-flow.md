# Email & password auth flow

## Screens

| Screen | Route | Purpose |
|--------|-------|---------|
| Login (existing) | `/login` | Google + link to email sign-in / register |
| Email login | `/login/email` | Email, password, forgot password |
| Register | `/login/register` | Multi-step email registration wizard |
| Forgot password | `/login/forgot-password` | Password reset email |
| Profile completion (existing) | `/sessions/profile/complete` | Required after registration |

## Registration

1. User opens **Register** from login screen.
2. Five-step wizard (account → personal → Quran learning → guardian if minor → review).
3. `EmailRegistrationCubit` validates each step; data kept in memory until final submit.
4. Final **Create account** → `RegisterWithEmailUseCase` → Firebase `createUserWithEmailAndPassword`.
5. On success:
   - `UserRepository.saveCompleteEmailRegistration` (merge, `profileCompleted: true`).
   - Verification email sent (best-effort, non-blocking).
   - `AuthBloc` → `authenticated` → **Home** when profile complete.
6. On auth failure: typed `EmailAuthFailureKey` → localized toast.
7. On Firestore failure after auth: retry on registration screen or profile completion after login.

## Login

1. User opens **Sign in with email** from login screen.
2. Validation → `SignInWithEmailUseCase`.
3. Firebase `signInWithEmailAndPassword`.
4. On success: same post-auth path as Google (device token, language sync) → **Home**.
5. Forgot password → reset email flow.

## Profile completion gate (Quran Sessions)

- **After register:** profile is complete; user enters app via normal post-auth routing.
- **After login with incomplete profile:** mandatory profile completion (recovery).
- **Before booking:** `ValidateBookingEligibilityUseCase` blocks incomplete
  profiles (`ProfileIncompleteFailure`).
- **Child accounts:** guardian gate unchanged (`GuardianApprovalRequiredFailure`).

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
