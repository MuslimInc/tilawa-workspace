# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [2.1.6+80] - 2026-07-15 [Google Play Production]

### Added

- **Typography**: Poppins for English UI; Arabic continues on IBM Plex across
  settings, home, and reading surfaces.

### Changed

- **First-run**: Quieter onboarding — fewer interruptive permission steps;
  more stable layouts and thumb-reach primary actions.
- **Home / Settings**: Dashboard and settings polish (surface colors, status
  chips, spacing, contrast).
- **Reciters**: Simplified list navigation (tabs bloc removed).

### Fixed

- **Startup / splash**: Hardened Android cold-start splash dismiss races
  (FLUTTER-A4) so the first frame is not released on a 0×0 Flutter view.

## [2.1.5+79] - 2026-07-14 [Google Play Production]

### Added

- **Forced update**: Store-gated minimum Android/iOS versions with a blocking
  update screen and admin App Version controls.
- **App review**: Rate / open store actions always target the production Play
  listing, including from non-production flavors.

### Changed

- **Updates**: Replaced Play in-app update flow with the forced-update gate.
- **Release size**: Removed unused bundled images/icons and unused runtime
  dependencies (smaller production AAB/APK).

### Fixed

- **What's New**: Bundled `changelog.json` so release highlights load after
  update.

## [2.1.4+78] - 2026-07-13 [Google Play Production]

### Added

- **Smart Khatma**: Paced Quran reading plan with home dashboard progress.
- **Daily Guidance**: Optional scheduled ayah notifications from Settings
  (permission-gated; off until the user enables them).
- **Home**: Dashboard refinements for reading progress and prayer/wird context.

### Changed

- **UI**: Broader Tilawa design-system surfaces (app bars, cards, empty/error
  states) for calmer, more consistent reading and settings flows.
- **Auth**: Local-first session trust with background restoration so reopening
  the app is less likely to bounce users to sign-in.

### Fixed

- Packaging and test/golden alignment for Android release candidates.

## [2.1.3+77] - 2026-07-12 [Google Play Production]

### Fixed

- **Quran Sessions**: Fixed Firestore document path error in teacher availability scheduling.

## [2.1.1+72] - 2026-07-03 [Google Play Production]

### Added

- **Auth**: Language switcher on the login screen for faster onboarding.

### Changed

- **UI**: Consistent error and empty states across library screens with retry
  actions; standardized illustrated-state sizing and app bar search layout.
- **Home**: Status bar chrome matches bottom navigation; dashboard content stays
  below the system status area.
- **Sign-in**: Google sign-in button theming and label styling improvements.

### Fixed

- **Offline indicator**: Banner respects the top safe area and no longer overlaps
  system UI.
- **Telemetry**: Crash reporting context and Sentry route tracking improvements.

## [2.0.17+71] - 2026-07-01 [Google Play Production]

### Added

- **Telemetry**: In-app bug report (Settings → Report bug) via Sentry user
  feedback with Tilawa-styled form UI.

### Changed

- **Navigation**: Phone bottom bar shows icon + label on every tab; المصحف
  Arabic label; 24dp icons; selection uses color/weight only (no pill or splash).
- **Settings**: Simpler list rows without leading icons or subtitles.

### Fixed

- **Telemetry**: Sentry feedback form options initialize reliably and match UI
  kit patterns.

## [2.0.17+69] - 2026-07-01 [Google Play Production]

Ships **2.0.17+68** changes that did not reach Play (build 68 cancelled), plus
post-68 fixes.

### Added

- **Telemetry**: Sentry Session Replay (error replays always; sampled sessions in
  release).
- **Quran Sessions**: Teacher apply-only rollout — student Learn Quran surfaces
  off by default; optional Settings/Home entry to external Google Form when flags
  are enabled.

### Fixed

- **Router**: Avoid `StateError` on Android resume when GoRouter matches are not
  yet resolved (`ShellRouteLocation` defensive read).
- **Auth**: Keep `AuthBloc` in sync after remote session revocation (FCM / resume
  checks); faster redirect after Google sign-in.
- **Settings**: Hide duplicate teacher-apply tile when Google Form entry section is
  shown.
- **Quran**: Restore 15-line grid alignment on mushaf pages 1–2.
- **In-app updates**: Treat benign Play `TASK_FAILURE` on update check (no user-facing
  error).
- **Audio**: Harden ayah playback reciter id parsing (`PlayAyahAudioUseCase`).
- **Downloads**: Snapshot active tasks during status sync; quieter orphaned-download
  recovery logs (`DownloadQueueManager`, `DownloadStatusSynchronizer`,
  `DownloadRecoveryService`).
- **Quran Sessions**: Teacher dashboard reload handles terminal availability sync
  states without stuck UI.

### Changed

- **Performance (Quran reader)**: P0 fixes for layout freeze, unified providers,
  and page-jump jank (`quran_image`).
- **Home**: Cleaner quick-tools layout and Quran Sessions visibility gating.
- **Tasbeeh**: History list uses `TilawaCard` for consistent tap feedback.

## [2.0.17+68] - 2026-07-01 [Google Play Production — not published]

Superseded by **2.0.17+69** (build 68 release workflow cancelled).

### Added

- **Telemetry**: Sentry Session Replay (error replays always; sampled sessions in
  release).
- **Quran Sessions**: Teacher apply-only rollout — student Learn Quran surfaces
  off by default; optional Settings/Home entry to external Google Form when flags
  are enabled.

### Fixed

- **Router**: Avoid `StateError` on Android resume when GoRouter matches are not
  yet resolved (`ShellRouteLocation` defensive read).
- **Auth**: Keep `AuthBloc` in sync after remote session revocation (FCM / resume
  checks); faster redirect after Google sign-in.
- **Settings**: Hide duplicate teacher-apply tile when Google Form entry section is
  shown.
- **Quran**: Restore 15-line grid alignment on mushaf pages 1–2.

### Changed

- **Performance (Quran reader)**: P0 fixes for layout freeze, unified providers,
  and page-jump jank (`quran_image`).
- **Home**: Cleaner quick-tools layout and Quran Sessions visibility gating.
- **Tasbeeh**: History list uses `TilawaCard` for consistent tap feedback.

## [2.0.16+66] - 2026-07-01 [Google Play Production]

### Changed

- **Android**: Enforce arm64-v8a-only native libs via `ndk.abiFilters` in Gradle
  (local debug/release; complements CI `--target-platform android-arm64`).
- **Android (Play)**: Release builds exclude Agora/LiveKit native SDKs (RTC stub in
  CI); production uses no-RTC distribution.

## [2.0.16+65] - 2026-06-29 [Google Play Closed Testing]

### Fixed

- **Audio**: Removed live `HydratedBloc` persistence for the Quran player — no
  more ghost mini-player or stale playback state after cold start; legacy
  hydration keys are cleared on startup.
- **Audio (Android)**: Closed-testing playback hardening — clearer loading and
  buffering UX, reliable queue advance, init-failure toast, and tighter handler
  sync for `audio_service`.
- **Auth**: Single-device P0 fixes — stale sign-out no longer races FCM session
  revocation; active-device registration is gated on explicit sign-in; localized
  session-revoked and registration-failure messages.
- **Auth**: Sign-out clears active-device registration and session state more
  reliably; device registration sends platform device info (no hardware IDs).
- **Android**: Wakelock keep-awake no longer crashes when the app resumes before
  `MainActivity` is foreground; obfuscated release `PlatformException` codes are
  handled and Sentry/Crashlytics wakelock lifecycle noise is filtered.
- **Android**: Boot shutdown/airplane-mode events during cold start are tagged in
  Sentry breadcrumbs (`during_boot`) to separate startup ANRs from runtime noise.
- **App Check**: Clearer sign-in and support-purchase errors when Firebase App
  Check blocks a request (localized copy instead of opaque failures).
- **Startup**: Single cold-start splash resolution via boot launch plan — no
  double splash or flicker on relaunch.

### Notes

- **Backend**: `registerActiveDevice` Cloud Function is already deployed to
  `quran-playera-app`; no app-side CF deploy is required for this build.

## [2.0.16+64] - 2026-06-29 [Google Play Hotfix]

### Fixed

- **Android**: Wakelock keep-awake no longer crashes when the app resumes before
  `MainActivity` is foreground; obfuscated release `PlatformException` codes are
  handled and Sentry/Crashlytics wakelock lifecycle noise is filtered.
- **Android**: Boot shutdown/airplane-mode events during cold start are tagged in
  Sentry breadcrumbs (`during_boot`) to separate startup ANRs from runtime noise.
- **Auth**: Sign-out clears active-device registration and session state more
  reliably; device registration uses platform device info without hardware IDs.

## [2.0.16+63] - 2026-06-29 [Google Play Hotfix]

### Fixed

- **Quran Sessions**: Prevent fatal crash when auth is not ready at startup;
  auth-required paths redirect to login instead of throwing
  `StateError: Quran Sessions requires a signed-in user`.
- **Android**: Keep-awake disable during background or teardown swallows
  wakelock `PlatformException` when no foreground activity is available.

## [2.0.16+62] - 2026-06-28 [Google Play Release]

### Added

- **Quran Sessions**: Discover verified Quran tutors, book 1:1 sessions, and join
  via external meeting links; My Sessions hub for upcoming and past bookings;
  teacher dashboard with schedule, bookings, and session management; guardian
  approval for student bookings where required.
- **Home**: Next-prayer hero with Hijri date, optional Today Plan card, featured
  tutor discovery card, and quick tools row for daily actions.

### Changed

- **Version**: Production track bumped to **2.0.16** (build **62**).
- **Theme**: Brand primary restored to green; warm canvas scaffold (`#FAF9F7`)
  across Home and the app shell.
- **Home**: Approved dashboard layout — prayer hero, primary actions, Today
  Plan, and scroll-away featured tutor sliver; interactive surfaces migrated to
  `TilawaInteractiveSurface`.
- **UI kit**: Soft Material ink splash/highlight without press-scale; `TilawaCard`
  nested-tap semantics (parent navigation from blank areas, nested controls keep
  their own action, disabled nested controls are dead zones); settings list rows
  use shared state-layer press, focus ring, and haptics.

### Fixed

- **Android**: Exclude unused Agora screen-sharing SDK so the release bundle
  only declares `mediaPlayback` foreground services (Play Console compliance).
- **Tasbeeh**: Counter card scales across viewport sizes without layout overflow.
- **Quran Sessions**: My Sessions correctly classifies upcoming vs past sessions
  (including tutor-cancelled slots); list caches invalidate after booking,
  cancel, and reschedule mutations.
- **Quran Sessions**: In-call toasts no longer overlay controls; local camera
  preview before remote participants join.
- **UI kit**: Long segmented-control labels ellipsize instead of overflowing.
- **Login / Home**: Sign-in flow polish and home layout cleanup after
  authentication.

## [2.0.13+58] - 2026-06-14 [Google Play Release]

### Fixed

- **Router**: Harden Android route restoration for `/reciter`, `/quran-reader`, and
  `/athkar` paths; safe typed extra decoding prevents null-check and Map cast
  crashes when the app is restored from the background.
- **Android**: Always use `RenderMode.texture` to avoid cold-start ANR in
  `FlutterJNI.onSurfaceCreated` and keep Google sign-in UI visible on Transsion
  ROMs.
- **Telemetry**: Downgrade expected FCM token failures on GMS-free devices; detect
  AOSP emulator fingerprints so release Sentry logs from emulators are filtered.

### Changed

- **Version**: Production track bumped to **2.0.13** (build **58**).

## [2.0.12+57] - 2026-06-13 [Google Play Release]

> Supersedes build 56 (published earlier the same day) to include the
> native-library packaging fix below.

### Added

- **Auth**: Native resume bridge and Transsion (Infinix/Tecno) sign-in policy —
  GMS UI visibility probing, hidden-activity detection, and
  `androidx.credentials` pinned to 1.5.0 on affected devices.
- **Reciters**: Favorites missing from the catalog order are appended instead of
  dropped; refined favorites ordering and alphabet scrubbing.

### Changed

- **Version**: Production track bumped to **2.0.12** (build **57**).
- **Android**: Native libraries stored uncompressed in the APK
  (`extractNativeLibs="false"`) so Google Play delta updates no longer
  re-download the full app on every release.
- **Player**: Tablet mini player anchored in the shell footer without overlapping
  the navigation rail or bar.
- **Onboarding**: Full-width stacked primary and back actions in the footer bar.
- **Support**: Screen reuses the catalog settings body layout.
- **What's New**: Published date shown without time of day.
- **CI**: Dart obfuscation (`--obfuscate --split-debug-info`) enabled in release
  builds.

### Fixed

- **Downloads**: Hardened watchdog, storage probe, and completed-file validation;
  recovery size check tightened to 1% tolerance; only verified files surface as
  offline items.
- **Prayer**: Tightened alerts permission flow navigation.
- **Tasbeeh**: Target count hint and stricter create validation.
- **Telemetry**: Critical init pipeline failures reported; duplicate Sentry
  native init after hot restart skipped.

## [2.0.11+55] - 2026-06-11 [Google Play Release]

### Added

- **Downloads**: Low-storage check before single and batch downloads; **Download All**
  is blocked (not just warned) when free space is insufficient.
- **Downloads**: `disk_space_plus` integration for free-space reads on the download
  volume.

### Changed

- **Version**: Production track bumped to **2.0.11** (build **55**).
- **Downloads tab**: Lists only completed downloads with valid on-disk files.
- **Reciters**: Download All chip keeps an opaque active background and a visible
  progress ring at 0%.
- **UI**: Semantic toast colors; RTL-correct swipe-to-delete backgrounds; undo
  SnackBars on bookmarks and favorites dismiss.

### Fixed

- **Downloads**: Delete-all confirmation no longer throws `ProviderNotFoundException`.

## [2.0.10+54] - 2026-06-11 [Google Play Release]

### Added

- **Sentry structured logs**: Warning-level and above `logger` output forwarded to
  Sentry Logs in non-profile builds; emulator logs filtered in release (same as
  crash events).
- **Sentry verify**: Debug Settings tile now sends a paired test log for Explore →
  Logs onboarding.

### Changed

- **Version**: Production track bumped to **2.0.10** (build **54**).
- **Logging**: Production-relevant download, auth, and prayer paths promoted to
  warn/error for Sentry visibility.
- **Android**: System UI overlay re-applied on resume after back-gesture relaunch
  (Android 12+).

## [2.0.9+53] - 2026-06-11 [Google Play Release]

### Added

- **Sentry**: Crash reporting with device, build, distribution, and install-source
  tags; debug-only verify control in Settings → Developer.
- **AppErrorGuard**: Process-wide error hooks that buffer failures before
  Crashlytics initializes and replay them once the reporter is ready.

### Changed

- **Version**: Production track bumped to **2.0.9** (build **53**).
- **Crashlytics**: Custom keys aligned with Sentry tags; global handlers no longer
  overwrite each other.
- **Startup**: Fatal bootstrap errors release the first frame so users see a
  retry screen instead of a stuck launch splash.
- **CI**: Play release builds stamp `TILAWA_DISTRIBUTION=play_<track>` for crash
  filtering.

## [2.0.8+52] - 2026-06-10 [Google Play Release]

### Added

- **Tasbeeh reminders**: Daily local notification per saved dhikr with tap-through
  to resume counting.
- **Tasbeeh history**: List or grid layout for saved dhikr and clear-all with
  confirmation.
- **Tasbeeh home**: Quick-count entry and refreshed saved-dhikr browsing.
- **What's New**: In-app changelog sheet with a one-time post-update prompt.
- **Reciters tabs**: All and Favorites tabs on the reciters catalog for faster
  switching without leaving the screen.
- **Settings**: Toggle to show or hide the reciters A–Z letter index rail.

### Changed

- **Version**: Production track bumped to **2.0.8** (build **52**).
- **Startup**: Hive-backed features wait until local boxes finish opening on cold
  start.
- **Reciters**: Alphabet scrub keeps header and catalog scroll positions stable,
  including on short filtered lists.
- **Downloads**: Nested tab layout for clearer browsing of offline surahs.
- **Quran player**: Smoother expand and collapse drag on the mini player shell.
- **UI kit**: Flatter bottom navigation chrome, simplified Tasbeeh count ring, and
  shared interaction surface tokens for buttons, chips, and cards.
- **Support**: Unified tier cards and footer alignment on the support screen.

### Fixed

- **Prayer times**: Stopped the loading / enable-location loop after location
  permission is denied.
- **Reciters**: Scrub lock no longer skips catalog positions when the filtered
  list is shorter than the full catalog.
- **Interactive surfaces**: Long-press-only controls no longer fire tap haptics.

## [2.0.7+51] - 2026-06-08 [Google Play Release]

### Added

- **Language welcome**: First-run language picker precedes onboarding, with an
  Arabic/English segmented switcher wired to the localization bloc.
- **Thumb-reach layout**: Shared 72/28 layout keeps primary actions in the
  one-handed reach zone across onboarding and the prayer-alerts permission flow.

### Changed

- **Version**: Production track bumped to **2.0.7** (build **51**).
- **Theme**: New warm cream canvas (`#F9F7F2`) with white raised cards for quiet
  lift and lighter shadows; screens now inherit the canvas instead of painting a
  surface background.
- **Settings**: Redesigned into labelled Appearance and Playback & storage
  sections with leading-icon headers and a member-since profile subtitle.
- **Reciters**: Alphabet index rail and active-letter overlay clear the Quran
  mini player so every letter stays reachable during playback.

### Fixed

- **Athkar**: Tasbeeh floating action button sits clear of the bottom
  navigation bar.

## [2.0.6+50] - 2026-06-07 [Google Play Release]

### Added

- **In-app updates**: Optional and required update prompts driven by Firestore
  config (Google Play in-app update API).
- **Quran image reader**: Surah index FAB above the navigation card for quick
  jumps within the mushaf reader.

### Changed

- **Version**: Production track bumped to **2.0.6** (build **50**).
- **App size**: Arm64-only release bundles and split debug symbols shrink
  download and update size on Play.
- **Reciters**: Alphabet index rail stays fixed size when the mini player
  appears.

### Fixed

- **Quran reader**: Surah index routes through reader `NavigationBloc`; back
  navigation and share/reader polish from recent fixes.
- **Prayer times**: Geocoding timeout prevents the screen hanging on the
  loading spinner; location permission recovery improvements.
- **Premium navigation**: Overlay alignment on the image reader.
- **Reciters**: System back exits the app from the catalog as expected.

## [1.0.7+39] - 2026-06-02 [Google Play Release]

### Added

- **Reciters search**: Dedicated search screen; double-tap Reciters tab to open search
  from the catalog.
- **Reciters alphabet index**: Android-style A–Z scrubber with filter chip and Maestro
  coverage.
- **Startup telemetry**: Cold-start phases logged to Crashlytics and Analytics.
- **Launch branding**: Green splash handoff, updated launcher icons, and stable
  cold-start frame gate.

### Changed

- **Version**: Production track bumped to **1.0.7** (build **39**) after pre-release
  audit on 1.0.6+38.
- **Prayer times**: Swipe between today and monthly tabs; bloc concurrency for
  overlapping loads.
- **Shell**: Bottom nav only on main shell route; mini player kept on pushed routes.

### Fixed

- **Security**: Removed debug localhost telemetry; HTTPS-only network config; blocked
  fake Firestore premium purchases (Play Billing only); untracked `key.properties`.
- **Crashlytics**: Collection enabled by default; profile builds excluded; network
  image load errors downgraded to non-fatal.
- **Navigation**: Root `/player` push via GoRouter; prayer notification cold-start
  race; redirect hardening when `AudioPlayerBloc` is not mounted.
- **Android**: `SCHEDULE_EXACT_ALARM` for Play policy; debug routes gated in release.
- **Auth**: Sign-in stability (Credential Manager); delete-account runs auth deletion
  before data wipe.
- **Telemetry**: Firestore startup sink no longer touches Firebase before
  `initializeApp()`.

## [1.0.6+38] - 2026-05-31 [Google Play Release]

### Added

- **Account deletion**: Delete account in Settings (with confirmation and Google
  re-authentication when required); Firestore profile and FCM tokens removed.
- **Legal links**: Privacy policy on login and in Settings; web account-deletion
  page at `hosting/public/delete-account/` for Play Console Data deletion URL.
- **Firebase Hosting**: Static privacy and account-deletion pages under
  `hosting/public/`.

### Changed

- **Version**: Production track bumped to **1.0.6** (build **38**) for clearer
  Play Vitals separation from prior 1.0.5 builds.

### Fixed

- **Permissions**: Removed unused `ACCESS_MEDIA_LOCATION` from Android manifest.

## [1.0.5+32] - 2026-05-24 [Google Play Release]

### Added

- **In-app review**: Calm engagement-based review prompts after value moments
  (listening, prayer tab, favorites, bookmarks); **Rate Tilawa** in Settings
  opens the store listing directly.
- **Startup**: Splash-held readiness gate — shell tabs stay gated until core
  services are ready; launch overlay stays until the splash route paints.
- **Reciters**: Shared catalog chrome and app bar for consistent list styling;
  clearer favorites screen and reciter cards.
- **Navigation**: Single-word bottom nav labels (Reciters, Prayer, Quran, Athkar,
  Settings) for clearer thumb reach on phone.

### Changed

- **Theme**: Primary accent refreshed to coral; search field and catalog screens
  aligned with the updated visual system.
- **Settings**: Cleaner layout and localization for support and app actions.
- **App review policy**: Prompts stay blocked on Athkar while you remain on the
  Athkar tab after closing a details screen.
- **App size**: Native FFmpeg frozen (not linked) to reduce download size;
  full share/reel Dart code preserved under `apps/tilawa/frozen/share/`.
  Screenshot sharing remains available from the Quran reader.
- **Bundled assets**: Drop duplicate `qpc-v4.json` / `quran_page_index.json`
  from `quran_image` (canonical copies stay in `quran_qcf`); stop shipping
  unused `quran.realm`; release Android builds ship **arm64-v8a** native libs only
  for smaller Play downloads.

### Frozen (not shipped in this build)

- **Video reel share**: UI hidden unless `SHARE_FFMPEG_ENABLED=true` after
  re-adding `ffmpeg_kit_flutter_new`, `video_player`, and `chewie`.
- **Native dependency**: `ffmpeg_kit_flutter_new` (see `frozen/share/README.md`).

### Fixed

- **Startup**: Launch splash no longer flickers away before the splash screen
  is visible.
- **Reciters grid**: Tablet/wide layouts no longer clip reciter names when many
  columns fit on screen.
- **Support purchases** (from 1.0.4 follow-up): Background and resume flows no
  longer show a false failure when verification runs concurrently on the support
  screen.

## [1.0.4+31] - 2026-05-23 [Google Play Release]

### Added

- **Support Tilawa**: Optional one-time Google Play contributions (small, kind,
  generous tiers) with calm thank-you flow; server-verified purchases and local
  support history without worship paywalls.
- **Quran player**: Elapsed and remaining time labels on the expanded player;
  refined expanded layout and queue sheet handle.
- **Google sign-in (Android)**: Credential Manager prepare step before the sign-in
  sheet for more reliable Google login on recent Android versions.
- **Athkar**: Clearer details layout, tap feedback, and counter interaction on
  session screens.

### Changed

- **Support screen**: Redesigned tiers, charities sheet, and Arabic copy aligned
  with the support visual system.
- **Onboarding**: Carousel and RTL footer aligned with ui_kit patterns.
- **Bottom navigation (phone)**: Slightly shorter bar height for thumb reach.
- **ui_kit**: App bar uses hairline chrome instead of a heavy drop shadow; count
  ring digits scale to stay inside the circle.

### Fixed

- **Quran player**: Smoother collapse from expanded player to the mini bar;
  progress duration and position stay in sync with live playback.
- **Support purchases**: Background and resume flows complete verification when
  Play delivers a purchase after the sheet closes; stale billing waiters clear
  after a short grace period; purchase failure messages follow the active locale.
- **Google sign-in (Android)**: Cryptographically secure nonce for the prepare
  bridge instead of a predictable timestamp.
- **Prayer notification status**: Close action returns to home when there is no
  back stack (carried from prior release hardening).

### Security

- **Firebase App Check**: Release builds attest via Play Integrity before
  `verifySupportPurchase` runs; Cloud Function enforces App Check and replay-safe
  token handling.

## [1.0.3+28] - 2026-05-20 [Google Play Release]

### Added

- UI kit interaction feedback (press animation, haptics) and async content states for loading, empty, and error screens.
- Sheet footer pattern for modal forms, pickers, and confirmations.

### Changed

- Settings screen simplified for clearer navigation and production-ready layout.
- Default app language is Arabic for new installs.
- Onboarding start button copy shortened (ابدأ / Get started).
- Confirm bottom sheets size to content instead of forcing half-screen height.

### Fixed

- Prayer notification status close action returns users to home when there is no back stack.
- Main screen startup widget tests aligned with shell cubit lifecycle.

## [1.0.2+27] - 2026-05-15 [Google Play Release]

### Added

- **Prayer times (display)**: Optional setting to show or hide text labels on prayer alert status chips (icon-only mode with accessibility labels).

### Changed

- **Bottom navigation (compact)**: White floating bar with clearer outline and shadow; selected tab pill width constrained for spacing; light-theme chrome tokens tuned for cream backgrounds.
- **Prayer times list**: Improved contrast for secondary status text on non-current rows.
- **Settings sheets**: Language picker uses themed surface background; primary color and related sheets use consistent drag-handle spacing from design tokens.
- **`TilawaSheetHandle` (ui_kit)**: Default top margin aligned with `spaceMedium` per density; `omitTopMargin` for overlays positioned manually; most call sites use `const TilawaSheetHandle()`.

### Fixed

- Bottom sheet drag handles sitting flush against the top edge of modals.

## [1.0.0+24] - 2026-05-08 [Google Play Release]

### Added

- **Prayer Notification Redirection**: Fixed routing discrepancies across all app states (terminated, background, foreground) to ensure accurate redirection to the Prayer Notification Status screen.
- **Prayer/Adhan Payload Matching**: Implemented a robust, JSON-based payload matcher that identifies local/native prayer notifications via multiple markers (`type`, `prayer_key`, `scheduled_time_ms`, etc.), replacing fragile string-based matching.
- **Testing**: Added a comprehensive suite of unit tests for payload matching (compact JSON, whitespace-formatted JSON, native markers) and routing logic.

### Changed

- **FCM Ownership**: Enforced strict service ownership by ensuring the FCM notification handler rejects local prayer payloads, preventing incorrect generic routing.
- **Navigation Deduplication**: Updated AppRouter to allow re-navigation to the Prayer Notification Status screen even when already on that route, enabling UI updates for subsequent notification taps.
- **System UI Overlay Ownership (Phase SUI-1)**: Added app-level default declarative `AnnotatedRegion<SystemUiOverlayStyle>` scope for standard routes (commit `fd304b9`).
- **Theme State (T3.1 Guardrail)**: Kept deferred theme fields (`useSystemTheme`, `AppThemePreset.highContrast`, `AppThemePreset.trueBlack`) persisted for backward-compatible state restoration.

### QA

- **Phase SUI-1 Verdict**: CONDITIONAL PASS.
- **Prayer Redirection Verdict**: PASS. Validated across payload formats and navigation scenarios via automated tests.
- **Decision**: Theme Token Harmonization (T4) GO for release with no pre-release action.

## [0.1.6+24] - 2026-05-05

### Added

- **Prayer Notifications**: Added tap handling and routing — tapping a prayer notification now opens the app at the appropriate screen with full navigation context.
- **Prayer Monitoring UI**: Implemented a dedicated prayer notification status screen showing current scheduling state, next alarm, and system permission health.
- **Adhan Sound Selection**: Users can now select their preferred adhan sound from available options in the notification settings.
- **Adhan QA Tools**: Built-in debug tools for testing adhan scheduling and playback, now enabled by default for development builds.
- **Arabic Alphabet Scrollbar**: Added drag overlay for improved gesture handling with long-press support on the Quran reader surah index.

### Changed

- **Prayer Analytics**: Enhanced event tracking with standardized scheduling keys and richer playback telemetry (start time, latency, fallback usage, duplicate guards).
- **ReciterCard**: Updated layout spacing for improved visual consistency.

### Fixed

- **Notification Taps**: Buffered tap events that arrive before the Android MethodChannel is initialized, preventing missed interactions.
- **Tests**: Added comprehensive test suite for `ArabicAlphabetScrollbar` covering edge cases in gesture handling.

### Docs

- **Spec 005**: Frozen after completing implementation and automated verification.

## [0.1.5+22] - 2026-05-01

### Added

- **Prayer Notifications & Adhan**: Native Android prayer alarm pipeline using `AlarmManager.setAlarmClock` for exact, Doze-bypassing prayer-time delivery, with a foreground `mediaPlayback` service (`AdhanPlaybackService`) for audio playback that survives app termination.
- **Watchdog**: Native `WorkManager` periodic worker (12-hour cadence) that refreshes the rolling 14-day prayer alarm window, with a 15-second timeout, retry on failure, and analytics events (`watchdog_triggered`, `watchdog_completed`, `watchdog_failed`, `watchdog_timeout_occurred`).
- **Boot recovery**: `PrayerBootReceiver` re-arms persisted alarms after `BOOT_COMPLETED`, `MY_PACKAGE_REPLACED`, `TIMEZONE_CHANGED`, and `TIME_SET` without requiring a full Dart cold start.
- **Monitoring**: Firebase Analytics events for the full prayer/adhan lifecycle (schedule started/success/failed, triggered, playback started/completed/failed, fallback used, duplicate-audio guard, permission cleanup, boot receiver, watchdog states) plus Crashlytics non-fatal context keys (manufacturer, exact-alarm grant, notification grant).

### Changed

- **Android signing**: Release builds now sign with the production upload keystore loaded from `android/key.properties`. The build fails fast if the keystore configuration is missing, refusing to ship a debug-signed AAB.
- **Android manifest**: Added `USE_EXACT_ALARM`, `FOREGROUND_SERVICE_MEDIA_PLAYBACK`, `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS`; removed the unused `FOREGROUND_SERVICE_DATA_SYNC` declaration.
- **R8 keep rules**: Added explicit `-keep` rules for `com.tilawa.app.prayer.**` so the manifest-referenced receivers, services, and worker survive code shrinking when minification is enabled.
- **Bootstrap**: Removed development-only block that toggled Firebase Performance `testMode` on debug startup.

### Fixed

- **Tests**: Resolved `app_router_test.dart` failure caused by Material 3 `InkSparkle` shader asset not being available in the widget-test bundle (switched the test theme to `InkRipple.splashFactory`).

## [0.1.4+21] - 2026-04-27

### Added

- **Share / Reels**: Users can now share Quran recitations as short video reels — combines a Mushaf page screenshot with an audio clip of the selected ayah.
- **Share / Screenshot**: Users can capture and share a screenshot of any Quran page directly from the reader.
- **Custom Player Background**: Users can set a personalised background image (from gallery or camera) for the expanded audio player, persisted across sessions via `PlayerBackgroundCubit`.
- **Release**: Added Android signing template and a Google Play release checklist to support safer production publishing.

### Changed

- **Share**: Reel content rendering now fetches ayah text and integrates it with the captured frame for a polished output.
- **Audio Player**: Playback failure toasts now fire reliably on all error transitions — `listenWhen` extended to include failure state changes.
- **Audio Position Service**: Position polling timer is now gated on active playback; timer is cancelled when no media is loaded or playback is paused, reducing idle CPU and battery usage.
- **Android**: Hardened release signing configuration to fail fast when production keystore values are missing.
- **Security**: Disabled cleartext network traffic in the Android manifest for production-safe defaults.
- **CI**: Updated Flutter CI pin to 3.41.7 (Dart 3.11.5) to satisfy workspace SDK constraints; corrected monorepo workflow paths.
- **Tests**: Stabilised settings, startup, share rendering, FFmpeg cancellation, and navigation layer tests for current behaviour.

### Fixed

- **Share**: `UserCancelledFailure` is now handled in `localizedMessage` — cancelling the image picker no longer causes an unhandled exhaustive-switch error.
- **UI Kit**: `TilawaShareFooterBar` now correctly references `componentTokens.footerBar` instead of the non-existent `shareFooterBar` getter.
- **Rendering**: Prevented small-screen Quran page overflow in non-scrollable page text rendering by clipping layout output.
- **Testing**: Fixed SettingsCubit DI setup for SharedPreferencesAsync in unit tests.
- **Testing**: Updated stale assertions in reciters startup and responsive mushaf renderer tests.
- **Testing**: Fixed async FFmpeg fake to respect manual-completion plans and deterministic cancel flow tests.
- **Tooling**: Removed tracked scratch debug script (`scratch/debug_page_data.dart`) to clear analyzer warnings.

## [0.1.3+20] - 2026-03-26

### Added

- **Analytics**: Integrated Firebase Analytics to track Athkar notification interactions and reading progress.
- **Analytics**: Added `athkar_notification_open` and `athkar_read_start` events with source tracking.

### Changed

- **Athkar Notifications**: Optimized reminder scheduling with a 1-hour delay after Fajr (morning) and Asr (evening) prayer times.
- **Athkar Notifications**: Refactored notification logic to use an injected `NavigationService`, improving testability and separation of concerns.
- **UI Kit**: Replaced magic numbers and hardcoded values with centralized design tokens in `TilawaDesignTokens`.
- **UI Kit**: Stabilized the language switcher with fixed-width buttons and absolute LTR visual ordering.

### Fixed

- **UI**: Resolved layout overflow issues in the Quran reader and responsive Bismillah widget text.
- **UI**: Fixed a null-check crash in the Arabic alphabet scrollbar.
- **Localization**: Corrected various RTL styling inconsistencies across the authentication and reciters screens.
- **Testing**: Achieved 99.3% unit test coverage for the `AthkarNotificationService`.

## [0.1.2+19] - 2026-03-19

### Added

- **Quran Reader**: Added last-read navigation, a searchable surah index, and a dedicated font loader flow that downloads QCF4 fonts on demand before opening the reader.
- **Reciters**: Added favorites-only filtering on the reciters list and quick Quran access from the reciters screen.
- **Downloads**: Added pause and resume actions for individual surah downloads.

### Changed

- **Quran Reader**: Reworked page rendering around JSON glyph and page-index data with responsive layout tuning, better `PageView` synchronization, and improved caching/performance.
- **Navigation**: Refined the main screen and bottom player so the player remains persistent while the navigation chrome can hide and show dynamically.
- **Reader UX**: Locked the app to portrait by default, while allowing landscape inside the Quran reader and automatically pausing audio playback during reading.
- **Reciters**: Improved scrolling to the currently playing surah in reciter details and refreshed several reciter list/grid layouts.
- **Dependencies**: Updated the Dart SDK to `^3.11.0`, upgraded `flutter_screenutil_plus` to `1.5.0`, and refreshed `flutter_local_notifications` and `timezone`.

### Fixed

- **Downloads**: Fixed batch download tracking, queue synchronization, cancellation handling, and recovery behavior.
- **Quran Reader**: Fixed Mushaf word spacing and page layout issues, including inconsistent early-page handling.
- **UI**: Improved scroll-to-top behavior and playback state synchronization across reader and reciter screens.

### Removed

- **Assets**: Removed bundled QCF font assets from the app package in favor of downloadable fonts.

## [0.1.0+17] - 2026-02-22

### Added

- **Quran Reader**: Implemented a comprehensive Quran reader feature with high-quality QCF fonts, decorative banners, and responsive 15-line layout.

### Changed

- **Prayer Times**: Rewrote the Prayer Times UI for a more premium look and feel, including improved location handling and accurate countdowns.
- **SDK**: Updated Flutter SDK version to 3.41.1.

### Fixed

- **Prayer Times**: Resolved several bugs in prayer time calculations and UI synchronization.

## [0.0.11+15] - 2026-02-11

### Fixed

- **Athkar**: Fixed layout directionality for Athkar text to correctly display brackets in RTL mode.

## [0.0.9+13] - 2026-01-28

### Added

- **Tests**: Enhanced `download_service_impl_test.dart` with additional tests for uncovered lines and improved handling of active downloads.
- **Tests**: Added `batch_download_manager_test.dart` for batch download functionality.
- **Tests**: Expanded `download_queue_manager_test.dart` with comprehensive test coverage.
- **Downloads**: Added `BatchDownloadManager` service for improved batch download handling.
- **Router**: Added `routerRestorationScopeId` constant for improved routing management.

### Changed

- **Downloads**: Improved error handling and state management in `DownloadServiceImpl`.
- **Downloads**: Enhanced `DownloadQueueManager` with better queue management.
- **Downloads**: Refactored `CancelDownloadsForReciterUseCase` to ensure batch notifications are canceled even when no downloads exist.
- **Bloc**: Improved `AlphabetScrollbarBloc` implementation.

### Fixed

- **ProGuard**: Added `-dontnote j$.**` rule to suppress R8 informational messages about unused desugaring keep rules.
- **Build**: Added `android.r8.ignoreUnusedKeepRules=true` to suppress ProGuard unmatched rule warnings in release builds.

### Removed

- **Services**: Removed unused `LuciqService` and related tests.
- **Tests**: Removed redundant tests from `alphabet_scrollbar_bloc_test.dart` related to HydratedBloc persistence.
- **Dependencies**: Removed `luciq_flutter` package dependency.

## [0.0.8+12] - 2026-01-27

### Changed

- **Dependencies**: Updated `flutter_local_notifications` to v20.0.0.
- **Analytics**: Refactored download analytics and removed legacy `AnalyticsService`.
- **UI**: Improved `OnboardingPage` layout.
- **Tests**: Fixed notification service tests and enforced strict named parameters usage.

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

