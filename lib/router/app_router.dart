import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:muzakri/reciter_model.dart';
import 'package:muzakri/screens/playlists_screen.dart';
import 'package:muzakri/screens/reciters_screen.dart';

class AppRouter {
  static const String reciters = '/';
  static const String reciterDetails = '/reciter/:reciterId';
  static const String playlists = '/playlists';

  static final GoRouter router = GoRouter(
    initialLocation: reciters,
    debugLogDiagnostics: true,
    redirect: (context, state) {
      // Add any global redirects here if needed
      return null;
    },
    routes: [
      GoRoute(
        path: reciters,
        name: 'reciters',
        builder: (context, state) => const RecitersScreen(),
      ),
      GoRoute(
        path: reciterDetails,
        name: 'reciterDetails',
        builder: (context, state) {
          // We need to get the reciter from the state or pass it through extra
          final reciter = state.extra as Reciter?;
          if (reciter == null) {
            // Fallback: return to reciters screen if no reciter data
            return const RecitersScreen();
          }
          return ReciterDetailsScreen(reciter: reciter);
        },
      ),
      GoRoute(
        path: playlists,
        name: 'playlists',
        builder: (context, state) => const PlaylistsScreen(),
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
              onPressed: () => context.go(reciters),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    ),
  );
}
