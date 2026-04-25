import 'dart:async';

import 'package:device_preview/device_preview.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quran_image/core/perf_logger.dart';
import 'package:quran_image/l10n/app_localizations.dart' as quran_image_l10n;
import 'package:tilawa/core/bootstrap/app_startup.dart';
import 'package:tilawa/core/logging/app_logger.dart';
import 'package:tilawa_core/constants/app_strings.dart';
import 'package:tilawa_core/services/interfaces/notification_dispatcher_interface.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import 'core/di/injection.dart';
import 'core/providers/app_providers.dart';
import 'core/services/update_service.dart';
import 'features/downloads/data/services/batch_download_manager.dart';
import 'features/downloads/data/services/download_queue_manager.dart';
import 'features/localization/presentation/bloc/localization_bloc.dart';
import 'features/quran_reader/presentation/theme/quran_reader_theme.dart';
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
      return;
    }
    _isCheckingNotification = true;

    try {
      await initializeNotificationHandlers();

      final INotificationDispatcher dispatcher =
          getIt<INotificationDispatcher>();

      // Check if the launch notification is the same one we already handled.
      // getNotificationAppLaunchDetails() returns the SAME data on every call,
      // so we compare the notification ID to avoid re-processing.
      final launchDetails = await dispatcher.getNotificationAppLaunchDetails();
      final int? currentId = launchDetails?.notificationResponse?.id;
      if (currentId == null ||
          currentId == AppRouter.lastProcessedNotificationId) {
        return;
      }

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

  Future<void> _checkForDeferredColdStartLocalNotification() async {
    if (_isCheckingNotification) {
      return;
    }
    _isCheckingNotification = true;

    try {
      final INotificationDispatcher dispatcher =
          getIt<INotificationDispatcher>();
      if (!_hasPrimedNotificationDispatcher) {
        await dispatcher.initialize(createHighImportanceChannel: false);
        _hasPrimedNotificationDispatcher = true;
      }

      final launchDetails = await dispatcher.getNotificationAppLaunchDetails();
      final bool didLaunch = launchDetails?.didNotificationLaunchApp ?? false;
      final int? currentId = launchDetails?.notificationResponse?.id;

      if (!didLaunch ||
          currentId == null ||
          currentId == AppRouter.lastProcessedNotificationId) {
        return;
      }

      await initializeNotificationHandlers();
      final bool processed = await dispatcher.processLaunchNotification();
      if (processed) {
        AppRouter.lastProcessedNotificationId = currentId;
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
              return MaterialApp.router(
                title: AppStrings.appName,
                showPerformanceOverlay: kProfileMode,
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
                  extensions: [QuranReaderTheme.light],
                ),
                darkTheme: AppTheme.getDarkTheme(
                  primaryColor: themeState.primaryColor,
                  extensions: [QuranReaderTheme.dark],
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
