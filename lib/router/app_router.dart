import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/extensions.dart';
import 'app_router_config.dart';

class AppRouter {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static String? redirect(BuildContext context, GoRouterState state) {
    // For now, we'll handle auth redirects in the UI
    return null;
  }

  static Widget errorBuilder(BuildContext context, GoRouterState state) =>
      Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(context.l10n.pageNotFound(state.uri.toString())),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => const HomeRoute().go(context),
                child: Text(context.l10n.goHome),
              ),
            ],
          ),
        ),
      );

  static final GoRouter router = GoRouter(
    navigatorKey: navigatorKey,
    initialLocation: const SplashRoute().location,
    debugLogDiagnostics: true,
    restorationScopeId: 'router',
    redirect: redirect,
    routes: $appRoutes,
    errorBuilder: errorBuilder,
  );
}
