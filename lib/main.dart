import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:muzakri/bloc/alphabet_scrollbar/alphabet_scrollbar_bloc.dart';
import 'package:muzakri/bloc/audio_player/audio_player_bloc.dart';
import 'package:muzakri/bloc/localization/localization_bloc.dart';
import 'package:muzakri/bloc/reciter_details/reciter_details_bloc.dart';
import 'package:muzakri/bloc/reciters/reciters_bloc.dart';
import 'package:muzakri/di_container.dart';
import 'package:muzakri/l10n/generated/app_localizations.dart';
import 'package:muzakri/router/app_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initDI();

  // Bloc.observer = AppBlocObserver();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      child: MultiBlocProvider(
        providers: [
          BlocProvider<LocalizationBloc>(
            create: (context) => getIt<LocalizationBloc>(),
          ),
          BlocProvider<RecitersBloc>(
            create: (context) => getIt<RecitersBloc>(),
          ),
          BlocProvider<ReciterDetailsBloc>(
            create: (context) => getIt<ReciterDetailsBloc>(),
          ),
          BlocProvider<AlphabetScrollbarBloc>(
            create: (context) => getIt<AlphabetScrollbarBloc>(),
          ),
          BlocProvider<AudioPlayerBloc>(
            create: (context) => getIt<AudioPlayerBloc>(),
          ),
        ],
        child: BlocBuilder<LocalizationBloc, LocalizationState>(
          builder: (context, state) {
            return MaterialApp.router(
              title: 'Muzakri',
              debugShowCheckedModeBanner: false,
              theme: ThemeData(primarySwatch: Colors.blue),
              routerConfig: AppRouter.router,
              locale: state.locale,
              supportedLocales: AppLocalizations.supportedLocales,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
            );
          },
        ),
      ),
    );
  }
}

class AppBlocObserver extends BlocObserver {
  @override
  void onEvent(Bloc bloc, Object? event) {
    super.onEvent(bloc, event);
    print('[BlocObserver] onEvent: $event');
  }

  @override
  void onTransition(Bloc bloc, Transition transition) {
    super.onTransition(bloc, transition);
    print('[BlocObserver] onTransition: $transition');
  }

  @override
  void onError(BlocBase bloc, Object error, StackTrace stackTrace) {
    super.onError(bloc, error, stackTrace);
    print('[BlocObserver] onError: $error');
  }
}
