# Tilawa mobile authentication docs

| Document | Purpose |
|----------|---------|
| [audit-summary.md](./audit-summary.md) | Pre/post implementation auth audit |
| [email-password-flow.md](./email-password-flow.md) | Registration, login, profile completion routing |
| [duplicate-email-policy.md](./duplicate-email-policy.md) | Cross-provider conflict handling |

## Firebase Console checklist

1. Enable **Email/Password** provider in Firebase Auth (staging + production).
2. Keep **Google** provider enabled (unchanged).
3. Optional: customize email verification and password reset templates.

## Maestro / QA credentials

Store test accounts in `.maestro/quran_sessions/.env` (gitignored). Never commit passwords.
