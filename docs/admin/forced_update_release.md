# Forced update — release process

Tilawa enforces required upgrades with a **blocking full-screen gate** on
mobile. Google Play In-App Updates are **not** used.

## Source of truth

Firestore document: `app_config/in_app_update`

| Field | Type | Meaning |
| --- | --- | --- |
| `android_min_build_number` | int | Gate Android when installed build &lt; value |
| `ios_min_build_number` | int | Gate iOS when installed build &lt; value |
| `updated_at` | timestamp | Last admin save (optional metadata) |

- Public **read** for clients.
- **Write** only when Firebase Auth ID token has `{ admin: true }` (Admin Panel).
- Clients **fail open**: network / missing doc / missing platform field / bad
  local build string → no gate.

Compare against the install **build number** (`PackageInfo.buildNumber`), not
the marketing semver (`version` in `pubspec.yaml`).

## Admin Panel

Path: **App Version** (`/app-version`)

1. Sign in as an admin user.
2. Open **App Version**.
3. Set Android / iOS minimum builds.
4. Save → confirm dialog → policy merges into Firestore.

## Deploy prerequisites

Firebase CLI must be logged in as a Google account with access to project
`quran-playera-app` (Tilawa / MuslimInc owner — **not** a work account that
only sees unrelated Firebase projects).

Check:

```bash
firebase login:list
firebase projects:list   # must include quran-playera-app
```

If the active email cannot see `quran-playera-app`:

```bash
firebase logout
firebase login
firebase projects:list
```

Then deploy:

```bash
firebase deploy --only firestore:rules --project quran-playera-app
melos run admin:deploy
```

## When to raise mins

1. Ship a build to Play / App Store (note the store **build number** / CFBundleVersion).
2. Confirm the new build is available to users in the target track.
3. In Admin → App Version, set that platform’s min to the lowest build you still
   support (usually the new release’s build, or N−1 if you keep one prior).
4. Confirm on a device still on an older build: gate appears; Update opens the store.
5. Confirm on a current build: app opens normally.
6. Confirm offline / airplane mode: older builds are **not** locked (fail open).

## Seed / break-glass (CLI)

If Admin is unavailable:

```bash
node scripts/seed_in_app_update_config.mjs --android=79 --ios=79
```

Requires `firebase login`. Prefer the Admin Panel for day-to-day changes.

## Client behavior (mobile)

Feature: `apps/tilawa/lib/features/forced_update/`

- Startup / resume → `ForcedUpdateCoordinator`
- Behind min → non-dismissible gate → open store listing (`OpenAppStoreListingUseCase`)
- Android store CTA always opens production Play package `com.tilawa.app`
  (not flavor ids like `.dev` / `.staging`)
- After store update + resume → re-evaluate; gate dismisses when build ≥ min

## Safety notes

- Raising mins **blocks** users on older builds until they update. Confirm store
  availability first.
- Setting both fields to `0` (or clearing mins via omit) effectively disables
  the gate (clients treat missing min as fail-open).
- Do not reuse Play In-App Update APIs.
