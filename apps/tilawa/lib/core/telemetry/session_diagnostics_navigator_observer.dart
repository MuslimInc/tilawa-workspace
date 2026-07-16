import 'package:flutter/widgets.dart';
import 'package:tilawa/core/telemetry/session_diagnostics_hub.dart';
import 'package:tilawa/router/app_router.dart';

/// Records GoRouter / Navigator pushes for Sentry session diagnostics.
class SessionDiagnosticsNavigatorObserver extends NavigatorObserver {
  void _capture() {
    try {
      final String route = AppRouter
          .router
          .routerDelegate
          .currentConfiguration
          .uri
          .toString();
      SessionDiagnosticsHub.noteRoute(route);
    } on Object {
      // Router may not be ready during early bootstrap.
    }
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _capture();

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _capture();

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) =>
      _capture();
}
