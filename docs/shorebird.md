# Shorebird code-push (Android)

Tilawa uses [Shorebird](https://shorebird.dev) to ship Dart-only patches to released Android builds without going through Play Store review.

- **App ID**: `43390e1a-be2e-427a-8286-cb94cde55c24` (see `apps/tilawa/shorebird.yaml`)
- **CLI**: `shorebird` (install via `curl --proto '=https' --tlsv1.2 -sSf https://raw.githubusercontent.com/shorebirdtech/install/main/install.sh | bash`)
- All commands below run from `apps/tilawa/`.

## What a patch can and can't ship

| Change | Ships via patch? |
|---|---|
| Dart code changes | Yes |
| New Flutter packages (Dart-only) | Yes |
| Plugin version bumps that change native (Java/Kotlin/Swift) code | **No** |
| Flutter engine version bumps | **No** |
| Asset file changes (`assets/*.json`, images) | **No** |
| Newly-referenced icons (Material/Fluent) | **No** (font is tree-shaken at AAB build time) |
| `pubspec.yaml` version bump | Not relevant — patches keep the original version |

If any "No" row applies to your change, cut a full release instead.

## Cutting a release

1. Bump the version in `apps/tilawa/pubspec.yaml`.
2. **Commit and tag before building** so the source state is reproducible:
   ```bash
   git add apps/tilawa/pubspec.yaml pubspec.lock
   git commit -m "chore: bump to 1.0.3+28"
   git tag v1.0.3+28
   ```
3. Build and release:
   ```bash
   cd apps/tilawa
   shorebird release android --flutter-version=3.44.0
   ```
4. Upload the AAB at `apps/tilawa/build/app/outputs/bundle/release/app-release.aab` to the Play Console.
5. Push the tag:
   ```bash
   git push origin master --tags
   ```

## Patching an existing release

1. Check out the release tag (or the commit the AAB was built from):
   ```bash
   git checkout v1.0.2+27
   ```
2. Apply your Dart changes on top (cherry-pick or branch from the tag).
3. **Run the preflight script** to spot unsafe changes early:
   ```bash
   ./scripts/shorebird-preflight.sh v1.0.2+27
   ```
4. If preflight is clean, patch:
   ```bash
   cd apps/tilawa
   shorebird patch android --release-version 1.0.2+27
   ```
5. Confirm publication:
   ```bash
   shorebird patches list --release-version 1.0.2+27
   ```

## Common pitfalls (and how to dodge them)

### Native code diff blocks the patch

**Symptom**: Shorebird's diff output lists `Lcom/google/...` or `Lio/flutter/plugins/...` classes added/removed; prompt asks "Continue anyway?".

**Root cause**: A plugin (usually FlutterFire) resolved to a newer minor version than what the release AAB shipped with. The `^` constraints in `pubspec.yaml` allow this.

**Fix**: We commit `pubspec.lock`, so this should not happen if you build from the release tag. If you somehow lose the lockfile state:
- Find the original FlutterFire versions in `~/Library/Application Support/shorebird/logs/` (look for the log from the original `shorebird release` run; it lists every resolved package).
- Create a workspace-root `pubspec_overrides.yaml` pinning those versions.
- Run `flutter clean && flutter pub get` then re-run the patch.
- Delete `pubspec_overrides.yaml` after.

### Asset diff warning

**Symptom**: Shorebird warns about changed files under `base/assets/flutter_assets/...`.

**Root cause**: A JSON file, image, or tree-shaken font changed between the release AAB and the current build.

**Fix**: The preflight script flags these. If the change is:
- **New `required` fields in a JSON-asset-backed model** → make them `String?` or use `@JsonKey(defaultValue: ...)`. See `apps/tilawa/lib/features/athkar/data/models/athkar_category_model.dart` for an example with `nameEn`.
- **Newly-referenced icons** → accept that they'll render as missing-glyph boxes for patched users, or cut a full release.
- **New images / data files** → can't ship via patch. Either gate the new code behind a runtime feature flag or cut a full release.

### Patch built from uncommitted state

**Symptom**: Can't reproduce the AAB the release used.

**Fix**: Always commit + tag before `shorebird release` (see the release flow above).

## Observability after a patch

Cold-start milestones and failures are logged to:

- **Firestore** `app_startup_logs` (backend-style query in console)
- **Crashlytics** breadcrumbs + non-fatals (includes `shorebird_patch_number`)
- **Analytics** `startup_phase` / `startup_failed` / `startup_completed`

See [startup_health_logs.md](observability/startup_health_logs.md). **Patch checklist (Option A, no new Play release):**
[patch_startup_telemetry.md](observability/patch_startup_telemetry.md). Deploy
`firestore.rules` before relying on backend logs.

## Useful commands

```bash
# List releases on the server
shorebird releases list --platform=android

# Show details for a specific release (Flutter version, upload date, etc.)
shorebird releases info --release-version 1.0.2+27

# List patches on a release
shorebird patches list --release-version 1.0.2+27
```
