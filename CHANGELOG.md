# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.0.7+11] - 2026-01-25

### Fixed

- **Audio**: Resolved a critical infinite recursive loop in MediaItem synchronization that caused hanging and excessive resource usage.
- **Audio**: Fixed a regression where surah duration was not correctly updating in the playback queue.
- **Tests**: Fixed settings screen tests to align with recent UI header changes.

### Changed

- **Dependencies**: Updated `google_fonts` to v8.0.0.

## [0.0.7+10] - 2026-01-25

### Added

- **History**: Implemented listening history feature with composite keys for idempotency.
- **Prayer Times**: Added prayer times feature including location services and persistence.
- **Settings**: Added app version and build number display.
- **Localization**: Added Arabic translations for Settings.

### Changed

- **UI**: Modernized and enhanced Settings screen tiles and sections.
- **Theme**: Centralized color definitions in `AppColors`.
- **UI**: Redesigned Reciter Details screen for a more premium look.
- **Build**: Updated Kotlin version to 2.1.0 and migrated from JCenter to MavenCentral.

### Fixed

- **UI**: Resolved Hero widget tag conflicts in various screens.
- **Cleanup**: Removed AppsFlyer SDK and updated build artifact paths.

## [0.0.6+7] - 2026-01-17

### Fixed

- **UI**: Fixed Hero widget tag conflict in `MainScreen`, `RecitersScreen`, and `PlaylistsScreen`.
- **Qibla**: Removed sensor timeout logic in `QiblaBloc` for improved UX.

### Changed

- **Dev Tools**: Improved VSCode launch configurations for mono-repo support.

## [0.0.6+6] - 2026-01-07

### Added

- **Theme System**: Introduced `AppColors` for centralized color management.
- **Android Notification**: Added `flutter_downloader` notification icon configuration in manifest.

### Changed

- **Download System**: Massive refactoring of download services and state management (`reciter_download_bloc`, `download_button`, `download_all_button`) for better stability.
- **Dependencies**: Updated `google_fonts` to v7.0.0.
- **UI**: Updates to `BottomPlayerUi` and `MainScreen`.

### Fixed

- **Download Quality**: Improvements to `DownloadNotificationService` and `FlutterDownloaderWrapper`.

### Removed

- **Legacy Tests**: Cleaned up obsolete and flaky integration tests (`bottom_player_test`, `download_all_button_test`).

## [0.0.5+5] - 2026-01-05

### Added

- **R8 Configuration**: Enabled optimized resource shrinking for release builds.
- **ProGuard Rules**: Added comprehensive rules for `flutter_local_notifications`, `Gson`, and Java desugaring.

### Fixed

- **Release Mode Notifications**: Resolved issues where notifications failed in release mode due to code shrinking.
- **Notification Resources**: Removed `largeIcon` reference to fix resource resolution issues in release builds.

## [0.0.4+4] - 2026-01-04

### Added

- **FCM Service**: Integrated Firebase Cloud Messaging for push notifications.
- **Notification Handling**: Added launch handling, debug scheduling, and Android exact alarm permissions.
- **Reciter Favorites**: Added datasource for managing favorite reciters.
- **Integration Tests**: Introduced fake `AthkarNotificationService` for robust integration testing.

### Changed

- **Refactoring**: Moved `AlphaScrollbarBloc` to the `reciters` feature for better domain cohesion.
- **Audio Player**: Integrated `audio_service` and `rxdart` into the audio player bloc; refactored position handling to `AudioPositionService`.
- **App Startup**: Refactored initialization logic for better performance and error handling.
- **Dependencies**: Updated `dartz_plus` packages.

### Fixed

- **Stream Emissions**: Implemented distinct filtering for audio and qibla streams to prevent duplicate states.
- **Download Tests**: Added network connectivity checks to improve test reliability.

## [0.0.3+3] - 2026-01-03

### Added

- **Athkar Notifications**: Scheduled daily athkar reminders (Morning at 7 AM, Evening at 5 PM).
- **Timezone Support**: Accurate notification scheduling across timezones (Cairo, Riyadh, Dubai, etc.).
- **Appsflyer SDK**: Integrated for marketing analytics.
- **Luciq SDK**: Integrated for bug reporting.
- **Startup Optimization**: Parallelized non-critical service initialization for faster app launch.
- Type-safe navigation with go_router_builder code generation
- Generated route definitions with `@TypedGoRoute` annotations
- Auto-completion support for route parameters
- Compile-time route validation
- Generated `app_router_config.g.dart` with route mixins

### Changed

- **BREAKING**: Navigation API completely refactored from string-based to type-safe routes
- **BREAKING**: `context.go(AppRouter.path)` replaced with `const RouteClass().go(context)`
- **BREAKING**: `context.push(AppRouter.path)` replaced with `const RouteClass().go(context)`
- **BREAKING**: `ReciterDetailsRoute` now requires both `reciterId` and `reciter` parameters
- Router configuration moved from manual `GoRoute` definitions to generated route classes
- Import statements updated from `app_router.dart` to `app_router_config.dart` in navigation components

### Removed

- String-based navigation patterns
- Manual route definitions in `app_router.dart`
- `go_router` imports from navigation components (replaced with `app_router_config.dart`)

### Fixed

- Eliminated runtime string parsing for navigation
- Improved refactoring safety for route changes
- Better IDE support with auto-completion for route parameters

### Technical Details

#### Migration Scope

- **Files Updated**: 7 navigation components
- **Routes Migrated**: 8 route definitions
- **Navigation Calls**: 8+ instances updated
- **Generated Files**: 1 (`app_router_config.g.dart`)

#### New Navigation Patterns

**Before (String-based):**

```dart
context.go(AppRouter.login);
context.push(AppRouter.premium);
context.push('/reciter/123', extra: reciter);
```

**After (Type-safe):**

```dart
const LoginRoute().go(context);
const PremiumRoute().go(context);
ReciterDetailsRoute(reciterId: '123', reciter: reciter).go(context);
```

#### Route Definitions

**Generated Routes:**

- `HomeRoute` - Main application screen
- `ReciterDetailsRoute` - Reciter details with parameters
- `ExpandedPlayerRoute` - Audio player expanded view
- `PremiumRoute` - Premium subscription screen
- `SettingsRoute` - Application settings
- `LoginRoute` - User authentication
- `DownloadsRoute` - Downloaded content management
- `ErrorRoute` - Error handling page

#### Build Configuration

**Dependencies Added:**

- `go_router_builder: ^4.1.1` (dev dependency)

**Build Runner:**

- Code generation via `dart run build_runner build`
- Automatic route mixin generation
- Type-safe route factory methods

#### Benefits Achieved

1. **Type Safety**: Compile-time validation of route parameters
2. **Developer Experience**: Auto-completion and IDE support
3. **Maintainability**: Easier refactoring and route management
4. **Performance**: Eliminated runtime string parsing
5. **Code Quality**: Cleaner, more readable navigation code

#### Migration Impact

**Breaking Changes:**

- All navigation calls must be updated to use new route classes
- Route parameters now require explicit typing
- Import statements need to reference `app_router_config.dart`

**Compatibility:**

- Router configuration remains compatible with existing GoRouter setup
- Error handling and redirects preserved
- Theme and localization integration unchanged

---

## Previous Versions

_Previous changelog entries would be documented here_
