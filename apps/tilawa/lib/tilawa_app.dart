import 'dart:async';
import 'dart:io';

import 'package:device_preview/device_preview.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quran_image/core/perf_logger.dart';
import 'package:quran_image/l10n/app_localizations.dart' as quran_image_l10n;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tilawa/core/bootstrap/app_startup.dart';
import 'package:tilawa/core/logging/app_logger.dart';
import 'package:tilawa_core/constants/app_strings.dart';
import 'package:tilawa_core/services/app_system_chrome_style.dart';
import 'package:tilawa_core/services/interfaces/notification_dispatcher_interface.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import 'core/di/injection.dart';
import 'core/providers/app_providers.dart';
import 'core/services/update_service.dart';
import 'features/downloads/data/services/batch_download_manager.dart';
import 'features/downloads/data/services/download_queue_manager.dart';
import 'features/localization/presentation/bloc/localization_bloc.dart';
import 'features/theme/presentation/cubit/theme_cubit.dart';
import 'l10n/generated/app_localizations.dart';
import 'router/app_router.dart';

class TilawaApp extends StatefulWidget {
  const TilawaApp({super.key});

  @override
  State<TilawaApp> createState() => _TilawaAppState();
}

class _TilawaAppState extends State<TilawaApp> with WidgetsBindingObserver {
  static const Duration _initialUpdateCheckDelay = Duration(seconds: 8);
  static const Duration _resumeUpdateCheckDelay = Duration(seconds: 2);
  static const Duration _deferredColdStartLocalProbeDelay = Duration(
    milliseconds: 900,
  );

  bool _hasProcessedLaunchNotification = false;
  bool _hasPrimedNotificationDispatcher = false;
  Timer? _resumeDebounceTimer;
  Timer? _updateCheckTimer;
  Timer? _localLaunchProbeTimer;
  bool _isCheckingNotification = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Process launch notification after first frame when router is ready
    SchedulerBinding.instance.addPostFrameCallback((_) {
      logger.d(
        'ROUTER_READY navigatorContext=${AppRouter.navigatorKey.currentContext != null}',
      );
      _processLaunchNotificationIfNeeded();
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
    _localLaunchProbeTimer?.cancel();
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
      // When app is resumed (warm start from notification), check for launch notification
      // Use debounce to prevent excessive checks when rapidly switching states
      _resumeDebounceTimer = Timer(const Duration(milliseconds: 100), () {
        _checkForNotificationOnResume();
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
      '[PerfLogger][Startup] update-check scheduled '
      'reason=$reason delayMs=${delay.inMilliseconds}',
    );
    _updateCheckTimer = Timer(delay, () {
      logger.d('[PerfLogger][Startup] update-check started reason=$reason');
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

  Future<void> _checkForNotificationOnResume() async {
    // Guard against concurrent checks
    if (_isCheckingNotification) {
      logger.d(
        '[QuranPlayerApp] _checkForNotificationOnResume: skipped – already checking',
      );
      return;
    }
    _isCheckingNotification = true;
    logger.d(
      '[QuranPlayerApp] _checkForNotificationOnResume: started, lastProcessedId=${AppRouter.lastProcessedNotificationId}',
    );

    try {
      await initializeNotificationHandlers();

      final INotificationDispatcher dispatcher =
          getIt<INotificationDispatcher>();

      // Check if the launch notification is the same one we already handled.
      // getNotificationAppLaunchDetails() returns the SAME data on every call,
      // so we compare the notification ID to avoid re-processing.
      final launchDetails = await dispatcher.getNotificationAppLaunchDetails();
      final int? currentId = launchDetails?.notificationResponse?.id;
      logger.d(
        '[QuranPlayerApp] _checkForNotificationOnResume: currentId=$currentId didLaunch=${launchDetails?.didNotificationLaunchApp}',
      );
      if (currentId == null ||
          currentId == AppRouter.lastProcessedNotificationId) {
        logger.d(
          '[QuranPlayerApp] _checkForNotificationOnResume: skipped – same id or null',
        );
        return;
      }

      logger.d(
        '[QuranPlayerApp] _checkForNotificationOnResume: processing notification id=$currentId',
      );
      final bool processed = await dispatcher.processLaunchNotification();
      if (processed) {
        AppRouter.lastProcessedNotificationId = currentId;
        logger.d('[QuranPlayerApp] Launch notification processed on resume');
      }
    } catch (e) {
      logger.d('[QuranPlayerApp] Error checking notification on resume: $e');
    } finally {
      _isCheckingNotification = false;
    }
  }

  Future<void> _processLaunchNotificationIfNeeded() async {
    if (_hasProcessedLaunchNotification) {
      return;
    }
    _hasProcessedLaunchNotification = true;

    // Large-scale startup pattern: avoid eager heavy notification wiring on
    // every cold start. Only process immediately when startup was actually
    // notification-driven.
    if (AppRouter.pendingStartupNotificationLaunch) {
      await initializeNotificationHandlers();
      AppRouter.pendingStartupNotificationLaunch = false;
      return;
    }

    // Probe local-notification cold-start lazily so startup frames stay fast.
    _localLaunchProbeTimer?.cancel();
    _localLaunchProbeTimer = Timer(_deferredColdStartLocalProbeDelay, () {
      if (!mounted) return;
      unawaited(_checkForDeferredColdStartLocalNotification());
    });
  }

  static const String _lastNotifIdKey = '_last_notif_id';
  static const String _lastNotifPidKey = '_last_notif_pid';
  // On hot restart the Dart VM resets all statics but the Android process
  // (and its PID) stays alive. On a genuine cold start the OS assigns a new
  // PID. Storing the PID alongside the notification ID lets us distinguish
  // "same process, Dart restarted" from "brand-new launch" reliably, with no
  // time-window guessing.

  Future<void> _checkForDeferredColdStartLocalNotification() async {
    if (_isCheckingNotification) {
      logger.d(
        '[QuranPlayerApp] _checkForDeferredColdStart: skipped – already checking',
      );
      return;
    }
    _isCheckingNotification = true;
    logger.d(
      '[QuranPlayerApp] _checkForDeferredColdStart: started, lastProcessedId=${AppRouter.lastProcessedNotificationId}',
    );

    try {
      final INotificationDispatcher dispatcher =
          getIt<INotificationDispatcher>();
      if (!_hasPrimedNotificationDispatcher) {
        await dispatcher.initialize(createHighImportanceChannel: false);
        _hasPrimedNotificationDispatcher = true;
      }

      // Restore lastProcessedNotificationId from persistent storage to handle
      // Dart VM restarts (hot restart) where static fields are cleared but the
      // Android Activity's Intent—and therefore getNotificationAppLaunchDetails()
      // —still returns the previously-processed notification.
      if (AppRouter.lastProcessedNotificationId == null) {
        final prefs = SharedPreferencesAsync();
        final storedId = await prefs.getInt(_lastNotifIdKey);
        final storedPid = await prefs.getInt(_lastNotifPidKey);
        final currentPid = pid;
        logger.d(
          '[QuranPlayerApp] _checkForDeferredColdStart: prefs storedId=$storedId storedPid=$storedPid currentPid=$currentPid',
        );
        if (storedId != null && storedPid == currentPid) {
          // Same process → hot restart. Suppress re-navigation.
          AppRouter.lastProcessedNotificationId = storedId;
          logger.d(
            '[QuranPlayerApp] _checkForDeferredColdStart: restored lastProcessedId=$storedId (hot restart)',
          );
        }
      }

      final launchDetails = await dispatcher.getNotificationAppLaunchDetails();
      final bool didLaunch = launchDetails?.didNotificationLaunchApp ?? false;
      final int? currentId = launchDetails?.notificationResponse?.id;
      logger.d(
        '[QuranPlayerApp] _checkForDeferredColdStart: didLaunch=$didLaunch currentId=$currentId lastProcessedId=${AppRouter.lastProcessedNotificationId}',
      );

      if (!didLaunch ||
          currentId == null ||
          currentId == AppRouter.lastProcessedNotificationId) {
        logger.d(
          '[QuranPlayerApp] _checkForDeferredColdStart: skipped – didLaunch=$didLaunch currentId=$currentId lastProcessedId=${AppRouter.lastProcessedNotificationId}',
        );
        return;
      }

      logger.d(
        '[QuranPlayerApp] _checkForDeferredColdStart: processing notification id=$currentId',
      );
      await initializeNotificationHandlers();
      final bool processed = await dispatcher.processLaunchNotification();
      if (processed) {
        AppRouter.lastProcessedNotificationId = currentId;
        final prefs = SharedPreferencesAsync();
        await prefs.setInt(_lastNotifIdKey, currentId);
        await prefs.setInt(_lastNotifPidKey, pid);
        logger.d(
          '[QuranPlayerApp] Deferred cold-start local notification processed',
        );
      }
    } catch (e) {
      logger.d(
        '[QuranPlayerApp] Error processing deferred cold-start notification: $e',
      );
    } finally {
      _isCheckingNotification = false;
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
              // Derive UI density from launch config (default: compact).
              // Override with --dart-define=TILAWA_COMPACT_UI=false for comfortable.
              final density = appLaunchConfig.compactUiEnabled
                  ? TilawaDensity.compact
                  : TilawaDensity.comfortable;
              final bool isDark = themeState.mode == ThemeMode.dark;
              final Brightness iconBrightness = isDark
                  ? Brightness.light
                  : Brightness.dark;
              final Brightness statusBarBrightness = isDark
                  ? Brightness.dark
                  : Brightness.light;
              AppSystemChromeStyle.updateDefaultAppStyle(
                SystemUiOverlayStyle(
                  statusBarColor: const Color(0x00000000),
                  statusBarIconBrightness: iconBrightness,
                  statusBarBrightness: statusBarBrightness,
                  systemNavigationBarColor: const Color(0x00000000),
                  systemNavigationBarDividerColor: const Color(0x00000000),
                  systemNavigationBarIconBrightness: iconBrightness,
                  systemStatusBarContrastEnforced: false,
                  systemNavigationBarContrastEnforced: false,
                ),
              );
              return MaterialApp.router(
                title: AppStrings.appName,
                showPerformanceOverlay: false,
                debugShowCheckedModeBanner: false,
                // showPerformanceOverlay: kDebugMode || kProfileMode,
                // checkerboardRasterCacheImages: kDebugMode || kProfileMode,
                builder: (context, child) {
                  final Widget app = DevicePreview.appBuilder(context, child);
                  return MediaQuery(
                    data: MediaQuery.of(context).copyWith(
                      textScaler: MediaQuery.textScalerOf(
                        context,
                      ).clamp(minScaleFactor: 1.0, maxScaleFactor: 1.4),
                    ),
                    child: app,
                  );
                },
                theme: AppTheme.getLightTheme(
                  primaryColor: themeState.primaryColor,
                  density: density,
                ),
                darkTheme: AppTheme.getDarkTheme(
                  primaryColor: themeState.primaryColor,
                  density: density,
                ),
                themeMode: themeState.mode,
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
