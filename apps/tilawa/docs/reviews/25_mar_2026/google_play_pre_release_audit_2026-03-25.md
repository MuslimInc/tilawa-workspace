# Google Play Pre-Release Audit

Date: 2026-03-25

Scope: Full codebase review of `apps/tilawa` with emphasis on runtime safety, startup performance, UI performance, state handling, background work, and release risk before publishing to Google Play.

Verification performed:
- `flutter analyze` in `apps/tilawa`
- `flutter analyze` in `packages/core`
- `flutter analyze` in `packages/ui`
- `flutter analyze` in `packages/quran`
- `flutter test --reporter compact --concurrency=1` in `apps/tilawa`

## Summary

Release status: Not ready for Google Play.

Findings summary:
- Critical: 1
- High: 3
- Medium: 3
- Low: 1

Primary blockers:
- Client startup code attempts to seed Firestore from end-user devices on every launch.
- The Downloads screen error state can crash instead of rendering the error UI.
- A malformed push-notification payload can route into the Quran reader with an invalid surah and trigger a runtime exception.
- The Qibla stream lifecycle is incorrect and can leave compass/location updates alive after the screen is closed.

Additional release notes:
- The full serial test suite is not green. It exits non-zero and includes a confirmed loader failure in `test/router/app_router_config_test.dart`.
- The startup and Quran-font paths contain avoidable performance risk on lower-end Android devices.

## Critical

### 1. Client app mutates Firestore during normal startup

Severity: Critical

Why this matters:
- Every app launch can perform production Firestore reads and potentially writes from an untrusted client.
- If Firestore rules allow it, any released client can seed or alter `subscription_plans`.
- Even if writes are blocked, the app still performs unnecessary backend work on every launch.

Affected files and components:
- `apps/tilawa/lib/core/bootstrap/app_startup.dart:370-373`
- `apps/tilawa/lib/core/services/firebase_initialization_service.dart:14-38`
- Premium / subscription catalog bootstrap

What is happening:
- `AppStartupTasks._initializeNonCriticalServicesInBackground()` calls `initializeFirebaseDataAsync()`.
- `FirebaseInitializationService.initializeFirebaseData()` checks `subscription_plans` and calls `addDefaultSubscriptionPlans()` when empty.
- The same service also contains sample-user bootstrap logic intended for testing.

Steps to reproduce:
1. Install a production-configured build.
2. Launch the app on a device with network access.
3. Observe Firestore traffic during startup.
4. On an empty or newly provisioned backend, the client will attempt to seed subscription data.

Recommended fix or mitigation:
- Remove all Firestore seeding/bootstrap writes from the shipping client.
- Move catalog initialization to an admin-only backend path, migration, or one-time server job.
- Gate any demo/sample-data code behind a non-production build flag and exclude it from release builds.

## High

### 2. Downloads error state uses a sliver in a box layout and can crash

Severity: High

Why this matters:
- When Downloads enters its error state, the UI can throw a render/layout exception instead of showing a retry screen.
- This is a user-facing crash path for a common failure mode such as storage/database/network errors.

Affected files and components:
- `apps/tilawa/lib/features/downloads/presentation/screens/downloads_screen.dart:106-116`
- `apps/tilawa/lib/features/downloads/presentation/screens/downloads_screen.dart:151-163`
- `apps/tilawa/lib/features/downloads/presentation/screens/downloads_screen.dart:168-202`
- Downloads screen error UI

What is happening:
- `_DownloadsBody` is rendered under `Scaffold > Stack > BlocBuilder`.
- In the error state it returns `_ErrorView`.
- `_ErrorView.build()` returns `SliverFillRemaining`, which requires a sliver parent, not a normal box layout.

Steps to reproduce:
1. Force `DownloadsBloc` into `DownloadsStateStatus.error`.
2. Open the Downloads screen.
3. Flutter attempts to place `SliverFillRemaining` under a non-sliver parent and throws during layout.

Recommended fix or mitigation:
- Replace `SliverFillRemaining` with a normal box widget such as `Center`, `SizedBox.expand`, or `CustomScrollView`-compatible wiring.
- Add a widget test that pumps the screen in the error state.

### 3. Invalid notification payload can crash Quran reader navigation

Severity: High

Why this matters:
- A malformed push payload from Firebase or the notification backend can send real users into a crash path.
- This affects both cold-start and tapped-notification flows.

Affected files and components:
- `apps/tilawa/lib/features/notifications/presentation/services/fcm_notification_handler_service.dart:107-115`
- `apps/tilawa/lib/features/quran_reader/presentation/screens/quran_reader_screen.dart:67-70`
- `packages/quran/lib/src/services/functions/page_functions.dart:39-44`
- Notification deep-link routing and Quran reader startup

What is happening:
- `resolveLocation()` accepts any parsed integer for `surahNumber`.
- `QuranReaderScreen.initState()` immediately calls `getPageNumber(widget.surahNumber, 1)` for any `surahNumber > 0`.
- `getPageNumber()` documents that it throws when the surah number is invalid.

Steps to reproduce:
1. Send or simulate a notification with payload `{"type":"quran","surahNumber":"999"}`.
2. Tap the notification.
3. The app navigates to `QuranReaderRoute(surahNumber: 999)`.
4. `QuranReaderScreen` calls `getPageNumber(999, 1)` and the reader flow throws.

Recommended fix or mitigation:
- Validate notification payloads before routing.
- Reject surah values outside `1..114` and fall back to `QuranLastReadRoute` or home.
- Add route-level guards and unit tests for malformed payloads.

### 4. Qibla stream lifecycle is wrong and can keep compass/location work alive after the screen closes

Severity: High

Why this matters:
- A location/compass stream that survives past the screen lifetime wastes battery and sensor usage.
- The current provider setup also creates two separate `QiblaBloc` instances with divergent state.

Affected files and components:
- `apps/tilawa/lib/core/providers/app_providers.dart:57`
- `apps/tilawa/lib/screens/main_screen.dart:47-51`
- `apps/tilawa/lib/screens/main_screen.dart:63-72`
- `apps/tilawa/lib/router/app_router_config.dart:182-189`
- `apps/tilawa/lib/features/qibla/presentation/screens/qibla_screen.dart:20-25`
- `apps/tilawa/lib/features/qibla/presentation/bloc/qibla_bloc.dart:37-38`
- `apps/tilawa/lib/features/qibla/presentation/bloc/qibla_bloc.dart:149-155`

What is happening:
- `AppProviders` registers a global `QiblaBloc`.
- `MainScreen` creates another local `QiblaBloc`.
- `QiblaRoute` builds `QiblaScreen` directly, so the route resolves the global bloc, not MainScreen's local one.
- `QiblaScreen` starts the flow in `initState()` but never dispatches `StopQiblaStream` on dispose.
- The active subscription is only cancelled when the bloc closes or someone explicitly sends `StopQiblaStream`.

Steps to reproduce:
1. Open the Qibla screen.
2. Grant permission and let the compass stream start.
3. Navigate away from Qibla without destroying the global app provider tree.
4. The global bloc can keep the subscription alive for the rest of the session.

Recommended fix or mitigation:
- Use a single ownership model for `QiblaBloc`.
- Stop the stream explicitly in `QiblaScreen.dispose()` or scope the bloc to the route and let route disposal close it.
- Add a bloc test covering start, navigate-away, and stream cancellation.

## Medium

### 5. First frame is delayed by pre-`runApp()` splash asset warm-up

Severity: Medium

Why this matters:
- This path directly delays cold-start rendering before Flutter can draw its first frame.
- It is especially risky on slower Android devices where startup time already matters.

Affected files and components:
- `apps/tilawa/lib/core/bootstrap/app_startup.dart:193-197`
- `apps/tilawa/lib/core/bootstrap/app_startup.dart:265-294`
- `apps/tilawa/lib/features/splash/presentation/screens/splash_screen.dart:98-104`
- Launch/startup path

What is happening:
- `bootstrap()` awaits `warmUpSplashWordmark()` before calling `runApp()`.
- `warmUpSplashWordmark()` waits on image resolution with a timeout of up to 750 ms.
- The splash screen then loads the same asset again through `Image.asset`.

Reproduction / observation:
1. Cold-start the app on a slower Android device.
2. The first Flutter frame cannot appear until the awaited warm-up finishes or times out.

Recommended fix or mitigation:
- Do not block `runApp()` on image warm-up.
- If the asset must be preloaded, move the warm-up after the first frame or rely on the native splash for that transition.

Note:
- This is an inference from the startup code path. I did not collect profile traces during this audit.

### 6. Quran font registration loads hundreds of files concurrently, increasing jank and memory pressure risk

Severity: Medium

Why this matters:
- The first Quran-reader open can trigger large concurrent file reads and font registration work.
- On low-memory devices this can cause noticeable stalls or memory spikes.

Affected files and components:
- `packages/quran/lib/src/services/quran_font_service.dart:121-171`
- `apps/tilawa/lib/features/quran_reader/presentation/bloc/quran_font_loader_bloc.dart:73-75`
- Quran reader initialization and font engine registration

What is happening:
- `loadFontsToEngine()` scans the font directory, creates a `FontLoader` per file, reads each file with `readAsBytes()`, and then awaits all loads via `Future.wait(loadFutures)`.
- The code targets roughly 604 Quran page fonts, so the work scales badly at first-use time.

Reproduction / observation:
1. Install on a fresh device.
2. Open the Quran reader for the first time after font download.
3. Expect the registration step to be the heaviest part of the flow, especially on lower-end devices.

Recommended fix or mitigation:
- Register fonts in bounded batches instead of one large `Future.wait`.
- Consider reducing the number of simultaneously loaded fonts or deferring registration to pages actually needed first.
- Add device profiling around first Quran-reader open before release.

Note:
- This is an inference from the code path. I did not capture memory or frame-timing traces during this audit.

### 7. Downloads screen dispatches duplicate loads and uses the wrong lifecycle hook for refresh

Severity: Medium

Why this matters:
- The screen can issue redundant `LoadDownloads` events on first display.
- `didChangeDependencies()` is not a visibility callback, so the intended "reload when visible" behavior is unreliable.
- The result is unnecessary work now and stale assumptions later.

Affected files and components:
- `apps/tilawa/lib/features/downloads/presentation/screens/downloads_screen.dart:31-58`
- `apps/tilawa/lib/features/downloads/presentation/screens/downloads_screen.dart:67-80`
- Downloads screen state loading

What is happening:
- `initState()` schedules `_loadDownloads()` with a post-frame callback.
- `didChangeDependencies()` schedules the same `_loadDownloads()` again.
- On first build, both run.
- Later, dependency changes such as localization/theme/media updates can trigger another load even though the screen was not "re-opened".

Steps to reproduce:
1. Open the Downloads screen for the first time.
2. Observe two `LoadDownloads` dispatches.
3. Trigger an inherited-widget change such as locale/theme and watch another reload occur.

Recommended fix or mitigation:
- Keep a single initial load path.
- Use an explicit visibility/navigation signal if refresh-on-return is required.
- Add a widget or bloc test asserting one initial `LoadDownloads` dispatch.

## Low

### 8. Test suite is not release-clean; router config test file is effectively dead

Severity: Low

Why this matters:
- The release pipeline does not currently provide a trustworthy green test signal.
- That increases the chance of shipping regressions unnoticed.

Affected files and components:
- `apps/tilawa/test/router/app_router_config_test.dart:1-220`
- Automated verification / CI gate

What is happening:
- The entire file is commented out, including `main()`.
- During `flutter test --reporter compact --concurrency=1`, the suite fails to load this file with:
  `Missing definition of 'main' method.`

Steps to reproduce:
1. Run `flutter test --reporter compact --concurrency=1` in `apps/tilawa`.
2. The suite fails while loading `test/router/app_router_config_test.dart`.

Recommended fix or mitigation:
- Delete the dead test file or restore it to a runnable state with a real `main()`.
- Require a fully green suite before the Play release cut.

## Final Recommendation

Do not publish this build to Google Play until the Critical and High findings are fixed and the full test suite is green.
