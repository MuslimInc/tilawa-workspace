import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/features/quran_reader/presentation/screens/quran_image_reader_screen.dart';
import 'package:tilawa/features/quran_reader/presentation/screens/quran_render_demo_screen.dart';
import 'package:tilawa_core/di/injection.dart';
import 'package:tilawa_core/entities/reciter_entity.dart';

import '../features/athkar/presentation/screens/athkar_categories_screen.dart';
import '../features/athkar/presentation/screens/athkar_details_screen.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/bookmarks/presentation/bloc/bookmarks_bloc.dart';
import '../features/bookmarks/presentation/screens/bookmarks_screen.dart';
import '../features/downloads/presentation/screens/downloads_screen.dart';
import '../features/history/presentation/bloc/history_bloc.dart';
import '../features/history/presentation/screens/history_screen.dart';
import '../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../features/prayer_times/presentation/bloc/prayer_times_bloc.dart';
import '../features/prayer_times/presentation/screens/prayer_times_screen.dart';
import '../features/premium/presentation/screens/premium_screen.dart';
import '../features/qibla/presentation/screens/qibla_screen.dart';
import '../features/reciters/presentation/bloc/reciter_details_bloc.dart';
import '../features/reciters/presentation/bloc/reciter_download_bloc.dart';
import '../features/reciters/presentation/screens/favorites_screen.dart';
import '../features/reciters/presentation/screens/reciter_details_loader.dart';
import '../features/reciters/presentation/screens/reciter_details_screen.dart';
import '../features/settings/presentation/screens/settings_screen.dart';
import '../features/splash/presentation/screens/splash_screen.dart';
import '../screens/main_screen.dart';
import '../screens/route_list_screen.dart';

part 'app_router_config.g.dart';

@TypedGoRoute<HomeRoute>(path: '/')
class HomeRoute extends GoRouteData with $HomeRoute {
  const HomeRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const MainScreen();
  }
}

@TypedGoRoute<OnboardingRoute>(path: '/onboarding')
class OnboardingRoute extends GoRouteData with $OnboardingRoute {
  const OnboardingRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const OnboardingScreen();
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
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => getIt<ReciterDetailsBloc>()),
        BlocProvider(create: (context) => getIt<ReciterDownloadBloc>()),
      ],
      child: ReciterDetailsScreen(reciter: $extra!),
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
    this.source = 'manual',
  });
  final int categoryId;
  final String categoryName;
  final String source;

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return AthkarDetailsScreen(
      categoryId: categoryId,
      categoryName: categoryName,
      source: source,
    );
  }
}

@TypedGoRoute<QiblaRoute>(path: '/qibla')
class QiblaRoute extends GoRouteData with $QiblaRoute {
  const QiblaRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const QiblaScreen();
  }
}

@TypedGoRoute<RouteListRoute>(path: '/routes')
class RouteListRoute extends GoRouteData with $RouteListRoute {
  const RouteListRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const RouteListScreen();
  }
}

@TypedGoRoute<SplashRoute>(path: '/splash')
class SplashRoute extends GoRouteData with $SplashRoute {
  const SplashRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const SplashScreen();
  }
}

@TypedGoRoute<BookmarksRoute>(path: '/bookmarks')
class BookmarksRoute extends GoRouteData with $BookmarksRoute {
  const BookmarksRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return BlocProvider(
      create: (context) =>
          getIt<BookmarksBloc>()..add(const BookmarksEvent.load()),
      child: const BookmarksScreen(),
    );
  }
}

@TypedGoRoute<HistoryRoute>(path: '/history')
class HistoryRoute extends GoRouteData with $HistoryRoute {
  const HistoryRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return BlocProvider(
      create: (context) =>
          getIt<HistoryBloc>()..add(const HistoryEvent.loadAllHistory()),
      child: const HistoryScreen(),
    );
  }
}

@TypedGoRoute<PrayerTimesRoute>(path: '/prayer-times')
class PrayerTimesRoute extends GoRouteData with $PrayerTimesRoute {
  const PrayerTimesRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return BlocProvider(
      create: (context) =>
          getIt<PrayerTimesBloc>()
            ..add(const PrayerTimesEvent.loadPrayerTimes()),
      child: const PrayerTimesScreen(),
    );
  }
}

@TypedGoRoute<QuranLastReadRoute>(path: '/quran-last-read')
class QuranLastReadRoute extends GoRouteData with $QuranLastReadRoute {
  const QuranLastReadRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const QuranImageReaderScreen(surahNumber: 0);
  }
}

@TypedGoRoute<QuranReaderRoute>(path: '/quran-reader/:surahNumber')
class QuranReaderRoute extends GoRouteData with $QuranReaderRoute {
  const QuranReaderRoute({required this.surahNumber, this.ayahNumber});

  final int surahNumber;
  final int? ayahNumber;

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return QuranImageReaderScreen(
      surahNumber: surahNumber,
      initialAyah: ayahNumber,
    );
  }
}

@TypedGoRoute<QuranRenderDemoRoute>(path: '/render-demo')
class QuranRenderDemoRoute extends GoRouteData with $QuranRenderDemoRoute {
  const QuranRenderDemoRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const QuranRenderDemoScreen();
  }
}
