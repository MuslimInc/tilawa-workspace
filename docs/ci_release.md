# Releasing to Google Play from mobile (GitHub Actions)

The [`android-release`](../.github/workflows/android-release.yml) workflow
builds a signed Android App Bundle with a plain `flutter build appbundle` and
publishes it to Google Play. Once set up, you can cut a release entirely from
the **GitHub mobile app or a mobile browser** — no laptop needed.

## One-time setup (needs the keystore + Play service account once)

Add these under **Repo → Settings → Secrets and variables → Actions → New
repository secret**:

| Secret | What it is | How to get it |
| --- | --- | --- |
| `ANDROID_KEYSTORE_BASE64` | Upload keystore (`.jks`) as base64 | On a device that has the keystore: `base64 -w0 upload-keystore.jks` and paste the output. **This is the one step that needs access to the keystore file.** |
| `ANDROID_KEY_PROPERTIES` | The full `key.properties` file contents (`storePassword`, `keyPassword`, `keyAlias`). The workflow overrides `storeFile`, so its value there does not matter. | Paste your `key.properties` as-is |
| `PLAY_SERVICE_ACCOUNT_JSON` | Play Console service-account JSON | Play Console → link a Google Cloud project → create a service account → download its JSON key → grant it release permissions on the app. Paste the whole JSON. |

> The only blocker that genuinely needs the keystore file is
> `ANDROID_KEYSTORE_BASE64`. If the keystore lives only on the laptop, that one
> secret must be created from somewhere that has the file. After that, every
> future release is mobile-only.

## Cutting a release from mobile

1. Make sure the changes you want to ship are **merged into the default
   branch** (the workflow itself must also be on the default branch before the
   "Run workflow" button appears).
2. Open the **GitHub app → repo → Actions → "Android Release (Google Play)" →
   Run workflow**.
3. Fill the form:
   - **track**: `internal` first (recommended), then promote.
   - **build_name**: e.g. `2.0.8`.
   - **build_number**: e.g. `52` — must be **higher** than the last uploaded
     version code (current live is `2.0.8+52` in repo; confirm Play Console).
   - **rollout**: only matters for `production` (e.g. `0.05` for 5%, `1.0` for
     full).
4. Run it and watch the logs. On success the build is on the chosen Play track.

The version name/code are passed straight to the build, so you don't need to
edit `pubspec.yaml` to bump the release.

Before the AAB build, CI runs `apps/tilawa/tool/stamp_changelog_release.py`,
which sets `lastUpdatedAt` on `assets/changelog/changelog.json` and stamps
`publishedAt` (UTC date/time) on the matching release entry
(`build_name+build_number`). The bundled What's New sheet shows that timestamp.

## Notes

- Builds use `flutter build appbundle --release --target-platform android-arm64
  --split-debug-info=build/symbols` (Flutter 3.44.2, Java 17). Arm64 is also
  set via `ndk.abiFilters` in `app/build.gradle`; the CLI flag is still
  required so Flutter AOT does not compile unused ABIs into the AAB. Code
  generation runs via `melos run gen` before the build. Debug symbols are
  attached as the `debug-symbols-<versionCode>` artifact for Crashlytics.
- The AAB is also attached to the run as the `app-release-aab` artifact, so you
  can download and upload it manually if the Play step ever needs to be skipped.
- Release notes / Data Safety / screenshots are still managed in the Play
  Console (see the release checklist).
- **First run is a validation run** — CI-specific flag/auth details can need a
  small tweak; check the logs and adjust if a step fails.
