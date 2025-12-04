import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'core/providers/providers.dart';
import 'features/localization/presentation/bloc/localization_bloc.dart';
import 'features/theme/presentation/cubit/theme_cubit.dart';
import 'l10n/generated/app_localizations.dart';
import 'router/app_router.dart';

class QuranPlayerApp extends StatelessWidget {
  const QuranPlayerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      child: AppProviders.create(child: const _PlayerApp()),
    );
  }
}

class _PlayerApp extends StatelessWidget {
  const _PlayerApp();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LocalizationBloc, LocalizationState>(
      builder: (context, locState) {
        return BlocBuilder<ThemeCubit, ThemeState>(
          builder: (context, themeState) {
            return MaterialApp.router(
              title: 'Muzakri',
              debugShowCheckedModeBanner: false,
              theme: FlexThemeData.light(
                scheme: themeState.scheme,
                surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
                blendLevel: 7,
                appBarStyle: FlexAppBarStyle.primary,
                appBarOpacity: 0.95,
                appBarElevation: 0,
                tabBarStyle: FlexTabBarStyle.forAppBar,
                tooltipsMatchBackground: true,
                visualDensity: FlexColorScheme.comfortablePlatformDensity,
                useMaterial3ErrorColors: true,
              ),
              darkTheme: FlexThemeData.dark(
                scheme: themeState.scheme,
                surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
                blendLevel: 13,
                appBarStyle: FlexAppBarStyle.background,
                appBarOpacity: 0.90,
                appBarElevation: 0,
                tabBarStyle: FlexTabBarStyle.forAppBar,
                tooltipsMatchBackground: true,
                visualDensity: FlexColorScheme.comfortablePlatformDensity,
                useMaterial3ErrorColors: true,
              ),
              themeMode: themeState.mode,
              routerConfig: AppRouter.router,
              locale: locState.locale,
              supportedLocales: AppLocalizations.supportedLocales,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
            );
          },
        );
      },
    );
  }
}
