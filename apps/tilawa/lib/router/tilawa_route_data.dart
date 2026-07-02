import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tilawa/core/telemetry/tilawa_sentry_route_display.dart';

/// Typed-route mixin that wraps destinations for Sentry TTFD.
mixin TilawaRouteData on GoRouteData {
  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return MaterialPage<void>(
      key: state.pageKey,
      name: state.name ?? state.path,
      arguments: <String, String>{
        ...state.pathParameters,
        ...state.uri.queryParameters,
      },
      restorationId: state.pageKey.value,
      child: TilawaSentryRouteDisplay(
        child: TilawaSentryRouteReporter(
          when: true,
          child: build(context, state),
        ),
      ),
    );
  }
}
