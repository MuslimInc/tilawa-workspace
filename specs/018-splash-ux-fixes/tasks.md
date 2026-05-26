# Tasks: Splash UX Fixes

**Spec**: [spec.md](./spec.md) | **Plan**: [plan.md](./plan.md)

## Done

- [x] **T018-001**: Add `a11ySplashLoading` and `splashSlowLoadingNotice` to `app_en.arb` and `app_ar.arb`.
- [x] **T018-002**: Reduce `initialTabRouteSettleDelay` from 1200 ms to 400 ms in `AppStartupReadiness` (FR-002).
- [x] **T018-003**: Fix `BoxFit.fill` → `BoxFit.contain` in `_BootGate._LaunchSplash` (FR-005).
- [x] **T018-004**: Add `CircularProgressIndicator.adaptive` below the wordmark in `SplashScreen` (FR-001).
- [x] **T018-005**: Show `splashSlowLoadingNotice` toast when `SplashNavigateToHome(timedOut: true)` (FR-003).
- [x] **T018-006**: Replace auth error toast with `AlertDialog` in `SplashScreen` (FR-004).
- [x] **T018-007**: Add `filterQuality: FilterQuality.high` to `SplashScreen` wordmark image (FR-006).
- [x] **T018-008**: Rename `_androidSplashWordmarkBoxSize` → `_wordmarkBoxSize` in `SplashScreen` (FR-007).
- [x] **T018-009**: Wrap splash content in `Semantics` with localized label and `liveRegion: true` (FR-008).
