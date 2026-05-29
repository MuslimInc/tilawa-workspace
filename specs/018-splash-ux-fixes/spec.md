# Feature Specification: Splash UX Fixes

**Feature Branch**: `fix/splash-arch-violations`
**Created**: 2026-05-26
**Status**: In Progress
**Input**: Senior UX audit of the splash launch flow — `SplashScreen`, `_BootGate._LaunchSplash`, and `AppStartupReadiness`.

---

## Context

The splash screen is the first user-visible surface. The current implementation has no loading feedback, an artificial 1.2-second minimum hold, silent degraded-state handling, a dismissible toast for critical auth errors, and rendering inconsistencies between the two splash surfaces that compose the launch sequence.

---

## Problem Statement

1. **No loading feedback** — A fully static screen with zero motion for up to 10 seconds on slow devices makes the app appear frozen.
2. **Artificial 1.2 s minimum delay** — `initialTabRouteSettleDelay = 1200 ms` is a hard floor applied even when startup completes in under 300 ms.
3. **Silent timeout** — When `maxSplashDuration` (10 s) is reached, `SplashNavigateToHome(timedOut: true)` is emitted, but the screen ignores the flag entirely and navigates to home without informing the user.
4. **Auth error as dismissible toast** — A `Fluttertoast` over a full-screen branded background auto-dismisses before the user can read or act on it; there is no retry affordance.
5. **`BoxFit` mismatch** — `_BootGate._LaunchSplash` renders with `BoxFit.fill` (stretches/distorts), `SplashScreen` uses `BoxFit.contain` (correct). The handoff between them can produce a visible snap.
6. **`FilterQuality` mismatch** — `_BootGate._LaunchSplash` uses `FilterQuality.high`; `SplashScreen` uses the default `FilterQuality.low`. The wordmark quality changes between the two surfaces.
7. **Misleading constant name** — `_androidSplashWordmarkBoxSize` is applied on all platforms without a platform guard, contradicting its name.
8. **No accessibility semantics** — Screen readers receive no label or live-region announcement during or after launch.

---

## Goals

1. Users see a loading indicator from the first frame of the splash.
2. Startup hold time is reduced to what is functionally necessary.
3. Users are notified when startup timed out and the app is in a degraded state.
4. Auth errors are surfaced in a persistent, dismissible dialog with a clear message.
5. Both splash surfaces render the wordmark identically (same `BoxFit`, same `FilterQuality`).
6. Constants are named to reflect their actual scope.
7. Screen readers announce the splash as a loading screen.

---

## Requirements

### Functional

- **FR-001**: `SplashScreen` displays a `CircularProgressIndicator.adaptive` (white) below the wordmark for the duration it is visible.
- **FR-002**: `AppStartupReadiness.initialTabRouteSettleDelay` is reduced from 1200 ms to 400 ms.
- **FR-003**: When `SplashNavigateToHome(timedOut: true)` is received, the screen shows a brief toast informing the user that some content may load slowly before navigating to home.
- **FR-004**: When `AuthBloc` emits an error during splash, a modal `AlertDialog` displays the message with a single dismiss action; navigation to login occurs only after the user dismisses the dialog.
- **FR-005**: `_BootGate._LaunchSplash` uses `BoxFit.contain` (matching `SplashScreen`).
- **FR-006**: `SplashScreen`'s `Image.asset` uses `filterQuality: FilterQuality.high` (matching `_BootGate._LaunchSplash`).
- **FR-007**: `_androidSplashWordmarkBoxSize` is renamed to `_wordmarkBoxSize` in `SplashScreen`.
- **FR-008**: The splash content is wrapped in a `Semantics` widget with a localized `label` and `liveRegion: true`.

### Localization

Two new keys in `app_en.arb` / `app_ar.arb`:
- `a11ySplashLoading` — screen-reader label for the splash surface.
- `splashSlowLoadingNotice` — toast text shown when startup times out.

Existing keys reused: `error` (dialog title), `close` (dialog dismiss button).

## Out of Scope

- Animated logo / Lottie intro (spec 008 skeleton track).
- Retry logic for auth failures (requires auth feature work).
- Platform-specific wordmark sizes.
