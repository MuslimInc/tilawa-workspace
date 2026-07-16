# Prompt — Release / Build

> Paste this for build/release work. Rules from
> [`.ai/OPERATING_SYSTEM.md`](../OPERATING_SYSTEM.md) apply. **This is High risk.**

You are doing build/release work in the Tilawa repo. **Mode: Release/build only.
Do NOT change application source, behavior, versions, signing, or CI unless I
explicitly ask.** Confirm the plan before running anything that publishes.

1. **Verify the environment first (report each):**
   - Correct Flutter via FVM (`.fvmrc`), Node `22` for functions.
   - Correct **flavor** and env file: `development` / `staging` / `production`
     under `apps/tilawa/env/*.json` (`--dart-define-from-file=env/<flavor>.json`).
   - Signing/secrets present as expected (do not print secret values).
   - Clean git state; on the intended branch; know whether this is a real
     release or a dry run. **Never deploy from a dirty tree.**
   - ⚠️ Confirm release gating flags for the target distribution before building
     (see `docs`/memory on Learn Quran release gating) — don't promote
     closed-testing artifacts to production.

2. **Update release metadata before building:**
   - Bump `apps/tilawa/pubspec.yaml`.
   - Move verified user-facing changes into the **Current release** section of
     `docs/release_notes.md`; keep each Play Console language block within 500
     characters.
   - Add the matching version and engineering details to `CHANGELOG.md`.
   - Treat the version bump, release notes, and changelog as one mandatory
     release-preparation change. Do not start a release build if any is missing.

3. **Build with the project command:**
   - Android production AAB:
     `dart run melos run tilawa:build:android:production`
     (release, `production` flavor, arm64).
   - Functions: `cd functions && npm ci && npm run build`.
   - Admin panel: `melos run admin:build`.
   - CI reference: `.github/workflows/android-release.yml`,
     `firebase-app-distribution.yml`, `firebase-admin-hosting.yml`,
     `pr-checks.yml`.

4. **Verify the artifact:**
   - Confirm it exists and report the **exact output path**
     (e.g. `apps/tilawa/build/app/outputs/bundle/productionRelease/*.aab`).
   - Report size, flavor, version/build number, and target platform.
   - If signed, confirm signing succeeded (do not leak keystore details).

5. **Deploy only if explicitly authorized.** State the exact command you would
   run (`firebase deploy --only ...`, workflow dispatch) and wait for my go.
   Firestore rules/indexes changes deploy separately and need review.

Report in the §6 format, with an **Environment**, **Artifact (path + metadata)**,
and **Deploy status (done / awaiting authorization / skipped)** section.
If any verification command is unavailable here, say so — do not fake success.
