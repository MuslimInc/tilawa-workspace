import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:tilawa/core/bootstrap/app_startup_readiness.dart';
import 'package:tilawa/core/bootstrap/startup_launch_coordinator.dart';
import 'package:tilawa/features/auth/domain/usecases/prepare_google_sign_in_use_case.dart';
import 'package:tilawa/features/splash/domain/usecases/get_splash_next_route_use_case.dart';
import 'package:tilawa/router/app_router.dart';
import 'package:tilawa/router/app_router_config.dart';

import 'startup_launch_coordinator_test.mocks.dart';

@GenerateMocks([
  GetSplashNextRouteUseCase,
  PrepareGoogleSignInUseCase,
  AppStartupReadiness,
])
void main() {
  late StartupLaunchCoordinator coordinator;
  late MockGetSplashNextRouteUseCase mockGetSplashNextRouteUseCase;
  late MockPrepareGoogleSignInUseCase mockPrepareGoogleSignIn;
  late MockAppStartupReadiness mockReadiness;

  setUp(() {
    AppRouter.resetForTesting();
    mockGetSplashNextRouteUseCase = MockGetSplashNextRouteUseCase();
    mockPrepareGoogleSignIn = MockPrepareGoogleSignInUseCase();
    mockReadiness = MockAppStartupReadiness();
    when(mockPrepareGoogleSignIn.call()).thenAnswer((_) async {});
    when(
      mockReadiness.waitUntilReady(prepareShell: anyNamed('prepareShell')),
    ).thenAnswer((_) async {});
    when(mockReadiness.timedOut).thenReturn(false);
    when(mockReadiness.recitersDataReady).thenReturn(false);
    coordinator = StartupLaunchCoordinator(
      mockGetSplashNextRouteUseCase,
      mockPrepareGoogleSignIn,
      mockReadiness,
    );
  });

  tearDown(AppRouter.resetForTesting);

  test('returns home plan and waits for shell prep', () async {
    when(mockGetSplashNextRouteUseCase.call()).thenAnswer(
      (_) async => const SplashRouteResult(SplashDestination.home),
    );

    final StartupLaunchPlan plan = await coordinator.resolve();

    expect(plan.target, StartupLaunchTarget.home);
    expect(plan.location, const HomeRoute().location);
    verify(mockReadiness.waitUntilReady(prepareShell: true)).called(1);
    verifyNever(mockPrepareGoogleSignIn.call());
  });

  test('returns login plan and prepares Google sign-in', () async {
    when(mockGetSplashNextRouteUseCase.call()).thenAnswer(
      (_) async => const SplashRouteResult(SplashDestination.login),
    );

    final StartupLaunchPlan plan = await coordinator.resolve();

    expect(plan.target, StartupLaunchTarget.login);
    expect(plan.location, const LoginRoute().location);
    verify(mockReadiness.waitUntilReady(prepareShell: false)).called(1);
    verify(mockPrepareGoogleSignIn.call()).called(1);
  });

  test(
    'prefers pending cold-start route when splash confirms authenticated home',
    () async {
      AppRouter.setPendingColdStartRoute(
        const PrayerNotificationStatusRoute().location,
        extra: '{"prayer_key":"fajr"}',
      );
      when(mockGetSplashNextRouteUseCase.call()).thenAnswer(
        (_) async => const SplashRouteResult(SplashDestination.home),
      );

      final StartupLaunchPlan plan = await coordinator.resolve();

      expect(plan.target, StartupLaunchTarget.notification);
      expect(plan.location, const PrayerNotificationStatusRoute().location);
      expect(plan.extra, '{"prayer_key":"fajr"}');
    },
  );

  test(
    'login plan discards pending cold-start route for unauthenticated user',
    () async {
      AppRouter.setPendingColdStartRoute(
        const PrayerNotificationStatusRoute().location,
      );
      when(mockGetSplashNextRouteUseCase.call()).thenAnswer(
        (_) async => const SplashRouteResult(SplashDestination.login),
      );

      final StartupLaunchPlan plan = await coordinator.resolve();

      expect(plan.target, StartupLaunchTarget.login);
      expect(plan.location, const LoginRoute().location);
      expect(AppRouter.pendingColdStartLocation, isNull);
    },
  );

  test('resolves notification payload to final route', () async {
    when(mockGetSplashNextRouteUseCase.call()).thenAnswer(
      (_) async => const SplashRouteResult(
        SplashDestination.notificationLaunch,
        notificationData: {'type': 'settings'},
      ),
    );

    final StartupLaunchPlan plan = await coordinator.resolve();

    expect(plan.target, StartupLaunchTarget.notification);
    expect(plan.location, const SettingsRoute().location);
    verify(mockReadiness.waitUntilReady(prepareShell: false)).called(1);
  });

  test('falls back to home when notification payload cannot resolve', () async {
    when(mockGetSplashNextRouteUseCase.call()).thenAnswer(
      (_) async =>
          const SplashRouteResult(SplashDestination.notificationLaunch),
    );
    when(mockReadiness.timedOut).thenReturn(true);

    final StartupLaunchPlan plan = await coordinator.resolve();

    expect(plan.target, StartupLaunchTarget.home);
    expect(plan.location, const HomeRoute().location);
    expect(plan.timedOut, isTrue);
  });
}
