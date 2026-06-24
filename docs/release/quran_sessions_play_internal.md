# Quran Sessions — Play Internal / Closed Testing Release Runbook

**Milestone:** `037-quran-session-free-beta-closure`  
**Audience:** Release engineer uploading to Google Play internal or closed track.

**Related:**

- [Master QA sign-off](../qa/quran_sessions_free_beta_signoff.md)
- [Experimental production readiness report](../../specs/037-quran-session-free-beta-closure/experimental-production-readiness-report.md)
- [CI release (generic Play workflow)](../../docs/ci_release.md)
- [Android Release workflow](../../.github/workflows/android-release.yml)

---

## Scope for this release

| In scope | Out of scope |
|----------|--------------|
| Individual 1:1 booking (external link + mock voice/video) | Paid booking / wallet |
| Single-active-device on callables | Group sessions |
| Feature-flagged booking | Agora / WebRTC SDK |
| Staging Firebase backend | Production-wide booking without documented flag |

---

## Pre-upload gates

- [ ] [Master sign-off](../qa/quran_sessions_free_beta_signoff.md) B1–B5 + T2/T5/T6/T7/T8 complete (or explicit risk acceptance documented).
- [ ] `./scripts/quran_sessions_preflight.sh` green locally or equivalent CI green on `master`.
- [ ] Cloud Functions deployed to staging Firebase (at minimum `createSessionBooking`, `registerActiveDevice`).
- [ ] ≥1 verified teacher with schedule + meeting link on staging.
- [ ] Rollback owner named on sign-off doc.

---

## Build flavor & environment variables

### Distribution stamp (required)

Play uploads via CI set:

```text
TILAWA_DISTRIBUTION=play_<track>
```

where `<track>` is `internal`, `alpha`, `beta`, or `production` ([android-release.yml](../../.github/workflows/android-release.yml)).

| Track | `TILAWA_DISTRIBUTION` | Booking default (`quranSessionsBookingEnabled`) |
|-------|----------------------|--------------------------------------------------|
| internal | `play_internal` | **on** (`!= play_production`) |
| alpha / beta (closed) | `play_alpha` / `play_beta` | **on** |
| production | `play_production` | **off** — must override explicitly |

Source: [`AppLaunchConfig.fromEnvironment`](../../apps/tilawa/lib/core/bootstrap/app_launch_config.dart).

### Booking flag (closed track cohort)

For **closed testing** where booking must be explicitly documented:

```text
--dart-define=TILAWA_LAUNCH_QURAN_SESSIONS_BOOKING_ENABLED=true
```

For **kill-switch** / rollback build:

```text
--dart-define=TILAWA_LAUNCH_QURAN_SESSIONS_BOOKING_ENABLED=false
```

Other Quran Sessions flags (reference only):

| Dart-define | Default (non-`play_production`) | Notes |
|-------------|----------------------------------|-------|
| `TILAWA_LAUNCH_QURAN_SESSIONS_ENABLED` | `true` | Master sessions feature |
| `TILAWA_LAUNCH_TEACHER_APPLICATION_ENABLED` | `true` | Teacher intake |
| `TILAWA_LAUNCH_QURAN_SESSIONS_PAID_BOOKING_SANDBOX_ENABLED` | `false` | **Do not enable** for Free Beta |

### Local / App Distribution build example

```sh
cd apps/tilawa
flutter build apk --release \
  --target-platform android-arm64 \
  --dart-define=TILAWA_DISTRIBUTION=play_internal \
  --dart-define=TILAWA_LAUNCH_QURAN_SESSIONS_BOOKING_ENABLED=true
```

### CI Play upload

GitHub Actions → **Android Release (Google Play)** → track `internal` (recommended first).  
CI currently stamps only `TILAWA_DISTRIBUTION=play_<track>`. For `internal`/`alpha`/`beta`, booking defaults **on**.  
To force booking **off** on a non-production track, extend the workflow with an extra `--dart-define` (not in tree today).

---

## Firebase & App Check

### Firebase project

- **Staging:** `quran-playera-app` (default in `functions/scripts/stagingFreeBetaSmoke.ts` and `firebase.json`).
- Confirm `apps/tilawa/android/app/google-services.json` points at the intended project before upload.
- Deploy Functions + rules to staging before tester rollout.

### App Check

Release builds activate App Check in [`app_startup_tasks.dart`](../../apps/tilawa/lib/core/bootstrap/app_startup_tasks.dart):

- **Android release:** Play Integrity provider.
- **Debug:** Android Debug provider.

Callable Functions (booking, `registerActiveDevice`, etc.) expect attested clients when enforcement is on. If callables fail with `unauthenticated` on a sideloaded APK, verify Play Integrity / debug token registration in Firebase Console → App Check.

**Tester note:** Play-internal installs are attested; Firebase App Distribution APKs may need debug App Check tokens for engineering builds.

### Firestore platform config

Document `quran_session_platform_config/global`:

- `enabledCallProviders`: include `external`; add `mock` only if testing B2.
- `defaultExternalMeetingUrl`: fallback when teacher has no personal link.

---

## What NOT to enable

| Item | Why |
|------|-----|
| `TILAWA_LAUNCH_QURAN_SESSIONS_PAID_BOOKING_SANDBOX_ENABLED=true` | Paid path out of Free Beta scope |
| `agora` / `webrtc` in `enabledCallProviders` | No RTC SDK in app; CF rejects client hints |
| `bookingType: group` | Server rejects; not productized |
| Wallet / payout CF flags | Unchanged; remain off |
| Production-wide booking on `play_production` without sign-off | Violates rollout plan |

---

## Upload procedure (summary)

1. Merge to default branch; confirm [pr-checks](../../.github/workflows/pr-checks.yml) green (`functions-emulator-tests` + analyze).
2. Run `./scripts/quran_sessions_preflight.sh`.
3. Deploy staging Functions (see [release-checklist § Staging deploy](../../specs/032-quran-session-delivery-plan/release-checklist.md)).
4. Trigger **Android Release** workflow → track `internal` → new `build_number`.
5. Add internal testers in Play Console; share [tester instructions](../qa/quran_sessions_free_beta_signoff.md#tester-cohort-instructions).
6. After internal smoke passes, promote to **closed** track with same or new build.

---

## Post-upload smoke (single device minimum)

Engineering smoke before handing to two-device QA:

| # | Step | Expected |
|---|------|----------|
| 1 | Fresh install from Play internal; sign in test student | Home loads; no crash |
| 2 | Open Quran Sessions entry (home / discover) | Sessions UI visible |
| 3 | Open verified teacher → **Book session** visible (booking flag on) | Slot picker loads |
| 4 | Book external meeting; open My Sessions → Join | External link opens |
| 5 | Sign out / sign in | No stuck session; epoch registers |

Full sign-off still requires two-device scenarios in [master sign-off](../qa/quran_sessions_free_beta_signoff.md).

---

## Maestro UI smoke

**Status:** Not automated for Quran Sessions in Phase 5.

Existing Maestro flows (`.maestro/`) cover reciters, player, prayer notifications — not sessions. A minimal sessions flow would need:

- Pre-authenticated Google session (see `.maestro/subflows/ensure_main_shell.yaml`).
- Stable semantics / test keys on sessions navigation (not present today).
- Build with booking flag on and staging backend data.

**Recommendation:** Rely on widget tests in `packages/quran_sessions/test/presentation/` + manual post-upload smoke above. Revisit Maestro after adding `Semantics` test IDs on the sessions entry route.

---

## CI verification reference

| Job | Workflow | What it covers |
|-----|----------|----------------|
| `analyze-and-test` | [pr-checks.yml](../../.github/workflows/pr-checks.yml) | `melos run analyze`; `melos run test` (all packages with `test/`, including `packages/quran_sessions`) — test step advisory |
| `functions-emulator-tests` | same | `npm test`, `npm run test:integration`, `npm run test:rules` (JDK 21) |

Targeted local paths mirrored in `scripts/quran_sessions_preflight.sh`.

---

## Rollback

See [master sign-off rollback checklist](../qa/quran_sessions_free_beta_signoff.md#rollback-checklist) and readiness report §19.

---

*Last updated: Phase 5 Play internal readiness (2026-06-23).*
