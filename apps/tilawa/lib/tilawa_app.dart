import 'dart:async';

import 'package:device_preview/device_preview.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quran_image/core/perf_logger.dart';
import 'package:quran_image/l10n/app_localizations.dart' as quran_image_l10n;
import 'package:tilawa/core/logging/app_logger.dart';
import 'package:tilawa/features/quran_reader/presentation/theme/quran_reader_theme.dart';
import 'package:tilawa_core/constants/app_strings.dart';
import 'package:tilawa_core/services/app_system_chrome_style.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import 'core/di/injection.dart';
import 'app/app_providers.dart';
import 'core/bootstrap/splash_launch_handoff.dart';
import 'core/services/notification_startup_service.dart';
import 'core/services/update_service.dart';
import 'features/downloads/data/services/batch_download_manager.dart';
import 'features/downloads/data/services/download_queue_manager.dart';
import 'features/localization/presentation/bloc/localization_bloc.dart';
import 'features/theme/domain/entities/app_theme_preset.dart';
import 'features/theme/domain/primary_color_preset.dart';
import 'features/theme/presentation/cubit/theme_cubit.dart';
import 'features/theme/presentation/theme_state_material.dart';
import 'l10n/generated/app_localizations.dart';
import 'router/app_router.dart';
import 'shared/widgets/quran_player_chrome.dart';
import 'router/app_router_config.dart';

class TilawaApp extends StatefulWidget {
  const TilawaApp({super.key});

  @override
  State<TilawaApp> createState() => _TilawaAppState();
}

class _TilawaAppState extends State<TilawaApp> with WidgetsBindingObserver {
  static const Duration _initialUpdateCheckDelay = Duration(seconds: 8);
  static const Duration _resumeUpdateCheckDelay = Duration(seconds: 2);

  Timer? _resumeDebounceTimer;
  Timer? _updateCheckTimer;

  late final NotificationStartupService _notificationStartupService =
      getIt<NotificationStartupService>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    SchedulerBinding.instance.addPostFrameCallback((_) {
      logger.d(
        'ROUTER_READY navigatorContext=${AppRouter.navigatorKey.currentContext != null} '
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
    });
  }

  @override
  void dispose() {
    _resumeDebounceTimer?.cancel();
    _updateCheckTimer?.cancel();
    _notificationStartupService.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Cancel any pending debounce timer to prevent duplicate checks
    _resumeDebounceTimer?.cancel();

    if (state == AppLifecycleState.resumed) {
      logger.d('[QuranPlayerApp] App resumed - checking for notification');
      _resumeDebounceTimer = Timer(const Duration(milliseconds: 100), () {
        unawaited(_notificationStartupService.handleAppResume());
        _scheduleUpdateCheck(
          delay: _resumeUpdateCheckDelay,
          reason: 'app-resumed',
        );
      });
    }
  }

  void _scheduleUpdateCheck({required Duration delay, required String reason}) {
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
      if (getIt.isRegistered<UpdateService>()) {
        // Run in background to not block UI
        getIt<UpdateService>().checkForUpdate();
      }
    } catch (e) {
      logger.d('[QuranPlayerApp] Error checking for update: $e');
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
  static const double _kTextScaleClampMax = 1.4;

  @override
  Widget build(BuildContext context) {
    PerfLogger.markBuild('PlayerAppMaterialRoot');
    return BlocListener<LocalizationBloc, LocalizationState>(
      listener: (context, state) {
        // Update download notification locale when app locale changes
        getIt<DownloadQueueManager>().locale = state.locale;
        getIt<BatchDownloadManager>().locale = state.locale;
      },
      child: BlocBuilder<LocalizationBloc, LocalizationState>(
        builder: (context, locState) {
          PerfLogger.markBuild('LocalizationBlocBuilder');
          return BlocBuilder<ThemeCubit, ThemeState>(
            builder: (context, themeState) {
              PerfLogger.markBuild('ThemeBlocBuilder');
              return MaterialApp.router(
                title: AppStrings.appName,
                onGenerateTitle: (context) =>
                    AppLocalizations.of(context)!.appTitle,
                showPerformanceOverlay: false,
                debugShowCheckedModeBanner: false,
                // showPerformanceOverlay: kDebugMode || kProfileMode,
                // checkerboardRasterCacheImages: kDebugMode || kProfileMode,
                builder: (context, child) {
                  // Release: skip DevicePreview.appBuilder — no preview ancestor
                  // work; profile/debug still use it when preview is enabled.
                  final app = kReleaseMode
                      ? (child ?? const SizedBox.shrink())
                      : DevicePreview.appBuilder(context, child);
                  final routedChild = _DefaultRouteSystemUiOverlay(
                    child: app,
                  );
                  return MediaQuery(
                    data: MediaQuery.of(context).copyWith(
                      textScaler:
                          MediaQuery.textScalerOf(
                            context,
                          ).clamp(
                            minScaleFactor: _kTextScaleClampMin,
                            maxScaleFactor: _kTextScaleClampMax,
                          ),
                    ),
                    child: routedChild,
                  );
                },
                theme: AppTheme.getLightTheme(
                  primaryColor: themeState.primaryColor,
                  extensions: [QuranReaderTheme.light],
                ),
                darkTheme: AppTheme.getDarkTheme(
                  primaryColor: themeState.primaryColor,
                  isDefaultPreset:
                      themeState.primaryColorSource ==
                          PrimaryColorSource.preset &&
                      themeState.primaryPresetId ==
                          PrimaryColorPreset.defaultPreset.id,
                  darkIsTrueBlack:
                      themeState.preset == AppThemePreset.trueBlack,
                  extensions: [QuranReaderTheme.dark],
                ),
                themeMode: themeState.themeMode,
                routerConfig: AppRouter.router,
                // Disable restoration when launched from notification
                restorationScopeId: AppRouter.disableStateRestoration
                    ? null
                    : AppStrings.restorationScopeId,
                locale: locState.locale,
                supportedLocales: AppLocalizations.supportedLocales,
                localizationsDelegates: const [
                  ...AppLocalizations.localizationsDelegates,
                  quran_image_l10n.AppLocalizations.delegate,
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _DefaultRouteSystemUiOverlay extends StatefulWidget {
  const _DefaultRouteSystemUiOverlay({required this.child});

  final Widget? child;

  @override
  State<_DefaultRouteSystemUiOverlay> createState() =>
      _DefaultRouteSystemUiOverlayState();
}

class _DefaultRouteSystemUiOverlayState
    extends State<_DefaultRouteSystemUiOverlay> {
  SystemUiOverlayStyle? _lastAppliedStyle;
  bool _launchHandoffScheduled = false;
  bool _loggedFirstBuild = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncSystemUiOverlay();
  }

  void _syncSystemUiOverlay() {
    final theme = Theme.of(context);
    final Color? playerNavOverride = context
        .read<QuranPlayerChromeNotifier>()
        .systemNavigationBarColorOverride;
    // Match the OS gesture strip to the Tilawa floating bottom-nav so the
    // two read as one continuous surface — otherwise the strip leaks the
    // primary-harmonised `colorScheme.surface` underneath the white nav.
    final overlayStyle = AppSystemChromeStyle.buildDefaultAppStyle(
      theme,
      navigationBarColor:
          playerNavOverride ??
          theme.componentTokens.adaptiveShell.bottomNavBackgroundColor,
    );
    if (_lastAppliedStyle == overlayStyle) {
      return;
    }
    _lastAppliedStyle = overlayStyle;
    AppSystemChromeStyle.updateDefaultAppStyle(overlayStyle);
    SystemChrome.setSystemUIOverlayStyle(overlayStyle);
  }

  void _scheduleLaunchHandoffMark() {
    if (_launchHandoffScheduled ||
        widget.child == null ||
        SplashLaunchHandoff.splashRouteHasPainted.value) {
      return;
    }
    _launchHandoffScheduled = true;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _launchHandoffScheduled = false;
      if (!mounted ||
          widget.child == null ||
          SplashLaunchHandoff.splashRouteHasPainted.value) {
        return;
      }
      // #region agent log
      fixBlackFrameLog(
        runId: 'post-fix',
        hypothesisId: 'H5',
        location:
            'tilawa_app.dart:_DefaultRouteSystemUiOverlayState._scheduleLaunchHandoffMark',
        message: 'Routed app first frame callback',
        data: const <String, Object?>{},
      );
      // #endregion
      SplashLaunchHandoff.markSplashRoutePainted();
    });
  }

  @override
  Widget build(BuildContext context) {
    context.watch<QuranPlayerChromeNotifier>();
    _syncSystemUiOverlay();
    _scheduleLaunchHandoffMark();
    if (!_loggedFirstBuild) {
      _loggedFirstBuild = true;
      // #region agent log
      fixBlackFrameLog(
        runId: 'flutter-handoff-baseline',
        hypothesisId: 'H4',
        location: 'tilawa_app.dart:_DefaultRouteSystemUiOverlayState.build',
        message: 'DefaultRouteSystemUiOverlay first build',
        data: <String, Object?>{
          'hasChild': widget.child != null,
        },
      );
      // #endregion
    }
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: _lastAppliedStyle!,
      child: widget.child ?? const SizedBox.shrink(),
    );
  }
}
