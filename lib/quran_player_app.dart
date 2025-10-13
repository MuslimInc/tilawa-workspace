import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:muzakri/core/providers/providers.dart';
import 'package:muzakri/features/localization/presentation/bloc/localization_bloc.dart';
import 'package:muzakri/features/theme/presentation/cubit/theme_cubit.dart';
import 'package:muzakri/l10n/generated/app_localizations.dart';
import 'package:muzakri/router/app_router.dart';

class QuranPlayerApp extends StatelessWidget {
  const QuranPlayerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      child: AppProviders.create(
        child: BlocBuilder<LocalizationBloc, LocalizationState>(
          builder: (context, locState) {
            return BlocBuilder<ThemeCubit, ThemeState>(
              builder: (context, themeState) {
                return MaterialApp.router(
                  title: 'Muzakri',
                  debugShowCheckedModeBanner: false,
                  theme: ThemeData(primarySwatch: Colors.blue),
                  darkTheme: ThemeData.dark(),
                  themeMode: themeState.mode,
                  routerConfig: AppRouter.router,
                  locale: locState.locale,
                  supportedLocales: AppLocalizations.supportedLocales,
                  localizationsDelegates:
                      AppLocalizations.localizationsDelegates,
                );
              },
            );
          },
        ),
      ),
    );
  }
}
