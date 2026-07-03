# Quran Sessions — Maestro device QA setup

Staging smoke automation for **student booking** and **teacher dashboard** on real Firebase (`quran-playera-app`). Maestro accelerates manual D1–D8 checks; it does not replace integration tests.

Related: [`staging-post-apply-verification.md`](staging-post-apply-verification.md), [`.maestro/quran_sessions/README.md`](../../.maestro/quran_sessions/README.md).

---

## Prerequisites

| Item | Requirement |
|------|-------------|
| Device | Android emulator or physical device with `com.tilawa.app` installed |
| Maestro | CLI ≥ 2.5 (`maestro --version`) |
| Firebase | Staging project `quran-playera-app` — **fake backend disabled** |
| Accounts | Student + teacher Google accounts (emails below; passwords never in repo) |

### Test accounts (Google Sign-In)

| Role | Email |
|------|--------|
| Teacher / admin QA | `mu7ammadkamel@hotmail.com` |
| Student QA | `mohammad.kamel@othaimmarkets.com` |

Tilawa auth is **Google OAuth only**. Password env vars are vault placeholders for CI docs; the app never reads them.

**Student account** must have completed Quran Sessions profile (EG / cairo). **Teacher account** must be a verified teacher with weekly availability (open slot for booking smoke).

---

## Staging build (required dart-defines)

From `apps/tilawa`:

```sh
flutter run -d <device_id> \
  --dart-define=TILAWA_DISTRIBUTION=staging \
  --dart-define=TILAWA_LAUNCH_LEARN_QURAN_STUDENT_FEATURE_ENABLED=true \
  --dart-define=TILAWA_LAUNCH_QURAN_SESSIONS_BOOKING_ENABLED=true
```

Do **not** set `USE_QURAN_SESSIONS_MVP_FAKE` or `TILAWA_QURAN_SESSIONS_BACKEND=fake` on staging.

Optional Agora/mock providers (if your local launch profile already uses them):

```sh
  --dart-define=TILAWA_LAUNCH_ENABLED_CALL_PROVIDERS=mock,agora \
  --dart-define=TILAWA_LAUNCH_AGORA_APP_ID=aacd48a930944ecea29bec112f229eb9
```

Cold install after flag changes — confirm Home shows **تعلّم القرآن** / **ابدأ التعلّم** before student smoke.

---

## Environment variables

Copy [`.maestro/quran_sessions/.env.example`](../../.maestro/quran_sessions/.env.example) to `.maestro/quran_sessions/.env` (gitignored).

| Variable | Used by | Notes |
|----------|---------|--------|
| `MAESTRO_TILAWA_STUDENT_EMAIL` | Student flow login subflow | Required unless `MAESTRO_SKIP_LOGIN=true` |
| `MAESTRO_TILAWA_STUDENT_PASSWORD` | — | Not used; keep in local vault only |
| `MAESTRO_TILAWA_TEACHER_EMAIL` | Teacher flow login subflow | Required unless skip login |
| `MAESTRO_TILAWA_TEACHER_PASSWORD` | — | Not used; keep in local vault only |
| `MAESTRO_SKIP_LOGIN` | Both flows | Set `true` when already signed in as the correct role |

### Export example (shell)

```sh
export MAESTRO_TILAWA_STUDENT_EMAIL='mohammad.kamel@othaimmarkets.com'
export MAESTRO_TILAWA_STUDENT_PASSWORD='***'   # local only — never commit
export MAESTRO_TILAWA_TEACHER_EMAIL='mu7ammadkamel@hotmail.com'
export MAESTRO_TILAWA_TEACHER_PASSWORD='***'
```

### CLI `-e` example

```sh
maestro test .maestro/quran_sessions/staging_student_smoke.yaml \
  --device emulator-5554 \
  -e MAESTRO_TILAWA_STUDENT_EMAIL="$MAESTRO_TILAWA_STUDENT_EMAIL" \
  -e MAESTRO_TILAWA_STUDENT_PASSWORD="$MAESTRO_TILAWA_STUDENT_PASSWORD"
```

---

## Running flows (separate roles)

**Never mix student and teacher in one flow.** Sign out between runs:

```sh
maestro test .maestro/quran_sessions/subflows/staging_sign_out.yaml --device emulator-5554
```

### Student smoke (full D1–D3, D8 subset)

```sh
maestro test .maestro/quran_sessions/staging_student_smoke.yaml --device emulator-5554 \
  -e MAESTRO_TILAWA_STUDENT_EMAIL="$MAESTRO_TILAWA_STUDENT_EMAIL"
```

Pre-authenticated session on device:

```sh
maestro test .maestro/quran_sessions/staging_student_smoke.yaml --device emulator-5554 \
  -e MAESTRO_SKIP_LOGIN=true
```

### Teacher dashboard smoke (external link hidden under videoOnly)

```sh
maestro test .maestro/quran_sessions/staging_teacher_dashboard_smoke.yaml --device emulator-5554 \
  -e MAESTRO_TILAWA_TEACHER_EMAIL="$MAESTRO_TILAWA_TEACHER_EMAIL"
```

### Partial hub entry only

```sh
maestro test .maestro/quran_sessions/staging_student_hub_booking_smoke.yaml --device emulator-5554 \
  -e MAESTRO_SKIP_LOGIN=true
```

---

## Failure artifacts

Maestro writes debug output under `~/.maestro/tests/<timestamp>/`. Copy failure screenshots to:

`docs/quran-sessions/device-qa-evidence/YYYY-MM-DD-<scenario>.png`

---

## Manual fallback (D1–D8)

When Maestro is **BLOCKED** (no credentials, Google picker unavailable, or missing student flag on build):

1. Install staging build with all dart-defines above; cold start.
2. **Student (`mohammad.kamel@othaimmarkets.com`):**
   - Home → **تعلّم القرآن** → **ابدأ التعلّم** → **المحفظون**
   - Open teacher → **احجز جلسة** → confirm **مرئي** only (no **صوتي** / **رابط خارجي**)
   - Book slot → expect **قيد الانتظار** (live `requiresTutorApproval`) or **القادمة**
   - **جلساتي** → cancel with reason → confirm not under **القادمة**
3. Sign out → **Teacher (`mu7ammadkamel@hotmail.com`):**
   - Settings → **لوحة تحكم المحفظ** → **لوحة المعلم**
   - Confirm **طلبات معلقة** / **حصص قادمة** visible; **no** **رابط الاجتماع الخارجي** in app bar

Record pass/fail in [`staging-post-apply-verification.md`](staging-post-apply-verification.md).

---

## Out of scope (smoke)

Paid checkout, wallet, admin UI, reschedule, voice/external product work, mixing roles in one flow.
