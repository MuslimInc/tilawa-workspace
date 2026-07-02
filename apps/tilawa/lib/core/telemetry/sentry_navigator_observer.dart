import 'package:sentry_flutter/sentry_flutter.dart';

/// Tilawa defaults for [SentryNavigatorObserver] (GoRouter routing instrumentation).
///
/// See: https://docs.sentry.io/platforms/dart/guides/flutter/integrations/routing-instrumentation/
abstract final class TilawaSentryNavigatorObserver {
  /// Routes excluded from navigation transactions (startup shell, etc.).
  static const List<String> ignoredRoutes = <String>[
    '/splash',
  ];

  /// Creates the observer wired into [GoRouter.observers].
  static SentryNavigatorObserver create() {
    return SentryNavigatorObserver(
      ignoreRoutes: ignoredRoutes,
    );
  }
}
