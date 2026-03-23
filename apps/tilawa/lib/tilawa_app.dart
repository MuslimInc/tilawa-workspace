import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:device_preview/device_preview.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tilawa_core/constants/app_strings.dart';
import 'package:tilawa_core/services/interfaces/notification_dispatcher_interface.dart';
import 'package:tilawa_ui/theme/app_theme.dart';

import 'core/di/injection.dart';
import 'core/providers/app_providers.dart';
import 'core/services/update_service.dart';
import 'features/downloads/data/services/batch_download_manager.dart';
import 'features/downloads/data/services/download_queue_manager.dart';
import 'features/notifications/presentation/services/fcm_notification_handler_service.dart';
import 'features/localization/presentation/bloc/localization_bloc.dart';
import 'features/theme/presentation/cubit/theme_cubit.dart';
import 'l10n/generated/app_localizations.dart';
import 'main.dart';
import 'router/app_router.dart';

class TilawaApp extends StatefulWidget {
  const TilawaApp({super.key});

  @override
  State<TilawaApp> createState() => _TilawaAppState();
}

class _TilawaAppState extends State<TilawaApp> with WidgetsBindingObserver {
  bool _hasProcessedLaunchNotification = false;
  Timer? _resumeDebounceTimer;
  bool _isCheckingNotification = false;
  int? _lastProcessedNotificationId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Process launch notification after first frame when router is ready
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _processLaunchNotificationIfNeeded();
      _checkForUpdate();
    });
  }

  @override
  void dispose() {
    _resumeDebounceTimer?.cancel();
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
        _checkForUpdate();
      });
    }
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
      final INotificationDispatcher dispatcher =
          getIt<INotificationDispatcher>();

      // Check if the launch notification is the same one we already handled.
      // getNotificationAppLaunchDetails() returns the SAME data on every call,
      // so we compare the notification ID to avoid re-processing.
      final launchDetails = await dispatcher.getNotificationAppLaunchDetails();
      final int? currentId = launchDetails?.notificationResponse?.id;
      if (currentId == null || currentId == _lastProcessedNotificationId) {
        return;
      }

      final bool processed = await dispatcher.processLaunchNotification();
      if (processed) {
        _lastProcessedNotificationId = currentId;
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

    if (AppRouter.pendingStartupNotificationLaunch) {
      AppRouter.pendingStartupNotificationLaunch = false;
      return;
    }

    try {
      final INotificationDispatcher dispatcher =
          getIt<INotificationDispatcher>();
      final bool processed = await dispatcher.processLaunchNotification();
      if (processed) {
        logger.d('Launch notification processed after app ready');
        return;
      }

      final RemoteMessage? initialMessage = await FirebaseMessaging.instance
          .getInitialMessage()
          .timeout(const Duration(seconds: 3), onTimeout: () => null);
      if (initialMessage != null) {
        await getIt<FCMNotificationHandlerService>().handleRemoteMessageTap(
          initialMessage,
        );
        logger.d('Initial FCM message processed after app ready');
      }
    } catch (e) {
      logger.d('Error processing launch notification: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppProviders.create(child: const _PlayerApp());
  }
}

class _PlayerApp extends StatelessWidget {
  const _PlayerApp();

  @override
  Widget build(BuildContext context) {
    return BlocListener<LocalizationBloc, LocalizationState>(
      listener: (context, state) {
        // Update download notification locale when app locale changes
        getIt<DownloadQueueManager>().locale = state.locale;
        getIt<BatchDownloadManager>().locale = state.locale;
      },
      child: BlocBuilder<LocalizationBloc, LocalizationState>(
        builder: (context, locState) {
          return BlocBuilder<ThemeCubit, ThemeState>(
            builder: (context, themeState) {
              return MaterialApp.router(
                title: AppStrings.appName,
                debugShowCheckedModeBanner: false,
                builder: DevicePreview.appBuilder,
                theme: AppTheme.getLightTheme(
                  primaryColor: themeState.primaryColor,
                ),
                darkTheme: AppTheme.getDarkTheme(
                  primaryColor: themeState.primaryColor,
                ),
                themeMode: themeState.mode,
                routerConfig: AppRouter.router,
                // Disable restoration when launched from notification
                restorationScopeId: AppRouter.disableStateRestoration
                    ? null
                    : AppStrings.restorationScopeId,
                locale: locState.locale,
                supportedLocales: AppLocalizations.supportedLocales,
                localizationsDelegates: AppLocalizations.localizationsDelegates,
              );
            },
          );
        },
      ),
    );
  }
}
