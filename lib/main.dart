import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:muzakri/core/di/injection_container.dart';
import 'package:muzakri/core/services/firebase_initialization_service.dart';
import 'package:muzakri/features/alphabet_scrollbar/presentation/bloc/alphabet_scrollbar_bloc.dart';
import 'package:muzakri/features/audio_player/presentation/bloc/audio_player_bloc.dart';
import 'package:muzakri/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:muzakri/features/auth/presentation/bloc/auth_event.dart';
import 'package:muzakri/features/downloads/presentation/bloc/downloads_bloc.dart';
import 'package:muzakri/features/localization/presentation/bloc/localization_bloc.dart';
import 'package:muzakri/features/premium/presentation/bloc/premium_bloc.dart';
import 'package:muzakri/features/reciters/presentation/bloc/reciter_details_bloc.dart';
import 'package:muzakri/features/reciters/presentation/bloc/reciters_bloc.dart';
import 'package:muzakri/features/theme/presentation/cubit/theme_cubit.dart';
import 'package:muzakri/firebase_options.dart';
import 'package:muzakri/l10n/generated/app_localizations.dart';
import 'package:muzakri/router/app_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await initDI();

  // Initialize Firebase data
  try {
    final firebaseInitService = sl<FirebaseInitializationService>();
    await firebaseInitService.initializeFirebaseData();
  } catch (e) {
    print('Warning: Could not initialize Firebase data: $e');
  }

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
          BlocProvider<ThemeCubit>(create: (context) => sl<ThemeCubit>()),
          BlocProvider<LocalizationBloc>(
            create: (context) => sl<LocalizationBloc>(),
          ),
          BlocProvider<RecitersBloc>(create: (context) => sl<RecitersBloc>()),
          BlocProvider<ReciterDetailsBloc>(
            create: (context) => sl<ReciterDetailsBloc>(),
          ),
          BlocProvider<AlphabetScrollbarBloc>(
            create: (context) => sl<AlphabetScrollbarBloc>(),
          ),
          BlocProvider<AudioPlayerBloc>(
            create: (context) => sl<AudioPlayerBloc>(),
          ),
          BlocProvider<DownloadsBloc>(
            create: (context) =>
                sl<DownloadsBloc>()..add(const LoadDownloads()),
          ),
          BlocProvider<PremiumBloc>(create: (context) => sl<PremiumBloc>()),
          BlocProvider<AuthBloc>(
            create: (context) {
              final authBloc = sl<AuthBloc>();
              authBloc.add(const CheckAuthStatusEvent());
              return authBloc;
            },
          ),
        ],
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
