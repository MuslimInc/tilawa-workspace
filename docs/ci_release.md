# Releasing to Google Play from mobile (GitHub Actions)

The [`android-release`](../.github/workflows/android-release.yml) workflow
builds a signed Android App Bundle with Shorebird and publishes it to Google
Play. Once set up, you can cut a release entirely from the **GitHub mobile app
or a mobile browser** — no laptop needed.

## One-time setup (needs the keystore + Play service account once)

Add these under **Repo → Settings → Secrets and variables → Actions → New
repository secret**:

| Secret | What it is | How to get it |
| --- | --- | --- |
| `ANDROID_KEYSTORE_BASE64` | Upload keystore (`.jks`) as base64 | On a machine that has the keystore: `base64 -w0 upload-keystore.jks` and paste the output. **This is the one step that needs access to the keystore file.** |
| `ANDROID_KEYSTORE_PASSWORD` | Keystore store password | From your `key.properties` |
| `ANDROID_KEY_PASSWORD` | Key password | From your `key.properties` |
| `ANDROID_KEY_ALIAS` | Key alias | From your `key.properties` |
| `SHOREBIRD_TOKEN` | Shorebird CI token | Run `shorebird login:ci` once and paste the token |
| `PLAY_SERVICE_ACCOUNT_JSON` | Play Console service-account JSON | Play Console → Setup → API access → create/download a service account with **Release** permission, paste the whole JSON |

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
   - **build_name**: e.g. `1.0.8`.
   - **build_number**: e.g. `40` — must be **higher** than the last uploaded
     version code (current live is `1.0.7+39`).
   - **rollout**: only matters for `production` (e.g. `0.05` for 5%, `1.0` for
     full).
4. Run it and watch the logs. On success the build is on the chosen Play track.

The version name/code are passed straight to the build, so you don't need to
edit `pubspec.yaml` to bump the release.

## Notes

- Builds use **Shorebird** (`shorebird release android`) to preserve OTA patch
  capability, matching `docs/google_play_release_checklist.md`.
- The AAB is also attached to the run as the `app-release-aab` artifact, so you
  can download and upload it manually if the Play step ever needs to be skipped.
- Release notes / Data Safety / screenshots are still managed in the Play
  Console (see the release checklist).
- **First run is a validation run** — CI-specific flag/auth details can need a
  small tweak; check the logs and adjust if a step fails.
