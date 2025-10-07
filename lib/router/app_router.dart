import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:muzakri/features/auth/presentation/screens/login_screen.dart';
import 'package:muzakri/features/premium/presentation/screens/premium_screen.dart';
import 'package:muzakri/reciter_model.dart';
import 'package:muzakri/screens/main_screen.dart';
import 'package:muzakri/screens/reciter_details_screen.dart';

class AppRouter {
  static const String home = '/';
  static const String reciterDetails = '/reciter/:reciterId';
  static const String premium = '/premium';
  static const String login = '/login';

  static final GoRouter router = GoRouter(
    initialLocation: home,
    debugLogDiagnostics: true,
    redirect: (context, state) {
      // For now, we'll handle auth redirects in the UI
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
      GoRoute(
        path: premium,
        name: 'premium',
        builder: (context, state) => const PremiumScreen(),
      ),
      GoRoute(
        path: login,
        name: 'login',
        builder: (context, state) => const LoginScreen(),
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
