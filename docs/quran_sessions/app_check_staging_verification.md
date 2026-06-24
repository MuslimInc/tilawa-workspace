# App Check — Staging Verification Runbook

**Scope:** Quran Sessions stable-scope Cloud Functions only.  
**Default:** App Check enforcement is **off** on CF runtime until ops explicitly enables it.

Do **not** flip enforcement on production Firebase until staging smoke passes and legal/product sign off.

---

## Why release build is required

The Flutter client activates Firebase App Check in **release/profile** builds only (`app_startup_tasks.dart`).  
**Debug builds skip App Check** — they cannot validate CF enforcement and will not reproduce production client behavior.

---

## Client dart-defines (staging smoke)

Build from `apps/tilawa`:

```sh
flutter build apk --release \
  --dart-define=TILAWA_DISTRIBUTION=staging \
  --dart-define=TILAWA_LAUNCH_QURAN_SESSIONS_ENABLED=true \
  --dart-define=TILAWA_LAUNCH_QURAN_SESSIONS_BOOKING_ENABLED=true \
  --dart-define=TILAWA_LAUNCH_ENABLED_CALL_PROVIDERS=external,mock
```

Install: `build/app/outputs/flutter-apk/app-release.apk`

---

## CF enforcement flip (staging ops only)

Enforcement is gated by runtime env `QURAN_SESSIONS_ENFORCE_APP_CHECK`.  
Implementation: `functions/src/quranSessions/sessionCallableOptions.ts` — only `"true"` enables rejection.

### Step 1 — Deploy callables (enforcement still off)

```sh
./scripts/deploy_quran_session_callables.sh quran-playera-app
```

Script prints whether `QURAN_SESSIONS_ENFORCE_APP_CHECK` is set. Unset = safe default (off).

### Step 2 — Staging smoke **before** enforcement

On release APK with staging Firebase:

1. Sign in as student; complete profile
2. Book free external session (B1)
3. Open session detail; join external link
4. Confirm no CF `unauthenticated` / App Check errors in logs

### Step 3 — Enable enforcement + redeploy

Set env on Cloud Functions runtime (Firebase Console → Functions → environment, or deploy-time config), then redeploy stable callables:

```sh
QURAN_SESSIONS_ENFORCE_APP_CHECK=true \
  ./scripts/deploy_quran_session_callables.sh quran-playera-app
```

Affected callables (13 stable + `sessionReminders` when `DEPLOY_SESSION_REMINDERS=true`): see script header in `scripts/deploy_quran_session_callables.sh`.

### Step 4 — Staging smoke **after** enforcement

Repeat Step 2 on the **same release APK** (no rebuild required if App Check was already active):

- [ ] Book session succeeds
- [ ] Cancel / reschedule / join paths succeed
- [ ] Teacher dashboard load succeeds
- [ ] No spike in CF App Check rejection metrics

### Rollback (~15 min)

```sh
# Unset or explicitly disable, then redeploy same function set
QURAN_SESSIONS_ENFORCE_APP_CHECK=false \
  ./scripts/deploy_quran_session_callables.sh quran-playera-app
```

See also: [monitoring-rollback-plan.md](../../specs/038-quran-session-stable-production-release/monitoring-rollback-plan.md) layer 7.

---

## Automated coverage

| Check | Location |
|-------|----------|
| Env gate default off | `functions/test/quranSessions/sessionCallableOptions.test.ts` |
| Callable wiring | `functions/test/quranSessions/sessionCallableWiring.test.ts` |
| Client release activation | `apps/tilawa/lib/core/bootstrap/app_startup_tasks.dart` |

---

## Production

**Do not** set `QURAN_SESSIONS_ENFORCE_APP_CHECK=true` on production until:

1. Staging smoke after flip is green (this doc Steps 2–4)
2. B1–B5 / T2–T8 manual sign-off complete
3. Rollback owner on call
