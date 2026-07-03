# Duplicate email / provider conflict policy

## Principles

1. **One Firebase Auth user per email** — Firebase is source of truth for UID.
2. **One Firestore `users/{uid}` doc per UID** — always merge, never create a
   second doc for the same auth user.
3. **No silent merge** — app never auto-links Google and password providers.
4. **Clear user messaging** — typed failures with localized copy.

## Scenarios

### A. Register with email when Google account exists

- Firebase: `email-already-in-use`.
- App: `EmailAuthFailureKey.emailAlreadyInUseWithGoogle` when provider hint is
  Google; otherwise `emailAlreadyInUse`.
- User action: Sign in with Google (or existing method).

### B. Google sign-in when email/password account exists

- Firebase: `account-exists-with-different-credential`.
- App: `EmailAuthFailureKey.accountExistsWithDifferentCredential` with
  `existingProvider: password`.
- User action: Sign in with email and password first. Linking deferred.

### C. Login with wrong method

- Wrong password: `wrongPassword`.
- Unknown email: `userNotFound` (generic message — no account enumeration).
- Invalid credential: `invalidCredential`.

### D. Same user, same provider

- Normal sign-in; Firestore profile merged by UID — no duplicate profile.

## Implementation

- `FirebaseAuthExceptionMapper` maps Firebase codes → `EmailAuthFailureKey`.
- Google provider maps `account-exists-with-different-credential` to the same
  key family for consistent UI.
- Registration never creates a Firestore profile before Auth UID exists.

## Out of scope (follow-up)

- In-app “Link Google account” settings flow.
- Admin-driven account merge.
- `fetchSignInMethodsForEmail` (deprecated in Firebase Auth v6) — rely on
  exception codes and credential hints.
