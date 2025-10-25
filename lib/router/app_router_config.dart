import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:muzakri/features/auth/presentation/screens/login_screen.dart';
import 'package:muzakri/features/downloads/presentation/screens/downloads_screen.dart';
import 'package:muzakri/features/premium/presentation/screens/premium_screen.dart';
import 'package:muzakri/features/settings/presentation/screens/settings_screen.dart';
import 'package:muzakri/screens/main_screen.dart';
import 'package:muzakri/screens/reciter_details_screen.dart';
import 'package:muzakri/shared/models/reciter_model.dart';
import 'package:muzakri/shared/widgets/expanded_player_screen.dart';

part 'app_router_config.g.dart';

@TypedGoRoute<HomeRoute>(path: '/')
class HomeRoute extends GoRouteData with $HomeRoute {
  const HomeRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const MainScreen();
  }
}

@TypedGoRoute<ReciterDetailsRoute>(path: '/reciter/:reciterId')
class ReciterDetailsRoute extends GoRouteData with $ReciterDetailsRoute {
  const ReciterDetailsRoute({required this.reciter, required this.reciterId});

  final Reciter reciter;
  final String reciterId;

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return ReciterDetailsScreen(reciter: reciter);
  }
}

@TypedGoRoute<ExpandedPlayerRoute>(path: '/expandedPlayer')
class ExpandedPlayerRoute extends GoRouteData with $ExpandedPlayerRoute {
  const ExpandedPlayerRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const ExpandedPlayerScreen();
  }
}

@TypedGoRoute<PremiumRoute>(path: '/premium')
class PremiumRoute extends GoRouteData with $PremiumRoute {
  const PremiumRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const PremiumScreen();
  }
}

@TypedGoRoute<SettingsRoute>(path: '/settings')
class SettingsRoute extends GoRouteData with $SettingsRoute {
  const SettingsRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const SettingsScreen();
  }
}

@TypedGoRoute<LoginRoute>(path: '/login')
class LoginRoute extends GoRouteData with $LoginRoute {
  const LoginRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const LoginScreen();
  }
}

@TypedGoRoute<DownloadsRoute>(path: '/downloads')
class DownloadsRoute extends GoRouteData with $DownloadsRoute {
  const DownloadsRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const DownloadsScreen();
  }
}

@TypedGoRoute<ErrorRoute>(path: '/error')
class ErrorRoute extends GoRouteData with $ErrorRoute {
  const ErrorRoute({this.error});

  final String? error;

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Page not found: ${state.uri}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => const HomeRoute().go(context),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    );
  }
}
