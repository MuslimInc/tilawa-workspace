# MeMuslim flavors — Phase 1 audit (2026-07-04)

Audit performed before adding `development` / `staging` / `production` flavors.

## Entry points

| Item | Finding |
|------|---------|
| `main.dart` | Single entry; Sentry init → `bootstrap()`. No flavor-specific mains. |
| `app_launch_config.dart` | All launch flags via `_LaunchEnvironment` + `String.fromEnvironment`. Staging defaults keyed off `TILAWA_DISTRIBUTION != play_production`. |
| `TILAWA_DISTRIBUTION` | Used across app, `quran_sessions` package, Cloud Functions, Maestro docs. Values: `local` (default), `staging`, `play_production`, `play_internal`, `play_alpha`, `play_beta`, custom QA strings. |

## VS Code launch

`.vscode/launch.json` had dart-defines only (no `--flavor`). Staging profiles set
`TILAWA_DISTRIBUTION=staging` + Quran Sessions flags. Production profile used
`play_production`.

## Android

| Item | Value |
|------|-------|
| `applicationId` | **`com.tilawa.app`** |
| `namespace` | `com.tilawa.app` |
| `google-services.json` | Single file at `android/app/` → project **`quran-playera-app`** |
| Product flavors | **None** (pre-change) |
| App name | `MeMuslim` (`values/strings.xml`), `أنا مسلم` (`values-ar/strings.xml`) |

## iOS

| Item | Value |
|------|-------|
| Bundle id | **`com.tilawa.app`** |
| Display name | `MeMuslim` (`Info.plist`) |
| `GoogleService-Info.plist` | Project **`quran-playera-app`**, bundle `com.tilawa.app` |
| Schemes | Single `Runner` scheme; no flavor configurations |

## Firebase

- **One project in repo:** `quran-playera-app` (`.firebaserc` default,
  `firebase_options.dart`, Functions, admin hosting).
- No separate “production-only” Firebase mobile config checked in.
- Play production behavior is enforced by **`TILAWA_DISTRIBUTION=play_production`**
  (feature flags), not a different Firebase project.

## Sentry

`sentry_config.dart` used `kReleaseMode ? 'production' : 'development'` for
`options.environment` — not tied to `TILAWA_DISTRIBUTION`. DSN from
`SENTRY_DSN` dart-define with project default embedded.

## CI

| Workflow | Behavior |
|----------|----------|
| `android-release.yml` | `flutter build appbundle` + `--dart-define=TILAWA_DISTRIBUTION=play_<track>`. Package `com.tilawa.app`. No `--flavor`. |
| `firebase-app-distribution.yml` | Release APK, reads App ID from `google-services.json`. |
| `pr-checks.yml` | analyze + test; no flavor-specific builds. |

## Maestro

- App id documented as **`com.tilawa.app`**
- Staging QA requires `TILAWA_DISTRIBUTION=staging` + `quran-playera-app`
- Join-window bypass: staging/local only; blocked for `play_production`

## Fake backend & QA guards

| Guard | Location |
|-------|----------|
| Fake backend blocked for `staging` / `play_production` | `quran_sessions_backend_config.dart` |
| QA join-window bypass | `staging_qa_join_window_bypass.dart` — blocked for `production`, `play_production` |
| Tests | `quran_sessions_backend_config_test.dart`, `staging_qa_join_window_bypass_test.dart` |

## Risks identified (addressed in implementation)

1. Adding flavors breaks undecorated `flutter build` → CI updated to
   `--flavor production`.
2. `applicationIdSuffix` requires Firebase apps for `.dev` / `.staging` →
   documented; placeholder json with updated package names checked in.
3. iOS requires build configurations + `pod install` → script
   `tool/configure_ios_flavors.py` + Podfile mapping added.
4. `TILAWA_DISTRIBUTION` must remain for Play tracks → explicit define still
   overrides `APP_ENV` defaults.

## Production IDs (must not change)

- Android: **`com.tilawa.app`**
- iOS: **`com.tilawa.app`**

Confirmed unchanged for `production` flavor implementation.
