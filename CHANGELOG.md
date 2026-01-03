# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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
