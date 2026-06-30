import 'dart:async';

import 'package:dartz_plus/dartz_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tilawa/core/bootstrap/splash_launch_handoff.dart';
import 'package:tilawa/features/auth/application/account_deletion_flow_tracker.dart';
import 'package:tilawa/features/auth/data/services/android_sign_in_platform_policy.dart';
import 'package:tilawa/features/auth/data/services/google_sign_in_session_tracker.dart';
import 'package:tilawa/features/auth/domain/entities/auth_result.dart';
import 'package:tilawa/features/auth/domain/entities/user_entity.dart';
import 'package:tilawa/features/auth/domain/gateways/google_sign_in_launch_gateway.dart';
import 'package:tilawa/features/auth/domain/repositories/auth_repository.dart';
import 'package:tilawa/features/auth/domain/services/google_sign_in_launch_readiness_store.dart';
import 'package:tilawa/features/auth/domain/usecases/prepare_google_sign_in_use_case.dart';
import 'package:tilawa/features/auth/domain/usecases/prewarm_google_sign_in_launch_use_case.dart';
import 'package:tilawa/features/auth/domain/usecases/resolve_google_sign_in_launch_use_case.dart';
import 'package:tilawa/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:tilawa/features/auth/presentation/cubit/login_google_sign_in_cubit.dart';
import 'package:tilawa/features/auth/presentation/screens/login_screen.dart';
import 'package:tilawa/features/auth/presentation/services/google_sign_in_interactive_launcher.dart';
import 'package:tilawa/features/theme/domain/primary_color_preset.dart';
import 'package:tilawa/l10n/generated/app_localizations.dart';
import 'package:tilawa_core/config/language_config.dart';
import 'package:tilawa_core/errors/failures.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../../../helpers/hydrated_bloc_test_helper.dart';
import '../bloc/auth_bloc_test.mocks.dart';
import '../services/google_sign_in_interactive_launcher_test.mocks.dart';

class TestGoogleSignInInteractiveLauncher
    extends GoogleSignInInteractiveLauncher {
  TestGoogleSignInInteractiveLauncher()
    : super(
        MockGoogleSignIn(),
        AndroidSignInPlatformPolicy.test(skipAutomaticSignIn: true),
      );

  GoogleSignInLaunchReadiness readiness = const GoogleSignInLaunchReady();
  int settledInvocations = 0;

  @override
  Future<GoogleSignInLaunchReadiness> checkReadiness() async => readiness;

  @override
  Future<void> runAfterUiSettled(Future<void> Function() action) async {
    settledInvocations++;
    await action();
  }
}

class _NoopPrepareGoogleSignInUseCase extends PrepareGoogleSignInUseCase {
  _NoopPrepareGoogleSignInUseCase()
    : super(_ThrowingAuthRepositoryForPrepare());

  @override
  Future<void> call() async {}
}

class _ThrowingAuthRepositoryForPrepare implements AuthRepository {
  @override
  Stream<UserEntity?> get authStateChanges => const Stream.empty();

  @override
  UserEntity? get currentUser => null;

  @override
  Future<void> deleteAccount() async {}

  @override
  Future<void> prepareGoogleSignIn() async {}

  @override
  Future<AuthResult> signInWithGoogle() async => const AuthResult.cancelled();

  @override
  Future<void> signOut() async {}
}

void main() {
  final TestWidgetsFlutterBinding binding =
      TestWidgetsFlutterBinding.ensureInitialized();
  final GetIt getIt = GetIt.instance;

  late MockSignInWithGoogleUseCase mockSignInWithGoogleUseCase;
  late MockSignOut mockSignOut;
  late MockDeleteAccount mockDeleteAccount;
  late MockGetCurrentUserUseCase mockGetCurrentUserUseCase;
  late MockSyncDeviceTokenUseCase mockSyncDeviceTokenUseCase;
  late MockGetCurrentLanguageUseCase mockGetCurrentLanguageUseCase;
  late MockSyncUserLanguagePreferenceUseCase mockSyncUserLanguagePreference;
  late AccountDeletionFlowTracker accountDeletionFlowTracker;
  late GoogleSignInSessionTracker sessionTracker;
  late TestGoogleSignInInteractiveLauncher testLauncher;
  late AuthBloc authBloc;

  final UserEntity testUser = UserEntity(
    id: '1',
    email: 'test@example.com',
    displayName: 'Test User',
    createdAt: DateTime.utc(2023),
  );

  setUpAll(() async {
    provideDummy<Either<Failure, void>>(const Right(null));
    provideDummy<Either<Failure, String>>(
      Right(LanguageConfig.defaultLanguageCode),
    );
    SharedPreferences.setMockInitialValues({});
    await initializeHydratedStorageForTest();
  });

  tearDownAll(() async {
    await clearHydratedStorageForTest();
  });

  setUp(() async {
    TilawaInteractionFeedback.enabled = false;
    SharedPreferences.setMockInitialValues({});
    await getIt.reset();
    mockSignInWithGoogleUseCase = MockSignInWithGoogleUseCase();
    mockSignOut = MockSignOut();
    mockDeleteAccount = MockDeleteAccount();
    mockGetCurrentUserUseCase = MockGetCurrentUserUseCase();
    mockSyncDeviceTokenUseCase = MockSyncDeviceTokenUseCase();
    mockGetCurrentLanguageUseCase = MockGetCurrentLanguageUseCase();
    mockSyncUserLanguagePreference = MockSyncUserLanguagePreferenceUseCase();
    accountDeletionFlowTracker = AccountDeletionFlowTracker();
    sessionTracker = GoogleSignInSessionTracker();
    testLauncher = TestGoogleSignInInteractiveLauncher();

    when(mockGetCurrentUserUseCase()).thenReturn(null);
    when(mockSyncDeviceTokenUseCase(any)).thenAnswer(
      (_) async => const Right(null),
    );
    when(mockSyncDeviceTokenUseCase.registerExplicitSignIn(any)).thenAnswer(
      (_) async => const Right(null),
    );
    when(
      mockGetCurrentLanguageUseCase(),
    ).thenAnswer((_) async => Right(LanguageConfig.defaultLanguageCode));
    when(mockSyncUserLanguagePreference(any)).thenAnswer((_) async {});

    authBloc = AuthBloc(
      mockSignInWithGoogleUseCase,
      mockSignOut,
      mockDeleteAccount,
      mockGetCurrentUserUseCase,
      mockSyncDeviceTokenUseCase,
      mockGetCurrentLanguageUseCase,
      mockSyncUserLanguagePreference,
      accountDeletionFlowTracker,
      sessionTracker,
    );

    getIt.registerSingleton<GoogleSignInLaunchGateway>(testLauncher);
    getIt.registerSingleton<GoogleSignInLaunchReadinessStore>(
      GoogleSignInLaunchReadinessStore(),
    );
    getIt.registerFactory<LoginGoogleSignInCubit>(
      () => LoginGoogleSignInCubit(
        PrewarmGoogleSignInLaunchUseCase(
          _NoopPrepareGoogleSignInUseCase(),
          getIt<GoogleSignInLaunchReadinessStore>(),
        ),
        ResolveGoogleSignInLaunchUseCase(
          getIt<GoogleSignInLaunchReadinessStore>(),
        ),
      ),
    );
    getIt.registerSingleton<AndroidSignInPlatformPolicy>(
      AndroidSignInPlatformPolicy.test(skipAutomaticSignIn: true),
    );
    getIt.registerSingleton<AccountDeletionFlowTracker>(
      accountDeletionFlowTracker,
    );
    getIt.registerSingleton<GoogleSignInSessionTracker>(sessionTracker);

    SplashLaunchHandoff.splashRouteHasPainted.value = true;
    binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
  });

  tearDown(() async {
    sessionTracker.markFinished();
    await authBloc.close();
    await getIt.reset();
  });

  Future<void> pumpLoginScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.getLightTheme(
          primaryColor: PrimaryColorPreset.defaultPreset.value,
        ),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        locale: const Locale('en'),
        builder: (BuildContext context, Widget? child) {
          return TilawaFeedbackHost(child: child!);
        },
        home: BlocProvider<AuthBloc>.value(
          value: authBloc,
          child: const LoginScreen(),
        ),
      ),
    );
    await tester.pump();
  }

  Future<void> pumpLoginInitFrames(WidgetTester tester) async {
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  Finder googleButtonFinder() {
    return find.byType(TilawaGoogleSignInButton);
  }

  bool isGoogleButtonLoading(WidgetTester tester) {
    return tester
        .widget<TilawaGoogleSignInButton>(googleButtonFinder())
        .isLoading;
  }

  void registerAutoSignInPolicy() {
    getIt.unregister<AndroidSignInPlatformPolicy>();
    getIt.registerSingleton<AndroidSignInPlatformPolicy>(
      AndroidSignInPlatformPolicy.test(skipAutomaticSignIn: false),
    );
  }

  Future<void> completeSignInAndPump(
    WidgetTester tester,
    Completer<AuthResult> completer,
    AuthResult result,
  ) async {
    completer.complete(result);
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 16));
      final bool authSettled = result.when(
        success: (_) => authBloc.state is AuthAuthenticated,
        failure: (_, _, _) => authBloc.state is AuthError,
        cancelled: () => authBloc.state is AuthUnauthenticated,
        noGoogleAccounts: () => authBloc.state is AuthNoGoogleAccounts,
      );
      if (authSettled) {
        return;
      }
    }
  }

  Future<void> pumpUntilAuthLoading(WidgetTester tester) async {
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 50));
      if (authBloc.state is AuthLoading) {
        return;
      }
    }
  }

  group('LoginScreen', () {
    testWidgets('renders welcome copy and the Google sign-in button', (
      WidgetTester tester,
    ) async {
      await pumpLoginScreen(tester);
      await pumpLoginInitFrames(tester);

      expect(find.text('Welcome to MeMuslim'), findsOneWidget);
      expect(find.text('Sign in with Google'), findsOneWidget);
      expect(find.text('Privacy policy'), findsOneWidget);
    });

    testWidgets(
      'manual tap launches sign-in through the interactive launcher',
      (
        WidgetTester tester,
      ) async {
        final Completer<AuthResult> signInCompleter = Completer<AuthResult>();
        when(
          mockSignInWithGoogleUseCase(),
        ).thenAnswer((_) => signInCompleter.future);

        await pumpLoginScreen(tester);
        await pumpLoginInitFrames(tester);

        await tester.tap(googleButtonFinder());
        await tester.pump();
        await tester.runAsync(() async {
          await authBloc.stream.firstWhere(
            (AuthState state) => state is AuthLoading,
          );
        });
        await tester.pump();

        expect(testLauncher.settledInvocations, 0);
        verify(mockSignInWithGoogleUseCase()).called(1);
        expect(isGoogleButtonLoading(tester), isTrue);

        await tester.runAsync(() async {
          signInCompleter.complete(AuthResult.success(user: testUser));
          await authBloc.stream.firstWhere((AuthState state) {
            return state is AuthAuthenticated ||
                state is AuthError ||
                state is AuthUnauthenticated;
          });
        });
        await tester.pump();

        expect(authBloc.state, isA<AuthAuthenticated>());
        verify(
          mockSyncDeviceTokenUseCase.registerExplicitSignIn(testUser.id),
        ).called(1);
      },
    );

    testWidgets('clears pending loading when readiness is a platform error', (
      WidgetTester tester,
    ) async {
      testLauncher.readiness = const GoogleSignInLaunchPlatformError(
        code: 'test',
        message: 'blocked',
      );

      await pumpLoginScreen(tester);
      await pumpLoginInitFrames(tester);

      await tester.tap(googleButtonFinder());
      await tester.pump();

      verifyNever(mockSignInWithGoogleUseCase());
      expect(isGoogleButtonLoading(tester), isFalse);
      expect(find.text('blocked'), findsOneWidget);
    });

    testWidgets('prewarms readiness into store on screen create', (
      WidgetTester tester,
    ) async {
      final GoogleSignInLaunchReadinessStore store =
          GoogleSignInLaunchReadinessStore();
      getIt.unregister<GoogleSignInLaunchReadinessStore>();
      getIt.registerSingleton<GoogleSignInLaunchReadinessStore>(store);
      testLauncher.readiness = const GoogleSignInLaunchUiUnavailable();

      await pumpLoginScreen(tester);
      await pumpLoginInitFrames(tester);
      await tester.pump(const Duration(milliseconds: 100));

      expect(store.cached, isA<GoogleSignInLaunchUiUnavailable>());
    });

    testWidgets('manual tap uses cached readiness without UI settle', (
      WidgetTester tester,
    ) async {
      when(
        mockSignInWithGoogleUseCase(),
      ).thenAnswer((_) async => const AuthResult.cancelled());

      await pumpLoginScreen(tester);
      await pumpLoginInitFrames(tester);
      await tester.pump(const Duration(milliseconds: 100));

      testLauncher.readiness = const GoogleSignInLaunchUiUnavailable();
      expect(
        getIt<GoogleSignInLaunchReadinessStore>().cached,
        isA<GoogleSignInLaunchReady>(),
      );

      await tester.tap(googleButtonFinder());
      await tester.pump();
      await tester.runAsync(() async {
        await authBloc.stream.firstWhere(
          (AuthState state) => state is AuthLoading,
        );
      });
      await tester.pump();

      expect(testLauncher.settledInvocations, 0);
      verify(mockSignInWithGoogleUseCase()).called(1);
    });

    testWidgets('shows fallback toast when platform error has no message', (
      WidgetTester tester,
    ) async {
      testLauncher.readiness = const GoogleSignInLaunchPlatformError(
        code: 'test',
      );

      await pumpLoginScreen(tester);
      await pumpLoginInitFrames(tester);

      await tester.tap(googleButtonFinder());
      await tester.pump();

      expect(
        find.text('Unable to sign in with third-party account'),
        findsOneWidget,
      );
    });

    testWidgets('dispatches sign-in when the interactive launcher is missing', (
      WidgetTester tester,
    ) async {
      getIt.unregister<GoogleSignInLaunchGateway>();

      when(
        mockSignInWithGoogleUseCase(),
      ).thenAnswer((_) async => const AuthResult.cancelled());

      await pumpLoginScreen(tester);
      await pumpLoginInitFrames(tester);

      await tester.tap(googleButtonFinder());
      await tester.pump();
      await tester.runAsync(() async {
        await authBloc.stream.firstWhere(
          (AuthState state) => state is AuthLoading,
        );
      });
      await tester.pump();

      verify(mockSignInWithGoogleUseCase()).called(1);
    });

    testWidgets(
      'keeps the button loading while the Google session is in flight',
      (
        WidgetTester tester,
      ) async {
        await pumpLoginScreen(tester);
        sessionTracker.markStarted();
        binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
        binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
        await tester.pump();

        expect(isGoogleButtonLoading(tester), isTrue);
        expect(sessionTracker.inFlight, isTrue);
      },
    );

    testWidgets('clears pending loading when readiness is uiUnavailable', (
      WidgetTester tester,
    ) async {
      testLauncher.readiness = const GoogleSignInLaunchUiUnavailable();

      await pumpLoginScreen(tester);
      await pumpLoginInitFrames(tester);

      await tester.tap(googleButtonFinder());
      await tester.pump();

      verifyNever(mockSignInWithGoogleUseCase());
      expect(isGoogleButtonLoading(tester), isFalse);
      expect(
        tester.widget<TilawaGoogleSignInButton>(googleButtonFinder()).onPressed,
        isNotNull,
      );
      expect(
        find.textContaining('Update Google Play Services'),
        findsOneWidget,
      );
    });

    testWidgets(
      'does not dispatch CheckAuthStatus while sign-in is in flight',
      (
        WidgetTester tester,
      ) async {
        when(
          mockSignInWithGoogleUseCase(),
        ).thenAnswer((_) => Completer<AuthResult>().future);

        await pumpLoginScreen(tester);
        await pumpLoginInitFrames(tester);

        authBloc.add(const SignInWithGoogleEvent());
        await tester.runAsync(() async {
          await authBloc.stream.firstWhere(
            (AuthState state) => state is AuthLoading,
          );
        });
        await tester.pump();

        expect(authBloc.state, isA<AuthLoading>());

        clearInteractions(mockGetCurrentUserUseCase);

        binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
        binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
        await tester.pump();

        verifyNever(mockGetCurrentUserUseCase());
      },
    );

    testWidgets('skips auto sign-in during account deletion flow', (
      WidgetTester tester,
    ) async {
      registerAutoSignInPolicy();
      accountDeletionFlowTracker.markDeletionStarted();

      await pumpLoginScreen(tester);
      await pumpLoginInitFrames(tester);

      verifyNever(mockSignInWithGoogleUseCase());
    });

    testWidgets('shows no toast when manual sign-in is cancelled', (
      WidgetTester tester,
    ) async {
      final Completer<AuthResult> signInCompleter = Completer<AuthResult>();
      when(
        mockSignInWithGoogleUseCase(),
      ).thenAnswer((_) => signInCompleter.future);

      await pumpLoginScreen(tester);
      await pumpLoginInitFrames(tester);

      await tester.tap(googleButtonFinder());
      await tester.pump();
      await tester.runAsync(() async {
        await authBloc.stream.firstWhere(
          (AuthState state) => state is AuthLoading,
        );
      });
      await tester.pump();

      expect(authBloc.state, isA<AuthLoading>());

      signInCompleter.complete(const AuthResult.cancelled());
      await tester.pump();
      await tester.pump();

      expect(authBloc.state, isA<AuthUnauthenticated>());
      expect(
        find.textContaining('No Google account found on this device'),
        findsNothing,
      );
      expect(
        find.text('Unable to sign in with third-party account'),
        findsNothing,
      );
    });

    testWidgets(
      'surfaces noGoogleAccounts when CM is unavailable and chooser dismissed',
      (
        WidgetTester tester,
      ) async {
        final Completer<AuthResult> signInCompleter = Completer<AuthResult>();
        when(
          mockSignInWithGoogleUseCase(),
        ).thenAnswer((_) => signInCompleter.future);

        await pumpLoginScreen(tester);
        await pumpLoginInitFrames(tester);

        await tester.tap(googleButtonFinder());
        await tester.pump();
        await tester.runAsync(() async {
          await authBloc.stream.firstWhere(
            (AuthState state) => state is AuthLoading,
          );
        });
        await tester.pump();

        await completeSignInAndPump(
          tester,
          signInCompleter,
          const AuthResult.noGoogleAccounts(),
        );

        expect(authBloc.state, isA<AuthNoGoogleAccounts>());
      },
    );

    testWidgets('shows auth error toast when sign-in returns failure', (
      WidgetTester tester,
    ) async {
      final Completer<AuthResult> signInCompleter = Completer<AuthResult>();
      when(
        mockSignInWithGoogleUseCase(),
      ).thenAnswer((_) => signInCompleter.future);

      await pumpLoginScreen(tester);
      await pumpLoginInitFrames(tester);

      await tester.tap(googleButtonFinder());
      await tester.pump();
      await tester.runAsync(() async {
        await authBloc.stream.firstWhere(
          (AuthState state) => state is AuthLoading,
        );
      });
      await tester.pump();

      await completeSignInAndPump(
        tester,
        signInCompleter,
        const AuthResult.failure(message: 'Network down'),
      );

      expect(authBloc.state, isA<AuthError>());
    });

    testWidgets('marks splash handoff painted when still false on init', (
      WidgetTester tester,
    ) async {
      SplashLaunchHandoff.splashRouteHasPainted.value = false;

      await pumpLoginScreen(tester);
      await tester.pump();

      expect(SplashLaunchHandoff.splashRouteHasPainted.value, isTrue);
    });
  });
}
