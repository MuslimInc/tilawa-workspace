# Quran Sessions — Maestro staging smoke

Device QA accelerators for **staging** (`quran-playera-app`). Smoke only — no new product behavior.

Canonical setup: [`docs/quran-sessions/maestro-device-qa-setup.md`](../../docs/quran-sessions/maestro-device-qa-setup.md).

## Account setup (existing Google uids)

Staging accounts are real Google-auth users. To enable **Email/Password on the same uid** (for vault/CI without creating duplicates):

```sh
cd functions
export GOOGLE_APPLICATION_CREDENTIALS=/path/to/service-account.json
npm run verify:quran-staging-existing-auth-accounts

export MAESTRO_QURAN_TEACHER_PASSWORD='***'   # local vault only
export MAESTRO_QURAN_STUDENT_PASSWORD='***'
npm run seed:quran-staging-existing-maestro-accounts          # dry run
npm run seed:quran-staging-existing-maestro-accounts:apply    # merge writes
```

Passwords are never printed or stored in the repo. Seed uses `auth.updateUser({ password })` on the existing uid only.

## Staging QA join-window bypass

Two Maestro accounts may **join outside the normal 15-minute window** on staging only (`TILAWA_DISTRIBUTION=staging`, project `quran-playera-app`). Production / `play_production` never apply the override. Lifecycle checks (cancelled, completed, wrong participant, etc.) still apply.

| Account | Email | UID |
|---------|-------|-----|
| Teacher | `mu7ammadkamel@hotmail.com` | `WV0m6tenTJPDLZE4EdWXBzjADF12` |
| Student | `mohammad.kamel@othaimmarkets.com` | `U33e4w08bYWFOuS7NTxoHmvDFxM2` |

Server logs: `[QA] join-window bypass applied for uid=…` when the override is used.

## Flows

| Flow | Role | Scope |
|------|------|--------|
| `staging_student_smoke.yaml` | Student | Login → hub → book video-only → pending/upcoming → cancel |
| `staging_teacher_dashboard_smoke.yaml` | Teacher | Login → dashboard → no external meeting link |
| `staging_student_hub_booking_smoke.yaml` | Student (partial) | Hub entry only — superseded by full student smoke |

**Do not mix roles in one flow.** Sign out between student and teacher runs (`subflows/staging_sign_out.yaml`).

## Env vars

Copy `.env.example` → `.env` (gitignored). Or pass via CLI:

```sh
maestro test .maestro/quran_sessions/staging_student_smoke.yaml \
  --device emulator-5554 \
  -e MAESTRO_QURAN_STUDENT_EMAIL='mohammad.kamel@othaimmarkets.com' \
  -e MAESTRO_QURAN_STUDENT_PASSWORD='***'
```

| Variable | Purpose |
|----------|---------|
| `MAESTRO_QURAN_STUDENT_EMAIL` | Student account (Google / email) |
| `MAESTRO_QURAN_STUDENT_PASSWORD` | Local vault — used after seed links password to same uid |
| `MAESTRO_QURAN_TEACHER_EMAIL` | Teacher account |
| `MAESTRO_QURAN_TEACHER_PASSWORD` | Local vault — used after seed links password to same uid |
| `MAESTRO_TILAWA_*` | Legacy aliases for existing YAML subflows |

Never commit real passwords.

## Subflows

| File | Purpose |
|------|---------|
| `subflows/staging_google_sign_in.yaml` | Fresh launch + Google account picker |
| `subflows/staging_sign_out.yaml` | Settings → logout |

App ID: `com.tilawa.app`.
