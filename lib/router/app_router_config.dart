import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/entities/reciter_entity.dart';
import '../core/extensions.dart';
import '../features/athkar/presentation/screens/athkar_categories_screen.dart';
import '../features/athkar/presentation/screens/athkar_details_screen.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/downloads/presentation/screens/downloads_screen.dart';
import '../features/premium/presentation/screens/premium_screen.dart';
import '../features/reciters/presentation/screens/favorites_screen.dart';
import '../features/settings/presentation/screens/settings_screen.dart';
import '../screens/main_screen.dart';
import '../screens/reciter_details_loader.dart';
import '../screens/reciter_details_screen.dart';
import '../shared/widgets/expanded_player_screen.dart';

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
  const ReciterDetailsRoute({this.$extra, required this.reciterId});

  final ReciterEntity? $extra;
  final String reciterId;

  @override
  Widget build(BuildContext context, GoRouterState state) {
    if ($extra == null) {
      return ReciterDetailsLoader(reciterId: reciterId);
    }
    return ReciterDetailsScreen(reciter: $extra!);
  }
}

@TypedGoRoute<ExpandedPlayerRoute>(path: '/expandedPlayer')
class ExpandedPlayerRoute extends GoRouteData with $ExpandedPlayerRoute {
  const ExpandedPlayerRoute();

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return CustomTransitionPage<void>(
      key: state.pageKey,
      child: const ExpandedPlayerScreen(),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
    );
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
  }
}

@TypedGoRoute<FavoritesRoute>(path: '/favorites')
class FavoritesRoute extends GoRouteData with $FavoritesRoute {
  const FavoritesRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const FavoritesScreen();
  }
}

@TypedGoRoute<AthkarCategoriesRoute>(path: '/athkar')
class AthkarCategoriesRoute extends GoRouteData with $AthkarCategoriesRoute {
  const AthkarCategoriesRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const AthkarCategoriesScreen();
  }
}

@TypedGoRoute<AthkarDetailsRoute>(path: '/athkar/:categoryId')
class AthkarDetailsRoute extends GoRouteData with $AthkarDetailsRoute {
  const AthkarDetailsRoute({
    required this.categoryId,
    required this.categoryName,
  });
  final int categoryId;
  final String categoryName;

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return AthkarDetailsScreen(
      categoryId: categoryId,
      categoryName: categoryName,
    );
  }
}
