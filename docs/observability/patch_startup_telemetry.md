# Patch startup telemetry (Option A)

Ship **startup observability** on release **1.0.6+38** via Shorebird patch — no new Play
upload. Includes `shorebird_code_push` for `patch_number` on each log row.

## Before you patch

### 1. Deploy Firestore rules (once)

From repo root (Firebase project `quran-playera-app`):

```bash
firebase deploy --only firestore:rules
```

Uses [`firestore.rules`](../../firestore.rules). Without this, `app_startup_logs` writes fail
silently in the app.

### 2. Commit telemetry changes

All files under `apps/tilawa/lib/core/telemetry/`, bootstrap hooks, `shorebird_code_push`
in `pubspec.yaml`, and `docs/observability/`.

### 3. Know the release base ref

Patch diff must be against the **exact commit** used for `shorebird release` of
`1.0.6+38`. If missing:

```bash
git tag v1.0.6+38 <release-commit-sha>
git push origin v1.0.6+38
```

## Patch workflow

```bash
# From repo root — replace BASE with v1.0.6+38 or the release commit SHA
./scripts/shorebird-preflight.sh v1.0.6+38

cd apps/tilawa
shorebird patch android --release-version 1.0.6+38

shorebird patches list --release-version 1.0.6+38
```

Preflight may **warn** on `pubspec.lock` (new `shorebird_code_push`). That is expected for
Option A. Continue if Shorebird does **not** block on native diffs when building the patch.

## Verify on a device

1. Install or update from Play (base **1.0.6+38**), wait for patch download (or kill/reopen).
2. Cold start twice.
3. Firebase Console → Firestore → `app_startup_logs`:
   - `startup_phase` rows through `startup_completed`, or
   - `startup_failed` with `reason` / `phase` if something breaks.
4. Check `patch_number` matches the new patch (e.g. `2` after rollback of bad patch `1`).
5. Crashlytics: custom keys `shorebird_patch_number`, `startup_last_phase`.

## Rollback

If cold start regresses, roll back the patch in Shorebird console / CLI before wider rollout.

## What ships in this patch

| Included | Not included |
|----------|----------------|
| `StartupTelemetry` + Firestore backend logs | New assets / icons |
| Early Crashlytics on boot failure | Native plugin bumps |
| Analytics `startup_phase` / `startup_failed` / `startup_completed` | New Play AAB |
| `shorebird_code_push` → `patch_number` on logs | |

See also [startup_health_logs.md](startup_health_logs.md) and [shorebird.md](../shorebird.md).
