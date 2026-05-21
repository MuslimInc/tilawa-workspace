import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/features/quran_reader/presentation/screens/quran_image_reader_screen.dart';
import 'package:tilawa/features/quran_reader/presentation/screens/quran_render_demo_screen.dart';
import 'package:tilawa/features/support/presentation/bloc/support_bloc.dart';
import 'package:tilawa/features/support/presentation/bloc/support_event.dart';
import 'package:tilawa_core/di/injection.dart';
import 'package:tilawa_core/entities/reciter_entity.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../features/athkar/presentation/screens/athkar_categories_screen.dart';
import '../features/athkar/presentation/screens/athkar_details_screen.dart';
import '../features/athkar/presentation/screens/tasbeeh_screen.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/bookmarks/presentation/bloc/bookmarks_bloc.dart';
import '../features/bookmarks/presentation/screens/bookmarks_screen.dart';
import '../features/downloads/presentation/screens/downloads_screen.dart';
import '../features/history/presentation/bloc/history_bloc.dart';
import '../features/history/presentation/screens/history_screen.dart';
import '../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../features/prayer_times/presentation/bloc/prayer_permissions_cubit.dart';
import '../features/prayer_times/presentation/bloc/prayer_times_bloc.dart';
import '../features/prayer_times/presentation/screens/prayer_notification_status_screen.dart';
import '../features/prayer_times/presentation/screens/prayer_times_screen.dart';
import '../features/support/presentation/screens/support_tilawa_screen.dart';
import '../features/qibla/presentation/screens/qibla_screen.dart';
import '../features/reciters/presentation/bloc/reciter_details_bloc.dart';
import '../features/reciters/presentation/bloc/reciter_download_bloc.dart';
import '../features/reciters/presentation/screens/favorites_screen.dart';
import '../features/reciters/presentation/screens/reciter_details_loader.dart';
import '../features/reciters/presentation/screens/reciter_details_screen.dart';
import '../features/settings/presentation/screens/settings_screen.dart';
import '../features/share/presentation/screens/screenshot_composer_screen.dart';
import '../features/share/presentation/screens/video_reel_composer_screen.dart';
import '../features/splash/presentation/screens/splash_screen.dart';
import '../core/debug/deep_link_debug_screen.dart';
import '../screens/app_shell_screen.dart';
import '../screens/main_screen.dart';
import '../screens/route_list_screen.dart';
import 'share_composer_extra.dart';

part 'app_router_config.g.dart';

@TypedShellRoute<AppShellRoute>(
  routes: <TypedRoute<RouteData>>[
    TypedGoRoute<HomeRoute>(path: '/'),
    TypedGoRoute<ReciterDetailsRoute>(path: '/reciter/:reciterId'),
    TypedGoRoute<SupportRoute>(path: '/support'),
    TypedGoRoute<PremiumRoute>(path: '/premium'),
    TypedGoRoute<SettingsRoute>(path: '/settings'),
    TypedGoRoute<DownloadsRoute>(path: '/downloads'),
    TypedGoRoute<ErrorRoute>(path: '/error'),
    TypedGoRoute<FavoritesRoute>(path: '/favorites'),
    TypedGoRoute<BookmarksRoute>(path: '/bookmarks'),
    TypedGoRoute<HistoryRoute>(path: '/history'),
    TypedGoRoute<QiblaRoute>(path: '/qibla'),
    TypedGoRoute<RouteListRoute>(path: '/routes'),
    TypedGoRoute<DeepLinkDebugRoute>(path: '/debug/deep-link'),
    TypedGoRoute<PrayerNotificationStatusRoute>(
      path: '/prayer-notification-status',
    ),
    TypedGoRoute<PrayerTimesRoute>(path: '/prayer-times'),
    TypedGoRoute<QuranRenderDemoRoute>(path: '/render-demo'),
  ],
)
class AppShellRoute extends ShellRouteData {
  const AppShellRoute();

  @override
  Widget builder(BuildContext context, GoRouterState state, Widget navigator) {
    return AppShellScreen(child: navigator);
  }
}

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

class SupportRoute extends GoRouteData with $SupportRoute {
  const SupportRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return BlocProvider(
      create: (_) => getIt<SupportBloc>()..add(const SupportEvent.started()),
      child: const SupportTilawaScreen(),
    );
  }
}

/// Legacy `/premium` path — same screen as [SupportRoute].
class PremiumRoute extends GoRouteData with $PremiumRoute {
  const PremiumRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return BlocProvider(
      create: (_) => getIt<SupportBloc>()..add(const SupportEvent.started()),
      child: const SupportTilawaScreen(),
    );
  }
}

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

class DownloadsRoute extends GoRouteData with $DownloadsRoute {
  const DownloadsRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const DownloadsScreen();
  }
}

class ErrorRoute extends GoRouteData with $ErrorRoute {
  const ErrorRoute({this.error});

  final String? error;

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return Scaffold(
      body: TilawaErrorState(
        icon: Icons.error_outline_rounded,
        title: context.l10n.pageNotFound(state.uri.toString()),
        retryLabel: context.l10n.goHome,
        onRetry: () => const HomeRoute().go(context),
      ),
    );
  }
}

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

@TypedGoRoute<TasbeehRoute>(path: '/athkar/tasbeeh')
class TasbeehRoute extends GoRouteData with $TasbeehRoute {
  const TasbeehRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const TasbeehScreen();
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

class QiblaRoute extends GoRouteData with $QiblaRoute {
  const QiblaRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const QiblaScreen();
  }
}

class RouteListRoute extends GoRouteData with $RouteListRoute {
  const RouteListRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const RouteListScreen();
  }
}

class DeepLinkDebugRoute extends GoRouteData with $DeepLinkDebugRoute {
  const DeepLinkDebugRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const DeepLinkDebugScreen();
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

class PrayerNotificationStatusRoute extends GoRouteData
    with $PrayerNotificationStatusRoute {
  const PrayerNotificationStatusRoute({this.$extra});

  final String? $extra;

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return PrayerNotificationStatusScreen(payloadJson: $extra);
  }
}

class PrayerTimesRoute extends GoRouteData with $PrayerTimesRoute {
  const PrayerTimesRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) =>
              getIt<PrayerTimesBloc>()
                ..add(const PrayerTimesEvent.loadPrayerTimes()),
        ),
        BlocProvider(
          create: (context) =>
              getIt<PrayerPermissionsCubit>()..checkCapability(),
        ),
      ],
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

@TypedGoRoute<ScreenshotComposerRoute>(path: '/share/screenshot')
class ScreenshotComposerRoute extends GoRouteData
    with $ScreenshotComposerRoute {
  const ScreenshotComposerRoute({this.$extra});

  final ScreenshotComposerNavExtra? $extra;

  @override
  Widget build(BuildContext context, GoRouterState state) {
    final ScreenshotComposerNavExtra extra = $extra!;
    return ScreenshotComposerScreen(
      surahNumber: extra.surahNumber,
      currentPage: extra.currentPage,
      initialFromAyah: extra.initialFromAyah,
      initialToAyah: extra.initialToAyah,
      reciterName: extra.reciterName,
      readerBoundaryKey: extra.readerBoundaryKey,
      readerPreviewBytesNotifier: extra.readerPreviewBytesNotifier,
    );
  }
}

@TypedGoRoute<VideoReelComposerRoute>(path: '/share/video-reel')
class VideoReelComposerRoute extends GoRouteData with $VideoReelComposerRoute {
  const VideoReelComposerRoute({this.$extra});

  final VideoReelComposerNavExtra? $extra;

  @override
  Widget build(BuildContext context, GoRouterState state) {
    final VideoReelComposerNavExtra extra = $extra!;
    return VideoReelComposerScreen(
      surahNumber: extra.surahNumber,
      initialFromAyah: extra.initialFromAyah,
      initialToAyah: extra.initialToAyah,
      reciterName: extra.reciterName,
      reciterServerUrl: extra.reciterServerUrl,
    );
  }
}

class QuranRenderDemoRoute extends GoRouteData with $QuranRenderDemoRoute {
  const QuranRenderDemoRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const QuranRenderDemoScreen();
  }
}
