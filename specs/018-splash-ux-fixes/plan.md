# Implementation Plan: Splash UX Fixes

**Branch**: `fix/splash-arch-violations` | **Date**: 2026-05-26 | **Spec**: [spec.md](./spec.md)

## Phases

| Phase | File | Change |
|-------|------|--------|
| 0 | `app_en.arb` / `app_ar.arb` | Add `a11ySplashLoading` and `splashSlowLoadingNotice` keys |
| 1 | `app_startup_readiness.dart` | Reduce `initialTabRouteSettleDelay` 1200 ms → 400 ms (FR-002) |
| 2 | `app_startup_widgets.dart` | Fix `_LaunchSplash`: `BoxFit.fill` → `BoxFit.contain` (FR-005) |
| 3 | `splash_screen.dart` | All remaining fixes: loading indicator, timedOut toast, auth dialog, FilterQuality, constant rename, Semantics (FR-001, 003, 004, 006, 007, 008) |

## Risks

- Reducing `initialTabRouteSettleDelay` may expose a visible tab-settling stutter on very slow devices. The 400 ms floor retains the `shellActivationDelay` (260 ms) plus 140 ms for the tab route; monitor in integration tests.
- `showDialog` on the splash surface has no `Scaffold` parent — relies on the root navigator provided by `MaterialApp.router`. Verified that `TilawaApp` mounts a navigator before the splash route.
