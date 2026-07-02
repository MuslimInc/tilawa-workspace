import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz_plus/dartz_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tilawa/core/bootstrap/app_startup_readiness.dart';
import 'package:tilawa/core/bootstrap/startup_launch_coordinator.dart';
import 'package:tilawa/core/navigation/navigation_source.dart';
import 'package:tilawa/features/auth/domain/entities/user_entity.dart';
import 'package:tilawa/features/auth/domain/repositories/auth_repository.dart';
import 'package:tilawa/features/auth/domain/usecases/await_auth_restoration_use_case.dart';
import 'package:tilawa/features/auth/domain/usecases/get_current_user_use_case.dart';
import 'package:tilawa/features/auth/domain/usecases/sign_out.dart';
import 'package:tilawa/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:tilawa/features/auth/presentation/cubit/session_validity_cubit.dart';
import 'package:tilawa/features/auth/domain/usecases/prepare_google_sign_in_use_case.dart';
import 'package:tilawa/features/onboarding/domain/usecases/check_onboarding_status.dart';
import 'package:tilawa/features/splash/domain/repositories/startup_notification_repository.dart';
import 'package:tilawa/features/splash/domain/usecases/get_splash_next_route_use_case.dart';
import 'package:tilawa/router/app_router.dart';
import 'package:tilawa/router/app_router_config.dart';
import 'package:tilawa/router/deep_link_resolver.dart';
import 'package:tilawa/router/quran_sessions_session_guard.dart';

class MockAppStartupReadiness extends Mock implements AppStartupReadiness {}

class MockPrepareGoogleSignInUseCase extends Mock
    implements PrepareGoogleSignInUseCase {}

class MockAuthRepository extends Mock implements AuthRepository {}

class MockGetCurrentUserUseCase extends Mock implements GetCurrentUserUseCase {}

class MockCheckOnboardingStatus extends Mock implements CheckOnboardingStatus {}

class MockStartupNotificationRepository extends Mock
    implements StartupNotificationRepository {}

class MockSignOut extends Mock implements SignOut {}

class MockSessionValidityCubit extends MockCubit<SessionValidityState>
    implements SessionValidityCubit {}

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

class FakeGoRouterState extends Fake implements GoRouterState {
  FakeGoRouterState(this.path);

  @override
  final String path;

  @override
  Uri get uri => Uri.parse(path);
}

void main() {
  late MockAuthRepository mockAuthRepository;
  late MockGetCurrentUserUseCase mockGetCurrentUser;
  late MockCheckOnboardingStatus mockOnboarding;
  late MockStartupNotificationRepository mockStartupNotifications;
  late GetSplashNextRouteUseCase splashRouteUseCase;
  late UserEntity signedInUser;

  final String eveningAthkarLocation = AthkarDetailsRoute(
    categoryId: DeepLinkResolver.athkarEveningCategoryId,
    categoryName: DeepLinkResolver.athkarEveningCategoryName,
    source: NavigationSource.notification.wireValue,
  ).location;

  final Map<String, dynamic> eveningAthkarPayload = {
    'type': 'athkar',
    'categoryId': '2',
    'categoryName': 'Evening Athkar',
  };

  late MockAppStartupReadiness mockReadiness;
  late MockPrepareGoogleSignInUseCase mockPrepareGoogleSignIn;

  setUp(() {
    AppRouter.resetForTesting();
    mockAuthRepository = MockAuthRepository();
    mockGetCurrentUser = MockGetCurrentUserUseCase();
    mockOnboarding = MockCheckOnboardingStatus();
    mockStartupNotifications = MockStartupNotificationRepository();
    mockReadiness = MockAppStartupReadiness();
    mockPrepareGoogleSignIn = MockPrepareGoogleSignInUseCase();
    signedInUser = UserEntity(
      id: 'user_1',
      email: 'user@example.com',
      displayName: 'User',
      createdAt: DateTime.utc(2024),
    );

    when(() => mockOnboarding()).thenAnswer((_) async => true);
    when(
      () => mockStartupNotifications.consumePendingNotification(),
    ).thenReturn(null);
    when(
      () => mockReadiness.waitUntilReady(
        prepareShell: any(named: 'prepareShell'),
      ),
    ).thenAnswer((_) async {});
    when(() => mockReadiness.timedOut).thenReturn(false);
    when(() => mockReadiness.recitersDataReady).thenReturn(false);
    when(() => mockPrepareGoogleSignIn()).thenAnswer((_) async {});
  });

  tearDown(AppRouter.resetForTesting);

  GetSplashNextRouteUseCase buildSplashRouteUseCase({
    required Stream<UserEntity?> authStream,
    UserEntity? userAfterRestore,
  }) {
    when(
      () => mockAuthRepository.authStateChanges,
    ).thenAnswer((_) => authStream);
    when(() => mockGetCurrentUser()).thenReturn(userAfterRestore);
    final awaitAuth = AwaitAuthRestorationUseCase(mockAuthRepository);
    return GetSplashNextRouteUseCase(
      mockGetCurrentUser,
      mockOnboarding,
      mockStartupNotifications,
      awaitAuth,
    );
  }

  StartupLaunchCoordinator buildCoordinator(
    GetSplashNextRouteUseCase useCase,
  ) {
    return StartupLaunchCoordinator(
      useCase,
      mockPrepareGoogleSignIn,
      mockReadiness,
    );
  }

  group('notification auth flow', () {
    test(
      'Test 1: notification cold start waits for auth then routes to target',
      () async {
        final controller = StreamController<UserEntity?>();
        when(
          () => mockStartupNotifications.consumePendingNotification(),
        ).thenReturn(eveningAthkarPayload);
        AppRouter.setPendingColdStartRoute(eveningAthkarLocation);
        splashRouteUseCase = buildSplashRouteUseCase(
          authStream: controller.stream,
          userAfterRestore: signedInUser,
        );

        final Future<SplashRouteResult> splashFuture = splashRouteUseCase();
        await Future<void>.delayed(Duration.zero);
        controller.add(signedInUser);
        await controller.close();

        final SplashRouteResult splashResult = await splashFuture;
        expect(splashResult.destination, SplashDestination.notificationLaunch);
        verify(() => mockAuthRepository.authStateChanges).called(1);

        final StartupLaunchPlan plan = await buildCoordinator(
          splashRouteUseCase,
        ).resolve();

        expect(plan.target, StartupLaunchTarget.notification);
        expect(plan.location, eveningAthkarLocation);
        expect(plan.location, isNot(const LoginRoute().location));
      },
    );

    test(
      'Test 2: notification cold start with signed-out user routes to login',
      () async {
        final controller = StreamController<UserEntity?>();
        when(
          () => mockStartupNotifications.consumePendingNotification(),
        ).thenReturn(eveningAthkarPayload);
        AppRouter.setPendingColdStartRoute(eveningAthkarLocation);
        splashRouteUseCase = buildSplashRouteUseCase(
          authStream: controller.stream,
          userAfterRestore: null,
        );

        final Future<SplashRouteResult> splashFuture = splashRouteUseCase();
        await Future<void>.delayed(Duration.zero);
        controller.add(null);
        await controller.close();

        final SplashRouteResult splashResult = await splashFuture;
        expect(splashResult.destination, SplashDestination.login);
        verify(() => mockAuthRepository.authStateChanges).called(1);

        final StartupLaunchPlan plan = await buildCoordinator(
          splashRouteUseCase,
        ).resolve();

        expect(plan.target, StartupLaunchTarget.login);
        expect(plan.location, const LoginRoute().location);
        expect(AppRouter.pendingColdStartLocation, isNull);
      },
    );

    test(
      'Test 3: notification payload does not bypass auth restoration',
      () async {
        final controller = StreamController<UserEntity?>();
        when(
          () => mockStartupNotifications.consumePendingNotification(),
        ).thenReturn(eveningAthkarPayload);
        splashRouteUseCase = buildSplashRouteUseCase(
          authStream: controller.stream,
          userAfterRestore: signedInUser,
        );

        final Future<SplashRouteResult> resultFuture = splashRouteUseCase();
        await Future<void>.delayed(Duration.zero);

        var completedBeforeAuth = false;
        unawaited(
          resultFuture.then((_) {
            completedBeforeAuth = true;
          }),
        );
        await Future<void>.delayed(Duration.zero);
        expect(completedBeforeAuth, isFalse);
        verify(() => mockAuthRepository.authStateChanges).called(1);

        controller.add(signedInUser);
        await controller.close();

        final SplashRouteResult result = await resultFuture;
        expect(result.destination, SplashDestination.notificationLaunch);
      },
    );

    test(
      'Test 4: normal cold start with delayed auth restore routes home',
      () async {
        final controller = StreamController<UserEntity?>();
        splashRouteUseCase = buildSplashRouteUseCase(
          authStream: controller.stream,
          userAfterRestore: signedInUser,
        );

        final Future<SplashRouteResult> resultFuture = splashRouteUseCase();
        await Future<void>.delayed(Duration.zero);
        controller.add(signedInUser);
        await controller.close();

        final SplashRouteResult result = await resultFuture;

        expect(result.destination, SplashDestination.home);
        verify(() => mockAuthRepository.authStateChanges).called(1);

        final StartupLaunchPlan plan = await buildCoordinator(
          splashRouteUseCase,
        ).resolve();
        expect(plan.target, StartupLaunchTarget.home);
        expect(plan.location, isNot(const LoginRoute().location));
      },
    );

    test(
      'Test 5: normal cold start with signed-out user routes to login',
      () async {
        final controller = StreamController<UserEntity?>();
        splashRouteUseCase = buildSplashRouteUseCase(
          authStream: controller.stream,
          userAfterRestore: null,
        );

        final Future<SplashRouteResult> resultFuture = splashRouteUseCase();
        await Future<void>.delayed(Duration.zero);
        controller.add(null);
        await controller.close();

        final SplashRouteResult result = await resultFuture;

        expect(result.destination, SplashDestination.login);
        verify(() => mockAuthRepository.authStateChanges).called(1);

        final StartupLaunchPlan plan = await buildCoordinator(
          splashRouteUseCase,
        ).resolve();
        expect(plan.target, StartupLaunchTarget.login);
        expect(plan.location, const LoginRoute().location);
      },
    );

    test(
      'Test 6: pending notification route is consumed exactly once',
      () async {
        AppRouter.setPendingColdStartRoute(eveningAthkarLocation);
        when(
          () => mockStartupNotifications.consumePendingNotification(),
        ).thenReturn(eveningAthkarPayload);
        splashRouteUseCase = buildSplashRouteUseCase(
          authStream: Stream<UserEntity?>.value(signedInUser),
          userAfterRestore: signedInUser,
        );

        final StartupLaunchPlan notificationPlan = await buildCoordinator(
          splashRouteUseCase,
        ).resolve();

        expect(notificationPlan.target, StartupLaunchTarget.notification);
        expect(notificationPlan.location, eveningAthkarLocation);

        AppRouter.consumePendingNotificationLaunchState();
        expect(AppRouter.pendingColdStartLocation, isNull);
        expect(AppRouter.pendingStartupNotificationLaunch, isFalse);

        when(
          () => mockStartupNotifications.consumePendingNotification(),
        ).thenReturn(null);
        final StartupLaunchPlan homePlan = await buildCoordinator(
          buildSplashRouteUseCase(
            authStream: Stream<UserEntity?>.value(signedInUser),
            userAfterRestore: signedInUser,
          ),
        ).resolve();

        expect(homePlan.target, StartupLaunchTarget.home);
        expect(homePlan.location, const HomeRoute().location);
      },
    );

    test('Test 7: notification handling does not invoke sign-out', () async {
      final MockSignOut mockSignOut = MockSignOut();
      when(
        () => mockSignOut(
          skipServerTokenClear: any(named: 'skipServerTokenClear'),
        ),
      ).thenAnswer((_) async => const Right(null));

      when(
        () => mockStartupNotifications.consumePendingNotification(),
      ).thenReturn(eveningAthkarPayload);
      splashRouteUseCase = buildSplashRouteUseCase(
        authStream: Stream<UserEntity?>.value(signedInUser),
        userAfterRestore: signedInUser,
      );

      await splashRouteUseCase();

      verifyNever(
        () => mockSignOut(
          skipServerTokenClear: any(named: 'skipServerTokenClear'),
        ),
      );
    });

    test(
      'Test 8: auth restoration timeout falls back to currentUser snapshot',
      () async {
        when(() => mockAuthRepository.authStateChanges).thenAnswer(
          (_) => const Stream<UserEntity?>.empty(),
        );
        when(() => mockGetCurrentUser()).thenReturn(signedInUser);
        final awaitAuth = AwaitAuthRestorationUseCase(mockAuthRepository);
        splashRouteUseCase = GetSplashNextRouteUseCase(
          mockGetCurrentUser,
          mockOnboarding,
          mockStartupNotifications,
          awaitAuth,
        );

        final SplashRouteResult result = await splashRouteUseCase();

        expect(result.destination, SplashDestination.home);
        verify(() => mockAuthRepository.authStateChanges).called(1);
      },
    );
  });

  group('session guard auth restoring', () {
    late MockSessionValidityCubit mockSessionCubit;
    late MockAuthBloc mockAuthBloc;

    setUp(() {
      mockSessionCubit = MockSessionValidityCubit();
      mockAuthBloc = MockAuthBloc();
    });

    testWidgets('defers login redirect while AuthBloc is still initial', (
      tester,
    ) async {
      whenListen(
        mockSessionCubit,
        Stream<SessionValidityState>.empty(),
        initialState: const SessionValidityState(),
      );
      when(() => mockAuthBloc.state).thenReturn(const AuthState.initial());

      late String? result;
      await tester.pumpWidget(
        MaterialApp(
          home: MultiBlocProvider(
            providers: [
              BlocProvider<SessionValidityCubit>.value(value: mockSessionCubit),
              BlocProvider<AuthBloc>.value(value: mockAuthBloc),
            ],
            child: Builder(
              builder: (context) {
                result = quranSessionsSessionRedirect(
                  context,
                  FakeGoRouterState('/sessions'),
                );
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );

      expect(result, isNull);
    });
  });
}
