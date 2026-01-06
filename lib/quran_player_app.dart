import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';

import 'core/constants/app_strings.dart';
import 'core/di/injection.dart';
import 'core/providers/providers.dart';
import 'core/services/interfaces/notification_dispatcher_interface.dart';
import 'core/theme/app_theme.dart';
import 'features/downloads/data/services/download_queue_manager.dart';
import 'features/localization/presentation/bloc/localization_bloc.dart';
import 'features/theme/presentation/cubit/theme_cubit.dart';
import 'l10n/generated/app_localizations.dart';
import 'main.dart';
import 'router/app_router.dart';

class QuranPlayerApp extends StatefulWidget {
  const QuranPlayerApp({super.key});

  @override
  State<QuranPlayerApp> createState() => _QuranPlayerAppState();
}

class _QuranPlayerAppState extends State<QuranPlayerApp>
    with WidgetsBindingObserver {
  bool _hasProcessedLaunchNotification = false;
  Timer? _resumeDebounceTimer;
  bool _isCheckingNotification = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Process launch notification after first frame when router is ready
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _processLaunchNotificationIfNeeded();
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
      });
    }
  }

  Future<void> _checkForNotificationOnResume() async {
    // Guard against concurrent checks
    if (_isCheckingNotification) return;
    _isCheckingNotification = true;

    try {
      final INotificationDispatcher dispatcher =
          getIt<INotificationDispatcher>();
      final bool processed = await dispatcher.processLaunchNotification();
      if (processed) {
        logger.d('[QuranPlayerApp] Launch notification processed on resume');
      }
    } catch (e) {
      logger.d('[QuranPlayerApp] Error checking notification on resume: $e');
    } finally {
      _isCheckingNotification = false;
    }
  }

  Future<void> _processLaunchNotificationIfNeeded() async {
    if (_hasProcessedLaunchNotification) return;
    _hasProcessedLaunchNotification = true;

    try {
      final INotificationDispatcher dispatcher =
          getIt<INotificationDispatcher>();
      final bool processed = await dispatcher.processLaunchNotification();
      if (processed) {
        logger.d('Launch notification processed after app ready');
      }
    } catch (e) {
      logger.d('Error processing launch notification: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScreenUtilPlusInit(
      designSize: const Size(390, 844),
      child: AppProviders.create(child: const _PlayerApp()),
    );
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
      },
      child: BlocBuilder<LocalizationBloc, LocalizationState>(
        builder: (context, locState) {
          // Set initial locale for download notifications
          getIt<DownloadQueueManager>().locale = locState.locale;

          return BlocBuilder<ThemeCubit, ThemeState>(
            builder: (context, themeState) {
              return MaterialApp.router(
                title: AppStrings.appName,
                debugShowCheckedModeBanner: false,
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
