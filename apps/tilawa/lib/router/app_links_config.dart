/// Policy for future HTTP / universal App Links integration.
///
/// Today the app routes notification taps only; platform URLs are not wired.
/// When adding `app_links` or intent filters:
///
/// 1. Set [usePlatformDefaultLocation] to `true` only after auth/onboarding
///    state is hydrated **before** the first [GoRouter] is constructed.
/// 2. Map incoming URIs to typed routes (same paths as [app_router_config.dart]).
/// 3. Do not also call `context.go` from a link listener — let go_router own
///    [PlatformRouteInformationProvider] updates.
/// 4. Measure cold start in `--profile`; debug JIT skews redirect timing.
abstract final class AppLinksConfig {
  /// While `true`, [GoRouter] uses [initialLocation] and ignores the OS deep
  /// link on cold start. Flip to `false` when App Links are enabled and bootstrap
  /// supplies a resolved platform URI instead of `/splash`.
  static const bool usePlatformDefaultLocation = false;

  /// Default route when no platform link and no notification launch is present.
  static const String defaultColdStartLocation = '/splash';
}
