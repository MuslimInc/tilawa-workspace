import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:muzakri/router/app_router_config.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: HomeRoute().location,
    debugLogDiagnostics: true,
    redirect: (context, state) {
      // For now, we'll handle auth redirects in the UI
      return null;
    },
    routes: $appRoutes,
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Page not found: ${state.uri}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => HomeRoute().go(context),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    ),
  );
}
