import 'package:flutter/foundation.dart' show kReleaseMode;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:tilawa/core/di/injection.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/features/home/presentation/cubit/home_quran_resume_cubit.dart';
import 'package:tilawa/features/quran_reader/presentation/screens/quran_index_screen.dart';
import 'package:tilawa/features/quran_reader/presentation/screens/quran_reader_host_screen.dart';
import 'package:tilawa/features/quran_reader/presentation/screens/quran_render_demo_screen.dart';
import 'package:tilawa/features/support/presentation/bloc/support_bloc.dart';
import 'package:tilawa/features/support/presentation/bloc/support_event.dart';
import 'package:tilawa_core/entities/reciter_entity.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../core/telemetry/tilawa_sentry_route_display.dart';
import '../features/app_review/domain/entities/app_review_blocked_flow.dart';
import '../features/app_review/presentation/widgets/app_review_sacred_flow_scope.dart';
import '../features/athkar/presentation/screens/athkar_details_screen.dart';
import '../features/athkar/presentation/screens/tasbeeh_screen.dart';
import '../features/athkar/presentation/widgets/athkar_categories_screen_scope.dart';
import '../features/auth/presentation/screens/email_auth_screens.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/manage_devices_screen.dart';
import '../features/bookmarks/presentation/bloc/bookmarks_bloc.dart';
import '../features/bookmarks/presentation/screens/bookmarks_screen.dart';
import '../features/downloads/presentation/widgets/downloads_screen_scope.dart';
import '../features/genui_assistant/genui_assistant.dart';
import '../features/history/presentation/bloc/history_bloc.dart';
import '../features/history/presentation/screens/history_screen.dart';
import '../features/notifications/debug/notification_debug_lab_screen.dart';
import '../features/onboarding/presentation/screens/language_welcome_screen.dart';
import '../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../features/prayer_times/presentation/screens/prayer_alerts_permission_screen.dart';
import '../features/prayer_times/presentation/screens/prayer_notification_status_screen.dart';
import '../features/prayer_times/presentation/widgets/prayer_times_screen_scope.dart';
import '../features/qibla/presentation/widgets/qibla_screen_scope.dart';
import '../features/reciters/presentation/bloc/reciter_details_bloc.dart';
import '../features/reciters/presentation/bloc/reciter_download_bloc.dart';
import '../features/reciters/presentation/screens/favorites_screen.dart';
import '../features/reciters/presentation/screens/reciter_details_loader.dart';
import '../features/reciters/presentation/screens/reciter_details_screen.dart';
import '../features/reciters/presentation/widgets/reciters_search_route_transition.dart';
import '../features/reciters/presentation/widgets/reciters_search_screen_scope.dart';
import '../features/settings/presentation/widgets/settings_screen_scope.dart';
import '../features/share/presentation/screens/screenshot_composer_screen.dart';
import '../features/share/presentation/screens/video_reel_composer_screen.dart';
import '../features/share/presentation/widgets/share_composer_screen_scope.dart';
import '../features/smart_khatma/presentation/widgets/smart_khatma_hub_scope.dart';
import '../features/smart_khatma/smart_khatma_feature_flags.dart';
import '../features/splash/presentation/screens/splash_screen.dart';
import '../features/support/presentation/screens/support_tilawa_screen.dart';
import '../features/daily_guidance/presentation/screens/daily_guidance_screen.dart';
import '../features/ui_kit_debug/tilawa_card_nested_tap_demo_screen.dart';
import '../screens/app_shell_screen.dart';
import '../screens/main_screen.dart';
import '../screens/route_list_screen.dart';
import '../shared/widgets/quran_player_expanded_page.dart';
import '../shared/widgets/quran_player_expanded_route_transition.dart';
import 'app_navigator_keys.dart';
import 'launch_route_page.dart';
import 'prayer_alerts_permission_nav_extra.dart';
import 'share_composer_extra.dart';
import 'tilawa_route_data.dart';

part 'app_router_config.g.dart';

@TypedShellRoute<AppShellRoute>(
  routes: <TypedRoute<RouteData>>[
    TypedGoRoute<HomeRoute>(path: '/'),
    TypedGoRoute<RecitersSearchRoute>(path: '/reciters/search'),
    TypedGoRoute<ReciterDetailsRoute>(path: '/reciter/:reciterId'),
    TypedGoRoute<SupportRoute>(path: '/support'),
    TypedGoRoute<PremiumRoute>(path: '/premium'),
    TypedGoRoute<SettingsRoute>(path: '/settings'),
    TypedGoRoute<ManageDevicesRoute>(path: '/settings/devices'),
    TypedGoRoute<DownloadsRoute>(path: '/downloads'),
    TypedGoRoute<ErrorRoute>(path: '/error'),
    TypedGoRoute<FavoritesRoute>(path: '/favorites'),
    TypedGoRoute<BookmarksRoute>(path: '/bookmarks'),
    TypedGoRoute<HistoryRoute>(path: '/history'),
    TypedGoRoute<QiblaRoute>(path: '/qibla'),
    TypedGoRoute<SmartKhatmaHubRoute>(path: '/smart-khatma'),
    TypedGoRoute<RouteListRoute>(path: '/routes'),
    TypedGoRoute<NotificationDebugLabRoute>(path: '/debug/notifications'),
    TypedGoRoute<TilawaCardNestedTapDemoRoute>(path: '/debug/tilawa-card'),
    TypedGoRoute<PrayerNotificationStatusRoute>(
      path: '/prayer-notification-status',
    ),
    TypedGoRoute<PrayerTimesRoute>(path: '/prayer-times'),
    TypedGoRoute<QuranIndexRoute>(path: '/quran-index'),
    TypedGoRoute<QuranRenderDemoRoute>(path: '/render-demo'),
    TypedGoRoute<SmartQuranPlanRoute>(path: '/smart-quran-plan'),
    TypedGoRoute<WidgetActionRoute>(path: '/widget/:action'),
    TypedGoRoute<DailyGuidanceRoute>(path: '/daily-guidance'),
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
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return launchRoutePage(
      state: state,
      reportOnFirstFrame: false,
      child: build(context, state),
    );
  }

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const _HomeRouteDisplayHost();
  }
}

class _HomeRouteDisplayHost extends StatefulWidget {
  const _HomeRouteDisplayHost();

  @override
  State<_HomeRouteDisplayHost> createState() => _HomeRouteDisplayHostState();
}

class _HomeRouteDisplayHostState extends State<_HomeRouteDisplayHost> {
  @override
  Widget build(BuildContext context) => const MainScreen();
}

class DailyGuidanceRoute extends GoRouteData with $DailyGuidanceRoute {
  const DailyGuidanceRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const DailyGuidanceScreen();
  }
}

class RecitersSearchRoute extends GoRouteData with $RecitersSearchRoute {
  const RecitersSearchRoute();

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return CustomTransitionPage<void>(
      key: state.pageKey,
      transitionDuration: RecitersSearchRouteTransition.transitionDuration,
      reverseTransitionDuration:
          RecitersSearchRouteTransition.reverseTransitionDuration,
      transitionsBuilder:
          (
            BuildContext context,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
            Widget child,
          ) {
            return RecitersSearchRouteTransition(
              animation: animation,
              child: child,
            );
          },
      child: TilawaSentryRouteDisplay(
        child: TilawaSentryRouteReporter(
          when: true,
          child: build(context, state),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const RecitersSearchScreenScope();
  }
}

@TypedGoRoute<LanguageWelcomeRoute>(path: '/language-welcome')
class LanguageWelcomeRoute extends GoRouteData with $LanguageWelcomeRoute {
  const LanguageWelcomeRoute();

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return launchRoutePage(
      state: state,
      child: build(context, state),
    );
  }

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const LanguageWelcomeScreen();
  }
}

@TypedGoRoute<PrayerAlertsPermissionRoute>(path: '/prayer-alerts-permissions')
class PrayerAlertsPermissionRoute extends GoRouteData
    with $PrayerAlertsPermissionRoute {
  const PrayerAlertsPermissionRoute({this.$extra});

  /// Covers shell chrome (bottom nav / side rail) when opened from in-app.
  static final GlobalKey<NavigatorState> $parentNavigatorKey =
      appRootNavigatorKey;

  final PrayerAlertsPermissionNavExtra? $extra;

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return launchRoutePage(
      state: state,
      child: build(context, state),
    );
  }

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return PrayerAlertsPermissionScreenScope(navExtra: $extra);
  }
}

@TypedGoRoute<OnboardingRoute>(path: '/onboarding')
class OnboardingRoute extends GoRouteData with $OnboardingRoute {
  const OnboardingRoute();

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return launchRoutePage(
      state: state,
      child: build(context, state),
    );
  }

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const OnboardingScreen();
  }
}

class ReciterDetailsRoute extends GoRouteData
    with $ReciterDetailsRoute, TilawaRouteData {
  const ReciterDetailsRoute({this.$extra, this.reciterId});

  final ReciterEntity? $extra;
  final String? reciterId;

  @override
  Widget build(BuildContext context, GoRouterState state) {
    final String? resolvedReciterId =
        reciterId ?? state.pathParameters['reciterId'];
    if (resolvedReciterId == null || resolvedReciterId.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          const HomeRoute().go(context);
        }
      });
      return const SizedBox.shrink();
    }

    final ReciterEntity? extra = $extra ?? _extraFromState(state.extra);
    if (extra == null) {
      return ReciterDetailsLoader(reciterId: resolvedReciterId);
    }
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => getIt<ReciterDetailsBloc>()),
        BlocProvider(create: (context) => getIt<ReciterDownloadBloc>()),
      ],
      child: ReciterDetailsScreen(reciter: extra),
    );
  }

  static ReciterEntity? _extraFromState(Object? extra) {
    if (extra is ReciterEntity) {
      return extra;
    }
    return null;
  }
}

class SupportRoute extends GoRouteData with $SupportRoute, TilawaRouteData {
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
class PremiumRoute extends GoRouteData with $PremiumRoute, TilawaRouteData {
  const PremiumRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return BlocProvider(
      create: (_) => getIt<SupportBloc>()..add(const SupportEvent.started()),
      child: const SupportTilawaScreen(),
    );
  }
}

class SettingsRoute extends GoRouteData with $SettingsRoute, TilawaRouteData {
  const SettingsRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const SettingsScreenScope();
  }
}

class ManageDevicesRoute extends GoRouteData
    with $ManageDevicesRoute, TilawaRouteData {
  const ManageDevicesRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const ManageDevicesScreen();
  }
}

@TypedGoRoute<LoginRoute>(
  path: '/login',
  routes: <TypedGoRoute<GoRouteData>>[
    TypedGoRoute<EmailLoginRoute>(path: 'email'),
    TypedGoRoute<RegisterRoute>(path: 'register'),
    TypedGoRoute<ForgotPasswordRoute>(path: 'forgot-password'),
  ],
)
class LoginRoute extends GoRouteData with $LoginRoute {
  const LoginRoute();

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return launchRoutePage(
      state: state,
      child: build(context, state),
    );
  }

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const LoginScreen();
  }
}

class EmailLoginRoute extends GoRouteData with $EmailLoginRoute {
  const EmailLoginRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const EmailLoginScreen();
  }
}

class RegisterRoute extends GoRouteData with $RegisterRoute {
  const RegisterRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const RegisterScreen();
  }
}

class ForgotPasswordRoute extends GoRouteData with $ForgotPasswordRoute {
  const ForgotPasswordRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const ForgotPasswordScreen();
  }
}

class DownloadsRoute extends GoRouteData with $DownloadsRoute, TilawaRouteData {
  const DownloadsRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const DownloadsScreenScope();
  }
}

class ErrorRoute extends GoRouteData with $ErrorRoute, TilawaRouteData {
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

class FavoritesRoute extends GoRouteData with $FavoritesRoute, TilawaRouteData {
  const FavoritesRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const FavoritesScreen();
  }
}

@TypedGoRoute<AthkarCategoriesRoute>(path: '/athkar')
class AthkarCategoriesRoute extends GoRouteData
    with $AthkarCategoriesRoute, TilawaRouteData {
  const AthkarCategoriesRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const AthkarCategoriesScreenScope();
  }
}

@TypedGoRoute<TasbeehRoute>(path: '/athkar/tasbeeh')
class TasbeehRoute extends GoRouteData with $TasbeehRoute, TilawaRouteData {
  const TasbeehRoute({this.dhikrId});

  final String? dhikrId;

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return TasbeehScreen(initialDhikrId: dhikrId);
  }
}

@TypedGoRoute<AthkarDetailsRoute>(path: '/athkar/:categoryId')
class AthkarDetailsRoute extends GoRouteData
    with $AthkarDetailsRoute, TilawaRouteData {
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

class QiblaRoute extends GoRouteData with $QiblaRoute, TilawaRouteData {
  const QiblaRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const QiblaScreenScope();
  }
}

class SmartKhatmaHubRoute extends GoRouteData
    with $SmartKhatmaHubRoute, TilawaRouteData {
  const SmartKhatmaHubRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const SmartKhatmaHubScope();
  }
}

class RouteListRoute extends GoRouteData with $RouteListRoute, TilawaRouteData {
  const RouteListRoute();

  @override
  String? redirect(BuildContext context, GoRouterState state) {
    if (kReleaseMode) return const HomeRoute().location;
    return null;
  }

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const RouteListScreen();
}

class NotificationDebugLabRoute extends GoRouteData
    with $NotificationDebugLabRoute, TilawaRouteData {
  const NotificationDebugLabRoute();

  @override
  String? redirect(BuildContext context, GoRouterState state) {
    if (kReleaseMode) return const HomeRoute().location;
    return null;
  }

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const NotificationDebugLabScreen();
}

class TilawaCardNestedTapDemoRoute extends GoRouteData
    with $TilawaCardNestedTapDemoRoute, TilawaRouteData {
  const TilawaCardNestedTapDemoRoute();

  @override
  String? redirect(BuildContext context, GoRouterState state) {
    if (kReleaseMode) return const HomeRoute().location;
    return null;
  }

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const TilawaCardNestedTapDemoScreen();
}

@TypedGoRoute<SplashRoute>(path: '/splash')
class SplashRoute extends GoRouteData with $SplashRoute {
  const SplashRoute();

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return launchRoutePage(
      state: state,
      reportOnFirstFrame: false,
      child: build(context, state),
    );
  }

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const SplashScreen();
  }
}

class BookmarksRoute extends GoRouteData with $BookmarksRoute, TilawaRouteData {
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

class HistoryRoute extends GoRouteData with $HistoryRoute, TilawaRouteData {
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
    with $PrayerNotificationStatusRoute, TilawaRouteData {
  const PrayerNotificationStatusRoute({this.$extra});

  final String? $extra;

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return PrayerNotificationStatusScreen(payloadJson: $extra);
  }
}

class PrayerTimesRoute extends GoRouteData
    with $PrayerTimesRoute, TilawaRouteData {
  const PrayerTimesRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const AppReviewSacredFlowScope(
      flow: AppReviewBlockedFlow.prayer,
      child: PrayerTimesScreenScope(),
    );
  }
}

class QuranIndexRoute extends GoRouteData
    with $QuranIndexRoute, TilawaRouteData {
  const QuranIndexRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return BlocProvider(
      create: (_) => getIt<HomeQuranResumeCubit>()..load(),
      child: const QuranIndexScreen(),
    );
  }
}

@TypedGoRoute<QuranLastReadRoute>(path: '/quran-last-read')
class QuranLastReadRoute extends GoRouteData
    with $QuranLastReadRoute, TilawaRouteData {
  const QuranLastReadRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const AppReviewSacredFlowScope(
      flow: AppReviewBlockedFlow.quranReading,
      child: QuranReaderHostScreen(surahNumber: 0),
    );
  }
}

@TypedGoRoute<KhatmaReaderRoute>(path: '/khatma-reader/:initialPage')
class KhatmaReaderRoute extends GoRouteData
    with $KhatmaReaderRoute, TilawaRouteData {
  const KhatmaReaderRoute({required this.initialPage});

  final int initialPage;

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return AppReviewSacredFlowScope(
      flow: AppReviewBlockedFlow.quranReading,
      child: QuranReaderHostScreen(
        surahNumber: 1,
        initialPage: initialPage,
        showSaveProgressAction: true,
      ),
    );
  }
}

@TypedGoRoute<QuranReaderRoute>(path: '/quran-reader/:surahNumber')
class QuranReaderRoute extends GoRouteData
    with $QuranReaderRoute, TilawaRouteData {
  const QuranReaderRoute({required this.surahNumber, this.ayahNumber});

  final int surahNumber;
  final int? ayahNumber;

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return AppReviewSacredFlowScope(
      flow: AppReviewBlockedFlow.quranReading,
      child: QuranReaderHostScreen(
        surahNumber: surahNumber,
        initialAyah: ayahNumber,
      ),
    );
  }
}

@TypedGoRoute<ScreenshotComposerRoute>(path: '/share/screenshot')
class ScreenshotComposerRoute extends GoRouteData
    with $ScreenshotComposerRoute, TilawaRouteData {
  const ScreenshotComposerRoute({this.$extra});

  final ScreenshotComposerNavExtra? $extra;

  @override
  Widget build(BuildContext context, GoRouterState state) {
    final ScreenshotComposerNavExtra? extra = $extra;
    if (extra == null) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => const HomeRoute().go(context),
      );
      return const SizedBox.shrink();
    }
    return ShareComposerScreenScope(
      child: ScreenshotComposerScreen(
        surahNumber: extra.surahNumber,
        currentPage: extra.currentPage,
        initialFromAyah: extra.initialFromAyah,
        initialToAyah: extra.initialToAyah,
        reciterName: extra.reciterName,
        readerBoundaryKey: extra.readerBoundaryKey,
        readerPreviewBytesNotifier: extra.readerPreviewBytesNotifier,
      ),
    );
  }
}

@TypedGoRoute<QuranPlayerExpandedRoute>(path: '/player')
class QuranPlayerExpandedRoute extends GoRouteData
    with $QuranPlayerExpandedRoute {
  const QuranPlayerExpandedRoute();

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return CustomTransitionPage<void>(
      key: state.pageKey,
      opaque: false,
      maintainState: true,
      transitionDuration: QuranPlayerExpandedRouteTransition.transitionDuration,
      reverseTransitionDuration:
          QuranPlayerExpandedRouteTransition.reverseTransitionDuration,
      transitionsBuilder:
          (
            BuildContext context,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
            Widget child,
          ) {
            return QuranPlayerExpandedRouteTransition(
              animation: animation,
              child: child,
            );
          },
      child: const TilawaSentryRouteDisplay(
        child: TilawaSentryRouteReporter(
          when: true,
          child: QuranPlayerExpandedPage(),
        ),
      ),
    );
  }
}

@TypedGoRoute<VideoReelComposerRoute>(path: '/share/video-reel')
class VideoReelComposerRoute extends GoRouteData
    with $VideoReelComposerRoute, TilawaRouteData {
  const VideoReelComposerRoute({this.$extra});

  final VideoReelComposerNavExtra? $extra;

  @override
  Widget build(BuildContext context, GoRouterState state) {
    final VideoReelComposerNavExtra? extra = $extra;
    if (extra == null) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => const HomeRoute().go(context),
      );
      return const SizedBox.shrink();
    }
    return ShareComposerScreenScope(
      child: VideoReelComposerScreen(
        surahNumber: extra.surahNumber,
        initialFromAyah: extra.initialFromAyah,
        initialToAyah: extra.initialToAyah,
        reciterName: extra.reciterName,
        reciterServerUrl: extra.reciterServerUrl,
      ),
    );
  }
}

class QuranRenderDemoRoute extends GoRouteData
    with $QuranRenderDemoRoute, TilawaRouteData {
  const QuranRenderDemoRoute();

  @override
  String? redirect(BuildContext context, GoRouterState state) {
    if (kReleaseMode) return const HomeRoute().location;
    return null;
  }

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const QuranRenderDemoScreen();
}

/// AI-generated Smart Quran Plan surface. Isolated, flag-gated, never the home
/// screen. The route is always present but its dependencies are only registered
/// when `genUiAssistantEnabled` is on; when off, [getIt] has nothing to resolve
/// and the route degrades to a safe "unavailable" view.
class SmartQuranPlanRoute extends GoRouteData
    with $SmartQuranPlanRoute, TilawaRouteData {
  const SmartQuranPlanRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    if (!getIt.isRegistered<GenUiAssistantCubit>() ||
        !getIt.isRegistered<GenUiComponentRegistry>() ||
        !getIt.isRegistered<GenUiActionDispatcher>() ||
        !getIt.isRegistered<TrustedContentResolver>()) {
      return Scaffold(
        body: Center(
          child: Text(
            GenUiStrings.surfaceUnavailable,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      );
    }
    return GenUiAssistantScreen(
      cubit: getIt<GenUiAssistantCubit>(),
      registry: getIt<GenUiComponentRegistry>(),
      dispatcher: getIt<GenUiActionDispatcher>(),
      content: getIt<TrustedContentResolver>(),
      request: const GenUiSurfaceRequest(surface: 'smartQuranPlan'),
    );
  }
}

class WidgetActionRoute extends GoRouteData
    with $WidgetActionRoute, TilawaRouteData {
  const WidgetActionRoute({required this.action, this.id});

  final String action;
  final String? id;

  @override
  String? redirect(BuildContext context, GoRouterState state) {
    switch (action) {
      case 'prayer':
      case 'prayer-times':
        return const PrayerTimesRoute().location;
      case 'ayah':
        final String? surahId = id ?? state.uri.queryParameters['surah'];
        final String? ayahId = state.uri.queryParameters['ayah'];
        if (surahId != null && int.tryParse(surahId) != null) {
          return QuranReaderRoute(
            surahNumber: int.parse(surahId),
            ayahNumber: ayahId != null ? int.tryParse(ayahId) : null,
          ).location;
        }
        return const QuranIndexRoute().location;
      case 'athkar':
        return const AthkarCategoriesRoute().location;
      case 'hijri':
        return const SettingsRoute().location;
      case 'khatma':
      case 'wird':
      case 'openKhatma':
        return isSmartKhatmaEnabled()
            ? const SmartKhatmaHubRoute().location
            : const HomeRoute().location;
      case 'setup':
      default:
        return const HomeRoute().location;
    }
  }

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const SizedBox.shrink();
  }
}
