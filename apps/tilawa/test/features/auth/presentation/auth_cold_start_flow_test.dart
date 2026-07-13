import 'dart:async';

import 'package:dartz_plus/dartz_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mockito/mockito.dart';
import 'package:tilawa/core/bootstrap/splash_launch_handoff.dart';
import 'package:tilawa/core/domain/server_action_guard.dart';
import 'package:tilawa/features/auth/data/services/android_sign_in_platform_policy.dart';
import 'package:tilawa/features/auth/domain/entities/auth_result.dart';
import 'package:tilawa/features/auth/domain/gateways/google_sign_in_launch_gateway.dart';
import 'package:tilawa/features/auth/domain/services/google_sign_in_launch_readiness_store.dart';
import 'package:tilawa/features/auth/domain/usecases/prewarm_google_sign_in_launch_use_case.dart';
import 'package:tilawa/features/auth/domain/usecases/resolve_google_sign_in_launch_use_case.dart';
import 'package:tilawa/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:tilawa/features/auth/presentation/cubit/login_google_sign_in_cubit.dart';
import 'package:tilawa/features/auth/presentation/screens/login_screen.dart';
import 'package:tilawa/features/localization/presentation/bloc/localization_bloc.dart';
import 'package:tilawa/features/splash/domain/usecases/get_splash_next_route_use_case.dart';
import 'package:tilawa/features/splash/presentation/bloc/splash_bloc.dart';
import 'package:tilawa/features/splash/presentation/bloc/splash_event.dart';
import 'package:tilawa/features/splash/presentation/bloc/splash_state.dart';
import 'package:tilawa/features/theme/domain/primary_color_preset.dart';
import 'package:tilawa/l10n/generated/app_localizations.dart';
import 'package:tilawa/router/app_router.dart';
import 'package:tilawa_core/config/language_config.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../../helpers/hydrated_bloc_test_helper.dart';
import '../../../helpers/noop_sync_user_language_preference_use_case.dart';
import '../../../support/fake_network_info.dart';
import '../helpers/auth_widget_test_harness.dart';
import 'bloc/auth_bloc_test.mocks.dart';
import 'screens/login_screen_test.dart';
import '../../splash/presentation/bloc/splash_bloc_test.mocks.dart';
import '../../localization/presentation/bloc/localization_bloc_test.mocks.dart'
    as localization_mocks;

/// Mirrors splash listener + login auth → home without full GoRouter.
class _ColdStartFlowHarness extends StatefulWidget {
  const _ColdStartFlowHarness({
    required this.splashBloc,
    required this.authBloc,
    required this.localizationBloc,
  });

  final SplashBloc splashBloc;
  final AuthBloc authBloc;
  final LocalizationBloc localizationBloc;

  @override
  State<_ColdStartFlowHarness> createState() => _ColdStartFlowHarnessState();
}

class _ColdStartFlowHarnessState extends State<_ColdStartFlowHarness> {
  bool _showLogin = false;
  bool _showHome = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.splashBloc.add(const SplashStarted());
    });
  }

  void _goHome() {
    if (!mounted) {
      return;
    }
    setState(() {
      _showLogin = false;
      _showHome = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: AppTheme.getLightTheme(
        primaryColor: PrimaryColorPreset.defaultPreset.value,
      ),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      locale: const Locale('en'),
      builder: (BuildContext context, Widget? child) {
        return TilawaFeedbackHost(child: child!);
      },
      home: MultiBlocProvider(
        providers: <BlocProvider<dynamic>>[
          BlocProvider<SplashBloc>.value(value: widget.splashBloc),
          BlocProvider<AuthBloc>.value(value: widget.authBloc),
          BlocProvider<LocalizationBloc>.value(
            value: widget.localizationBloc,
          ),
        ],
        child: MultiBlocListener(
          listeners: <BlocListener<dynamic, dynamic>>[
            BlocListener<SplashBloc, SplashState>(
              listener: (BuildContext context, SplashState state) {
                if (state is SplashNavigateToLogin) {
                  setState(() => _showLogin = true);
                }
                if (state is SplashNavigateToHome) {
                  _goHome();
                }
              },
            ),
            BlocListener<AuthBloc, AuthState>(
              listenWhen: (AuthState previous, AuthState current) {
                return current is AuthAuthenticated &&
                    previous is! AuthAuthenticated;
              },
              listener: (BuildContext context, AuthState state) => _goHome(),
            ),
          ],
          child: _showHome
              ? const Scaffold(
                  key: Key('home_phase'),
                  body: Center(child: Text('Home')),
                )
              : _showLogin
              ? const LoginScreen()
              : const Scaffold(
                  key: Key('splash_phase'),
                  body: Center(child: CircularProgressIndicator()),
                ),
        ),
      ),
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  provideAuthBlocDummies();
  provideDummy<bool>(false);

  setUpAll(() async {
    await initializeHydratedStorageForTest();
  });

  tearDownAll(() async {
    await clearHydratedStorageForTest();
  });
  late AuthWidgetTestHarness authHarness;
  late SplashBloc splashBloc;
  late MockGetSplashNextRouteUseCase mockGetSplashNextRoute;
  late MockPrepareGoogleSignInUseCase mockPrepareGoogleSignIn;
  late MockAppStartupReadiness mockReadiness;
  late LocalizationBloc localizationBloc;
  late TestGoogleSignInInteractiveLauncher testLauncher;
  late FakeNetworkInfo networkInfo;

  final GetIt getIt = GetIt.instance;

  setUp(() async {
    AppRouter.resetForTesting();
    TilawaInteractionFeedback.enabled = false;
    authHarness = AuthWidgetTestHarness();
    mockGetSplashNextRoute = MockGetSplashNextRouteUseCase();
    mockPrepareGoogleSignIn = MockPrepareGoogleSignInUseCase();
    mockReadiness = MockAppStartupReadiness();
    testLauncher = TestGoogleSignInInteractiveLauncher();
    networkInfo = FakeNetworkInfo();

    when(mockGetSplashNextRoute.call()).thenAnswer(
      (_) async => const SplashRouteResult(SplashDestination.login),
    );
    when(mockPrepareGoogleSignIn.call()).thenAnswer((_) async {});
    when(
      mockReadiness.waitUntilReady(prepareShell: anyNamed('prepareShell')),
    ).thenAnswer((_) async {});
    when(mockReadiness.warmShellPrepInBackground()).thenReturn(null);
    when(mockReadiness.timedOut).thenReturn(false);

    splashBloc = SplashBloc(
      mockGetSplashNextRoute,
      mockPrepareGoogleSignIn,
      mockReadiness,
    );

    final localization_mocks.MockSetLanguageUseCase mockSetLanguage =
        localization_mocks.MockSetLanguageUseCase();
    final localization_mocks.MockGetRecitersUseCase mockGetReciters =
        localization_mocks.MockGetRecitersUseCase();
    final MockGetCurrentLanguageUseCase mockGetCurrentLanguage =
        MockGetCurrentLanguageUseCase();
    when(
      mockGetCurrentLanguage(),
    ).thenAnswer((_) async => const Right(LanguageConfig.defaultLanguageCode));
    when(mockSetLanguage(any)).thenAnswer((_) async => const Right(null));
    when(mockGetReciters.invalidateCache()).thenReturn(null);

    localizationBloc = LocalizationBloc(
      mockGetCurrentLanguage,
      mockSetLanguage,
      mockGetReciters,
      noopSyncUserLanguagePreferenceUseCase(),
    );

    await getIt.reset();
    getIt.registerSingleton<GoogleSignInLaunchGateway>(testLauncher);
    getIt.registerSingleton<ServerActionGuard>(ServerActionGuard(networkInfo));
    getIt.registerSingleton<GoogleSignInLaunchReadinessStore>(
      GoogleSignInLaunchReadinessStore(),
    );
    getIt.registerFactory<LoginGoogleSignInCubit>(
      () => LoginGoogleSignInCubit(
        PrewarmGoogleSignInLaunchUseCase(
          mockPrepareGoogleSignIn,
          getIt<GoogleSignInLaunchReadinessStore>(),
        ),
        ResolveGoogleSignInLaunchUseCase(
          getIt<GoogleSignInLaunchReadinessStore>(),
        ),
        getIt<ServerActionGuard>(),
      ),
    );
    getIt.registerSingleton<AndroidSignInPlatformPolicy>(
      AndroidSignInPlatformPolicy.test(skipAutomaticSignIn: true),
    );
    getIt.registerSingleton(authHarness.accountDeletionFlowTracker);
    getIt.registerSingleton(authHarness.signInSessionTracker);

    SplashLaunchHandoff.splashRouteHasPainted.value = true;
  });

  tearDown(() async {
    authHarness.dispose();
    await splashBloc.close();
    await localizationBloc.close();
    await networkInfo.dispose();
    await getIt.reset();
    AppRouter.resetForTesting();
    reset(mockGetSplashNextRoute);
    reset(mockPrepareGoogleSignIn);
    reset(mockReadiness);
  });

  group('cold-start auth flow', () {
    testWidgets('splash routes to login then Google sign-in reaches home', (
      WidgetTester tester,
    ) async {
      final Completer<AuthResult> signInCompleter = Completer<AuthResult>();
      when(authHarness.mockSignInWithGoogle()).thenAnswer(
        (_) => signInCompleter.future,
      );

      await tester.pumpWidget(
        _ColdStartFlowHarness(
          splashBloc: splashBloc,
          authBloc: authHarness.authBloc,
          localizationBloc: localizationBloc,
        ),
      );
      await tester.pump();
      await tester.runAsync(() async {
        await splashBloc.stream.firstWhere(
          (SplashState state) => state is SplashNavigateToLogin,
        );
      });
      await tester.pump();

      expect(find.byKey(const Key('splash_phase')), findsNothing);
      expect(find.text('Welcome to MeMuslim'), findsOneWidget);

      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Sign in with Google'), findsOneWidget);

      await tester.tap(find.byType(TilawaGoogleSignInButton));
      await tester.pump();
      await tester.runAsync(() async {
        await authHarness.authBloc.stream.firstWhere(
          (AuthState state) => state is AuthLoading,
        );
      });
      await tester.pump();

      await tester.runAsync(() async {
        signInCompleter.complete(
          AuthResult.success(user: AuthWidgetTestHarness.defaultUser),
        );
        await authHarness.authBloc.stream.firstWhere(
          (AuthState state) => state is AuthAuthenticated,
        );
      });
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byKey(const Key('home_phase')), findsOneWidget);
      expect(find.text('Home'), findsOneWidget);
    });

    testWidgets('signed-in cold start skips login and reaches home', (
      WidgetTester tester,
    ) async {
      when(mockGetSplashNextRoute.call()).thenAnswer(
        (_) async => const SplashRouteResult(SplashDestination.home),
      );

      await tester.pumpWidget(
        _ColdStartFlowHarness(
          splashBloc: splashBloc,
          authBloc: authHarness.authBloc,
          localizationBloc: localizationBloc,
        ),
      );
      await tester.pump();
      await tester.runAsync(() async {
        await splashBloc.stream.firstWhere(
          (SplashState state) => state is SplashNavigateToHome,
        );
      });
      await tester.pump();

      expect(find.text('Welcome to MeMuslim'), findsNothing);
      expect(find.byKey(const Key('home_phase')), findsOneWidget);
    });
  });
}
