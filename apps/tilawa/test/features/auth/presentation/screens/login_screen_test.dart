import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mockito/mockito.dart';
import 'package:tilawa/core/bootstrap/splash_launch_handoff.dart';
import 'package:tilawa/features/auth/application/account_deletion_flow_tracker.dart';
import 'package:tilawa/features/auth/data/services/android_sign_in_platform_policy.dart';
import 'package:tilawa/features/auth/data/services/google_sign_in_session_tracker.dart';
import 'package:tilawa/features/auth/domain/entities/auth_result.dart';
import 'package:tilawa/features/auth/domain/entities/user_entity.dart';
import 'package:tilawa/features/auth/domain/usecases/delete_account.dart';
import 'package:tilawa/features/auth/domain/usecases/get_current_user_use_case.dart';
import 'package:tilawa/features/auth/domain/usecases/sign_in_with_google_use_case.dart';
import 'package:tilawa/features/auth/domain/usecases/sign_out.dart';
import 'package:tilawa/features/auth/domain/usecases/sync_device_token_use_case.dart';
import 'package:tilawa/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:tilawa/features/auth/presentation/screens/login_screen.dart';
import 'package:tilawa/features/auth/presentation/services/google_sign_in_interactive_launcher.dart';
import 'package:tilawa/features/theme/domain/primary_color_preset.dart';
import 'package:tilawa/l10n/generated/app_localizations.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../../../helpers/hydrated_bloc_test_helper.dart';
import '../bloc/auth_bloc_test.mocks.dart';
import '../services/google_sign_in_interactive_launcher_test.mocks.dart';

class TestGoogleSignInInteractiveLauncher extends GoogleSignInInteractiveLauncher {
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

void main() {
  final TestWidgetsFlutterBinding binding =
      TestWidgetsFlutterBinding.ensureInitialized();
  final GetIt getIt = GetIt.instance;

  late MockSignInWithGoogleUseCase mockSignInWithGoogleUseCase;
  late MockSignOut mockSignOut;
  late MockDeleteAccount mockDeleteAccount;
  late MockGetCurrentUserUseCase mockGetCurrentUserUseCase;
  late MockSyncDeviceTokenUseCase mockSyncDeviceTokenUseCase;
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
    await initializeHydratedStorageForTest();
  });

  tearDownAll(() async {
    await clearHydratedStorageForTest();
  });

  setUp(() async {
    await getIt.reset();
    mockSignInWithGoogleUseCase = MockSignInWithGoogleUseCase();
    mockSignOut = MockSignOut();
    mockDeleteAccount = MockDeleteAccount();
    mockGetCurrentUserUseCase = MockGetCurrentUserUseCase();
    mockSyncDeviceTokenUseCase = MockSyncDeviceTokenUseCase();
    accountDeletionFlowTracker = AccountDeletionFlowTracker();
    sessionTracker = GoogleSignInSessionTracker();
    testLauncher = TestGoogleSignInInteractiveLauncher();

    when(mockGetCurrentUserUseCase()).thenReturn(null);
    when(mockSyncDeviceTokenUseCase(any)).thenAnswer((_) async {});

    authBloc = AuthBloc(
      mockSignInWithGoogleUseCase,
      mockSignOut,
      mockDeleteAccount,
      mockGetCurrentUserUseCase,
      mockSyncDeviceTokenUseCase,
      accountDeletionFlowTracker,
    );

    getIt.registerSingleton<GoogleSignInInteractiveLauncher>(testLauncher);
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
  }

  Finder googleButtonFinder() {
    return find.byType(TilawaButton);
  }

  bool isGoogleButtonLoading(WidgetTester tester) {
    return tester.widget<TilawaButton>(googleButtonFinder()).isLoading;
  }

  void registerAutoSignInPolicy() {
    getIt.unregister<AndroidSignInPlatformPolicy>();
    getIt.registerSingleton<AndroidSignInPlatformPolicy>(
      AndroidSignInPlatformPolicy.test(skipAutomaticSignIn: false),
    );
  }

  group('LoginScreen', () {
    testWidgets('renders welcome copy and the Google sign-in button', (
      WidgetTester tester,
    ) async {
      await pumpLoginScreen(tester);
      await pumpLoginInitFrames(tester);

      expect(find.text('Welcome to Tilawa'), findsOneWidget);
      expect(find.text('Continue with Google'), findsOneWidget);
      expect(find.text('Privacy policy'), findsOneWidget);
    });

    testWidgets('manual tap launches sign-in through the interactive launcher', (
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

      expect(testLauncher.settledInvocations, 1);
      verify(mockSignInWithGoogleUseCase()).called(1);
      expect(isGoogleButtonLoading(tester), isTrue);

      signInCompleter.complete(AuthResult.success(user: testUser));
      await tester.pump();

      expect(authBloc.state, isA<AuthAuthenticated>());
    });

    testWidgets('keeps the button loading while the Google session is in flight', (
      WidgetTester tester,
    ) async {
      await pumpLoginScreen(tester);
      sessionTracker.markStarted();
      binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();

      expect(isGoogleButtonLoading(tester), isTrue);
      expect(sessionTracker.inFlight, isTrue);
    });

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
        tester.widget<TilawaButton>(googleButtonFinder()).onPressed,
        isNotNull,
      );
    });

    testWidgets('does not dispatch CheckAuthStatus while sign-in is in flight', (
      WidgetTester tester,
    ) async {
      registerAutoSignInPolicy();

      when(
        mockSignInWithGoogleUseCase(),
      ).thenAnswer((_) => Completer<AuthResult>().future);

      await pumpLoginScreen(tester);
      await pumpLoginInitFrames(tester);

      expect(authBloc.state, isA<AuthLoading>());

      sessionTracker.markStarted();
      clearInteractions(mockGetCurrentUserUseCase);

      binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();

      verifyNever(mockGetCurrentUserUseCase());
    });

    testWidgets('dispatches CheckAuthStatus after resume when loading stalls', (
      WidgetTester tester,
    ) async {
      registerAutoSignInPolicy();

      when(
        mockSignInWithGoogleUseCase(),
      ).thenAnswer((_) => Completer<AuthResult>().future);

      await pumpLoginScreen(tester);
      await pumpLoginInitFrames(tester);

      expect(authBloc.state, isA<AuthLoading>());

      clearInteractions(mockGetCurrentUserUseCase);

      binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();

      verify(mockGetCurrentUserUseCase()).called(1);
    });

    testWidgets('skips auto sign-in during account deletion flow', (
      WidgetTester tester,
    ) async {
      registerAutoSignInPolicy();
      accountDeletionFlowTracker.markDeletionStarted();

      await pumpLoginScreen(tester);
      await pumpLoginInitFrames(tester);

      verifyNever(mockSignInWithGoogleUseCase());
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
