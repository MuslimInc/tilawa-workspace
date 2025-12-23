import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';

import 'core/di/injection.dart';
import 'core/providers/providers.dart';
import 'core/theme/app_theme.dart';
import 'features/downloads/data/services/download_queue_manager.dart';
import 'features/localization/presentation/bloc/localization_bloc.dart';
import 'features/theme/presentation/cubit/theme_cubit.dart';
import 'l10n/generated/app_localizations.dart';
import 'router/app_router.dart';

class QuranPlayerApp extends StatelessWidget {
  const QuranPlayerApp({super.key});

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
                title: 'Muzakri',
                debugShowCheckedModeBanner: false,
                theme: AppTheme.getLightTheme(themeState.scheme),
                darkTheme: AppTheme.getDarkTheme(themeState.scheme),
                themeMode: themeState.mode,
                routerConfig: AppRouter.router,
                restorationScopeId: 'quran_player_app',
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
