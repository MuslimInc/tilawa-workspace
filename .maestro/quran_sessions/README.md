# Quran Sessions — Maestro staging smoke

Device QA accelerators for **staging** (`quran-playera-app`). Smoke only — no new product behavior.

Canonical setup: [`docs/quran-sessions/maestro-device-qa-setup.md`](../../docs/quran-sessions/maestro-device-qa-setup.md).

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
  -e MAESTRO_TILAWA_STUDENT_EMAIL='mohammad.kamel@othaimmarkets.com' \
  -e MAESTRO_TILAWA_STUDENT_PASSWORD='***'
```

Password vars are **not used by the app** (Google Sign-In only); keep them out of git.

## Subflows

| File | Purpose |
|------|---------|
| `subflows/staging_google_sign_in.yaml` | Fresh launch + Google account picker |
| `subflows/staging_sign_out.yaml` | Settings → logout |

App ID: `com.tilawa.app`.
