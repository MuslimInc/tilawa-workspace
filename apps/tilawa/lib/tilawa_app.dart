import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quran_image/core/perf_logger.dart';
import 'package:quran_image/l10n/quran_image_localizations.dart'
    as quran_image_l10n;
import 'package:quran_sessions/l10n/quran_sessions_localizations.dart'
    as quran_sessions_l10n;
import 'package:tilawa/core/logging/app_logger.dart';
import 'package:tilawa/core/telemetry/startup_perf_log.dart';
import 'package:tilawa/features/quran_reader/presentation/theme/quran_reader_theme.dart';
import 'package:tilawa_core/constants/app_strings.dart';
import 'package:tilawa/core/services/app_lifecycle_keep_awake.dart';
import 'package:tilawa_core/services/interfaces/keep_awake_service.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import 'app/app_providers.dart';
import 'app/default_route_system_ui_overlay.dart';
import 'core/bootstrap/startup_blur_shader_warmup.dart';
import 'core/telemetry/session_diagnostics_hub.dart';
import 'core/debug/device_preview_app_builder.dart';
import 'core/di/injection.dart';
import 'core/services/notification_startup_service.dart';
import 'features/auth/presentation/cubit/session_validity_cubit.dart';
import 'features/auth/presentation/widgets/session_verification_banner.dart';
import 'features/auth/data/services/google_sign_in_session_tracker.dart';
import 'features/downloads/data/services/batch_download_manager.dart';
import 'features/downloads/data/services/download_queue_manager.dart';
import 'features/forced_update/forced_update.dart';
import 'features/localization/presentation/bloc/localization_bloc.dart';
import 'features/prayer_times/domain/entities/entities.dart';
import 'features/prayer_times/domain/usecases/load_prayer_settings_use_case.dart';
import 'features/prayer_times/domain/usecases/schedule_prayer_notifications_use_case.dart';
import 'features/quran_sessions/quran_sessions_platform_config_store.dart';
import 'features/theme/domain/entities/app_theme_preset.dart';
import 'features/theme/presentation/cubit/theme_cubit.dart';
import 'features/theme/presentation/theme_state_material.dart';
import 'features/whats_new/whats_new.dart';
import 'l10n/generated/app_localizations.dart';
import 'router/app_router.dart';
import 'router/app_router_config.dart';

class TilawaApp extends StatefulWidget {
  const TilawaApp({super.key});

  @override
  State<TilawaApp> createState() => _TilawaAppState();
}

class _TilawaAppState extends State<TilawaApp> with WidgetsBindingObserver {
  static const Duration _initialUpdateCheckDelay = Duration(seconds: 8);
  static const Duration _initialWhatsNewDelay = Duration(milliseconds: 1500);
  static const Duration _resumeUpdateCheckDelay = Duration(seconds: 2);

  Timer? _resumeDebounceTimer;
  Timer? _updateCheckTimer;
  Timer? _whatsNewTimer;

  late final NotificationStartupService _notificationStartupService =
      getIt<NotificationStartupService>();
  late final SessionValidityCubit _sessionValidityCubit =
      getIt<SessionValidityCubit>();
  late final KeepAwakeService _keepAwakeService = getIt<KeepAwakeService>();

  @override
  void initState() {
    super.initState();
    StartupPerfLog.log('tilawa_app_init');
    WidgetsBinding.instance.addObserver(this);
    unawaited(SessionDiagnosticsHub.startSession());
    SchedulerBinding.instance.addPostFrameCallback((_) {
      StartupPerfLog.log(
        'tilawa_app_first_post_frame',
        detail:
            'navigator_ready=${AppRouter.navigatorKey.currentContext != null} '
            'location=${AppRouter.router.routerDelegate.currentConfiguration.uri}',
      );
      // handleAppStartup must run before consume: consume clears
      // pendingStartupNotificationLaunch / pendingColdStartLocation, which
      // would incorrectly schedule the 900ms deferred local-notification probe.
      unawaited(_notificationStartupService.handleAppStartup());
      final String? bootstrapTarget = AppRouter.pendingColdStartLocation;
      if (bootstrapTarget != null) {
        final Object? bootstrapExtra = AppRouter.pendingColdStartExtra;
        final String homeLocation = const HomeRoute().location;
        if (bootstrapTarget != homeLocation) {
          AppRouter.router.push(bootstrapTarget, extra: bootstrapExtra);
        }
        AppRouter.consumePendingNotificationLaunchState();
      }
      _scheduleUpdateCheck(
        delay: _initialUpdateCheckDelay,
        reason: 'initial-startup',
      );
      _scheduleWhatsNewCheck(
        delay: _initialWhatsNewDelay,
        reason: 'initial-startup',
      );
    });
  }

  @override
  void dispose() {
    _resumeDebounceTimer?.cancel();
    _updateCheckTimer?.cancel();
    _whatsNewTimer?.cancel();
    _notificationStartupService.dispose();
    unawaited(_keepAwakeService.disable());
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    AppLifecycleKeepAwake.handleStateChange(
      state: state,
      keepAwakeService: _keepAwakeService,
    );
    // Cancel any pending debounce timer to prevent duplicate checks
    _resumeDebounceTimer?.cancel();

    if (state == AppLifecycleState.resumed) {
      logger.d('[QuranPlayerApp] App resumed - checking for notification');
      _resumeDebounceTimer = Timer(const Duration(milliseconds: 100), () {
        unawaited(_notificationStartupService.handleAppResume());
        unawaited(_sessionValidityCubit.checkOnResume());
        _scheduleUpdateCheck(
          delay: _resumeUpdateCheckDelay,
          reason: 'app-resumed',
        );
      });
    }
  }

  void _scheduleUpdateCheck({required Duration delay, required String reason}) {
    if (getIt.isRegistered<GoogleSignInSessionTracker>() &&
        getIt<GoogleSignInSessionTracker>().inFlight) {
      logger.d(
        '[AppLaunch] source=Startup update-check deferred '
        'reason=$reason (Google sign-in in flight)',
      );
      _updateCheckTimer?.cancel();
      _updateCheckTimer = Timer(const Duration(seconds: 5), () {
        _scheduleUpdateCheck(delay: Duration.zero, reason: '$reason-deferred');
      });
      return;
    }
    _updateCheckTimer?.cancel();
    logger.d(
      '[AppLaunch] source=Startup update-check scheduled '
      'reason=$reason delayMs=${delay.inMilliseconds}',
    );
    _updateCheckTimer = Timer(delay, () {
      logger.d(
        '[AppLaunch] source=Startup update-check started reason=$reason',
      );
      _checkForUpdate();
    });
  }

  Future<void> _checkForUpdate() async {
    try {
      if (getIt.isRegistered<ForcedUpdateCoordinator>()) {
        // Run in background to not block UI
        unawaited(getIt<ForcedUpdateCoordinator>().checkForUpdate());
      }
    } on Object catch (e) {
      logger.d('[QuranPlayerApp] Error checking for update: $e');
    }
  }

  void _scheduleWhatsNewCheck({
    required Duration delay,
    required String reason,
  }) {
    _whatsNewTimer?.cancel();
    logger.d(
      '[AppLaunch] source=Startup whats-new scheduled '
      'reason=$reason delayMs=${delay.inMilliseconds}',
    );
    _whatsNewTimer = Timer(delay, () {
      logger.d(
        '[AppLaunch] source=Startup whats-new started reason=$reason',
      );
      unawaited(_maybeShowWhatsNew());
    });
  }

  Future<void> _maybeShowWhatsNew() async {
    try {
      if (getIt.isRegistered<WhatsNewCoordinator>()) {
        await getIt<WhatsNewCoordinator>().maybeShowAfterLaunch();
      }
    } catch (e) {
      logger.d("[QuranPlayerApp] Error showing what's new: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    PerfLogger.markBuild('TilawaAppRoot');
    return AppProviders.create(child: const _PlayerApp());
  }
}

class _PlayerApp extends StatelessWidget {
  const _PlayerApp();

  /// Matches [DESIGN.md] §3 — predictable layouts with moderate a11y scaling.
  static const double _kTextScaleClampMin = 1.0;
  static const double _kTextScaleClampMax = kTilawaGlobalTextScaleFactor;

  static Future<void> _reschedulePrayerNotificationsForLocaleChange() async {
    try {
      final LoadPrayerSettingsUseCase loadSettings =
          getIt<LoadPrayerSettingsUseCase>();
      final SchedulePrayerNotificationsUseCase scheduleNotifications =
          getIt<SchedulePrayerNotificationsUseCase>();
      final result = await loadSettings.call();
      await result.fold(
        (_) async {},
        (PrayerSettingsEntity settings) async {
          final double? latitude = settings.effectiveSchedulingLatitude;
          final double? longitude = settings.effectiveSchedulingLongitude;
          if (latitude == null || longitude == null) {
            return;
          }
          await scheduleNotifications.call(
            settings: settings,
            latitude: latitude,
            longitude: longitude,
            forceReschedule: true,
          );
        },
      );
    } catch (e) {
      logger.w(
        '[TilawaApp] Failed to reschedule prayer notifications after locale change: $e',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    PerfLogger.markBuild('PlayerAppMaterialRoot');
    if (getIt.isRegistered<QuranSessionsPlatformConfigStore>()) {
      context.watch<QuranSessionsPlatformConfigStore>();
    }
    return BlocListener<LocalizationBloc, LocalizationState>(
      listener: (context, state) {
        // Update download notification locale when app locale changes
        getIt<DownloadQueueManager>().locale = state.locale;
        getIt<BatchDownloadManager>().locale = state.locale;
        unawaited(_reschedulePrayerNotificationsForLocaleChange());
      },
      child: BlocSelector<LocalizationBloc, LocalizationState, Locale>(
        selector: (LocalizationState state) => state.locale,
        builder: (BuildContext context, Locale locale) {
          PerfLogger.markBuild('LocalizationBlocBuilder');
          return BlocSelector<ThemeCubit, ThemeState, _AppThemeSnapshot>(
            selector: _AppThemeSnapshot.from,
            builder: (BuildContext context, _AppThemeSnapshot themeSnapshot) {
              PerfLogger.markBuild('ThemeBlocBuilder');
              return _ThemedMaterialApp(
                locale: locale,
                themeSnapshot: themeSnapshot,
                textScaleClampMin: _kTextScaleClampMin,
                textScaleClampMax: _kTextScaleClampMax,
              );
            },
          );
        },
      ),
    );
  }
}

@immutable
class _AppThemeSnapshot extends Equatable {
  const _AppThemeSnapshot({
    required this.themeMode,
    required this.primaryColor,
    required this.isDefaultPreset,
    required this.darkIsTrueBlack,
  });

  factory _AppThemeSnapshot.from(ThemeState state) {
    return _AppThemeSnapshot(
      themeMode: state.themeMode,
      primaryColor: state.primaryColor,
      isDefaultPreset: state.isDefaultPresetForDarkTheme,
      darkIsTrueBlack: state.preset == AppThemePreset.trueBlack,
    );
  }

  final ThemeMode themeMode;
  final Color primaryColor;
  final bool isDefaultPreset;
  final bool darkIsTrueBlack;

  @override
  List<Object?> get props => <Object?>[
    themeMode,
    primaryColor,
    isDefaultPreset,
    darkIsTrueBlack,
  ];
}

class _ThemedMaterialApp extends StatelessWidget {
  const _ThemedMaterialApp({
    required this.locale,
    required this.themeSnapshot,
    required this.textScaleClampMin,
    required this.textScaleClampMax,
  });

  static bool _loggedMaterialAppBuilder = false;

  final Locale locale;
  final _AppThemeSnapshot themeSnapshot;
  final double textScaleClampMin;
  final double textScaleClampMax;

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: AppStrings.appName,
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      showPerformanceOverlay: false,
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        if (!_loggedMaterialAppBuilder) {
          _loggedMaterialAppBuilder = true;
          StartupPerfLog.log('material_app_builder_first');
        }
        StartupBlurShaderWarmup.scheduleOnce(
          resolveOverlay: () => AppRouter.navigatorKey.currentState?.overlay,
        );
        final app = applyDevicePreviewAppBuilder(context, child);
        final routedChild = DefaultRouteSystemUiOverlay(
          child: app,
        );
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler:
                tilawaProductTextScaler(
                  MediaQuery.textScalerOf(context),
                ).clamp(
                  minScaleFactor: textScaleClampMin,
                  maxScaleFactor: textScaleClampMax,
                ),
          ),
          child: TilawaFeedbackHost(
            child: SessionVerificationBanner(child: routedChild),
          ),
        );
      },
      theme: AppTheme.getLightTheme(
        primaryColor: themeSnapshot.primaryColor,
        locale: locale,
        extensions: const [QuranReaderTheme.light],
      ),
      darkTheme: AppTheme.getDarkTheme(
        primaryColor: themeSnapshot.primaryColor,
        locale: locale,
        isDefaultPreset: themeSnapshot.isDefaultPreset,
        darkIsTrueBlack: themeSnapshot.darkIsTrueBlack,
        extensions: const [QuranReaderTheme.dark],
      ),
      themeMode: themeSnapshot.themeMode,
      routerConfig: AppRouter.router,
      restorationScopeId: AppRouter.disableStateRestoration
          ? null
          : AppStrings.restorationScopeId,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        ...AppLocalizations.localizationsDelegates,
        quran_image_l10n.QuranImageLocalizations.delegate,
        quran_sessions_l10n.QuranSessionsLocalizations.delegate,
      ],
    );
  }
}
