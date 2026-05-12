import 'dart:async';

import 'package:device_preview/device_preview.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quran_image/core/perf_logger.dart';
import 'package:quran_image/l10n/app_localizations.dart' as quran_image_l10n;
import 'package:tilawa/core/bootstrap/app_startup.dart';
import 'package:tilawa/core/logging/app_logger.dart';
import 'package:tilawa/features/quran_reader/presentation/theme/quran_reader_theme.dart';
import 'package:tilawa_core/constants/app_strings.dart';
import 'package:tilawa_core/services/app_system_chrome_style.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import 'core/di/injection.dart';
import 'core/providers/app_providers.dart';
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
        'ROUTER_READY navigatorContext=${AppRouter.navigatorKey.currentContext != null}',
      );
      unawaited(_notificationStartupService.handleAppStartup());
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
              final density = appLaunchConfig.compactUiEnabled
                  ? TilawaDensity.compact
                  : TilawaDensity.comfortable;
              return MaterialApp.router(
                title: AppStrings.appName,
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
                  final routedChild = _DefaultRouteSystemUiOverlay(child: app);
                  return MediaQuery(
                    data: MediaQuery.of(context).copyWith(
                      textScaler: MediaQuery.textScalerOf(
                        context,
                      ).clamp(minScaleFactor: 1.0, maxScaleFactor: 1.4),
                    ),
                    child: routedChild,
                  );
                },
                theme: AppTheme.getLightTheme(
                  primaryColor: themeState.primaryColor,
                  density: density,
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
                  density: density,
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

class _DefaultRouteSystemUiOverlay extends StatelessWidget {
  const _DefaultRouteSystemUiOverlay({required this.child});

  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final overlayStyle = AppSystemChromeStyle.buildDefaultAppStyle(
      Theme.of(context),
    );
    AppSystemChromeStyle.updateDefaultAppStyle(overlayStyle);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayStyle,
      child: child ?? const SizedBox.shrink(),
    );
  }
}
