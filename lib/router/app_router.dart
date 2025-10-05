import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:muzakri/reciter_model.dart';
import 'package:muzakri/screens/main_screen.dart';
import 'package:muzakri/screens/reciter_details_screen.dart';

class AppRouter {
  static const String home = '/';
  static const String reciterDetails = '/reciter/:reciterId';

  static final GoRouter router = GoRouter(
    initialLocation: home,
    debugLogDiagnostics: true,
    redirect: (context, state) {
      // Add any global redirects here if needed
      return null;
    },
    routes: [
      GoRoute(
        path: home,
        name: 'home',
        builder: (context, state) => const MainScreen(),
      ),
      GoRoute(
        path: reciterDetails,
        name: 'reciterDetails',
        builder: (context, state) {
          // We need to get the reciter from the state or pass it through extra
          final reciter = state.extra as Reciter?;
          if (reciter == null) {
            // Fallback: return to main screen if no reciter data
            return const MainScreen();
          }
          return ReciterDetailsScreen(reciter: reciter);
        },
      ),
    ],
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
              onPressed: () => context.go(home),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    ),
  );
}
