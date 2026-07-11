import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:tilawa/core/bootstrap/app_startup_readiness.dart';
import 'package:tilawa/features/auth/domain/usecases/prepare_google_sign_in_use_case.dart';
import 'package:tilawa/features/splash/domain/usecases/get_splash_next_route_use_case.dart';
import 'package:tilawa/features/splash/presentation/bloc/splash_bloc.dart';
import 'package:tilawa/features/splash/presentation/bloc/splash_event.dart';
import 'package:tilawa/features/splash/presentation/bloc/splash_state.dart';
import 'package:tilawa/router/app_router.dart';
import 'package:tilawa/router/app_router_config.dart';

import 'splash_bloc_test.mocks.dart';

@GenerateMocks([
  GetSplashNextRouteUseCase,
  PrepareGoogleSignInUseCase,
  AppStartupReadiness,
])
void main() {
  late SplashBloc bloc;
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
    when(mockReadiness.warmShellPrepInBackground()).thenReturn(null);
    when(mockReadiness.timedOut).thenReturn(false);
    when(mockReadiness.recitersDataReady).thenReturn(false);
    bloc = SplashBloc(
      mockGetSplashNextRouteUseCase,
      mockPrepareGoogleSignIn,
      mockReadiness,
    );
  });

  tearDown(() {
    bloc.close();
    AppRouter.resetForTesting();
  });

  group('SplashBloc', () {
    test('initial state is SplashLoading', () {
      expect(bloc.state, const SplashLoading());
    });

    blocTest<SplashBloc, SplashState>(
      'skips route resolution when boot launch plan already applied',
      build: () => bloc,
      act: (bloc) {
        AppRouter.applyBootLaunchPlan(
          targetLocation: const HomeRoute().location,
        );
        bloc.add(const SplashStarted());
      },
      expect: () => [const SplashNavigateToHome(timedOut: false)],
      verify: (_) {
        verifyNever(mockGetSplashNextRouteUseCase.call());
        verifyNever(
          mockReadiness.waitUntilReady(prepareShell: anyNamed('prepareShell')),
        );
      },
    );

    blocTest<SplashBloc, SplashState>(
      're-resolves route after boot plan consumed',
      build: () {
        when(
          mockGetSplashNextRouteUseCase.call(),
        ).thenAnswer(
          (_) async => const SplashRouteResult(SplashDestination.home),
        );
        return bloc;
      },
      setUp: () {
        AppRouter.applyBootLaunchPlan(
          targetLocation: const HomeRoute().location,
        );
        AppRouter.consumeBootLaunchPlan();
      },
      act: (bloc) => bloc.add(const SplashStarted()),
      expect: () => [const SplashNavigateToHome(timedOut: false)],
      verify: (_) {
        verify(mockGetSplashNextRouteUseCase.call()).called(1);
        verify(
          mockReadiness.waitUntilReady(prepareShell: true),
        ).called(1);
      },
    );

    blocTest<SplashBloc, SplashState>(
      'uses boot notification target without re-resolving route',
      build: () => bloc,
      act: (bloc) {
        AppRouter.applyBootLaunchPlan(
          targetLocation: const PrayerNotificationStatusRoute().location,
          notificationLocation: const PrayerNotificationStatusRoute().location,
          notificationExtra: '{"prayer_key":"fajr"}',
        );
        bloc.add(const SplashStarted());
      },
      expect: () => [
        isA<SplashNavigateToNotification>().having(
          (state) => state.location,
          'location',
          const PrayerNotificationStatusRoute().location,
        ),
      ],
      verify: (_) {
        verifyNever(mockGetSplashNextRouteUseCase.call());
      },
    );

    blocTest<SplashBloc, SplashState>(
      'emits notification route when pending cold start is set during splash',
      build: () {
        when(
          mockGetSplashNextRouteUseCase.call(),
        ).thenAnswer(
          (_) async => const SplashRouteResult(SplashDestination.home),
        );
        return bloc;
      },
      act: (bloc) {
        AppRouter.setPendingColdStartRoute(
          const PrayerNotificationStatusRoute().location,
          extra: '{"prayer_key":"fajr"}',
        );
        bloc.add(const SplashStarted());
      },
      expect: () => [
        isA<SplashNavigateToNotification>().having(
          (state) => state.location,
          'location',
          const PrayerNotificationStatusRoute().location,
        ),
      ],
      verify: (_) {
        verify(
          mockReadiness.waitUntilReady(prepareShell: true),
        ).called(1);
      },
    );

    blocTest<SplashBloc, SplashState>(
      'emits home and waits for shell prep',
      build: () {
        when(
          mockGetSplashNextRouteUseCase.call(),
        ).thenAnswer(
          (_) async => const SplashRouteResult(SplashDestination.home),
        );
        return bloc;
      },
      act: (bloc) => bloc.add(const SplashStarted()),
      expect: () => [const SplashNavigateToHome(timedOut: false)],
      verify: (_) {
        verify(
          mockReadiness.waitUntilReady(prepareShell: true),
        ).called(1);
      },
    );

    blocTest<SplashBloc, SplashState>(
      'emits login and warms shell prep in background',
      build: () {
        when(
          mockGetSplashNextRouteUseCase.call(),
        ).thenAnswer(
          (_) async => const SplashRouteResult(SplashDestination.login),
        );
        return bloc;
      },
      act: (bloc) => bloc.add(const SplashStarted()),
      expect: () => [const SplashNavigateToLogin()],
      verify: (_) {
        verifyNever(mockReadiness.waitUntilReady(prepareShell: true));
        verify(mockReadiness.warmShellPrepInBackground()).called(1);
        verify(mockPrepareGoogleSignIn.call()).called(1);
      },
    );

    blocTest<SplashBloc, SplashState>(
      'discards pending cold start when splash resolves to login',
      build: () {
        when(
          mockGetSplashNextRouteUseCase.call(),
        ).thenAnswer(
          (_) async => const SplashRouteResult(SplashDestination.login),
        );
        return bloc;
      },
      act: (bloc) {
        AppRouter.setPendingColdStartRoute(
          const PrayerNotificationStatusRoute().location,
          extra: '{"prayer_key":"fajr"}',
        );
        bloc.add(const SplashStarted());
      },
      expect: () => [const SplashNavigateToLogin()],
      verify: (_) {
        expect(AppRouter.pendingColdStartLocation, isNull);
        verify(mockPrepareGoogleSignIn.call()).called(1);
      },
    );

    blocTest<SplashBloc, SplashState>(
      'emits onboarding',
      build: () {
        when(mockGetSplashNextRouteUseCase.call()).thenAnswer(
          (_) async => const SplashRouteResult(SplashDestination.onboarding),
        );
        return bloc;
      },
      act: (bloc) => bloc.add(const SplashStarted()),
      expect: () => [const SplashNavigateToOnboarding()],
    );

    blocTest<SplashBloc, SplashState>(
      'emits notification route',
      build: () {
        when(mockGetSplashNextRouteUseCase.call()).thenAnswer(
          (_) async => const SplashRouteResult(
            SplashDestination.notificationLaunch,
            notificationData: {'type': 'settings'},
          ),
        );
        return bloc;
      },
      act: (bloc) => bloc.add(const SplashStarted()),
      expect: () => [
        isA<SplashNavigateToNotification>().having(
          (state) => state.location,
          'location',
          '/settings',
        ),
      ],
      verify: (_) {
        verifyNever(
          mockReadiness.waitUntilReady(prepareShell: anyNamed('prepareShell')),
        );
        verifyNever(mockReadiness.warmShellPrepInBackground());
      },
    );

    blocTest<SplashBloc, SplashState>(
      'emits notification route for reciter deep link without shell prep',
      build: () {
        when(mockGetSplashNextRouteUseCase.call()).thenAnswer(
          (_) async => const SplashRouteResult(
            SplashDestination.notificationLaunch,
            notificationData: {'type': 'reciter', 'reciterId': '42'},
          ),
        );
        return bloc;
      },
      act: (bloc) => bloc.add(const SplashStarted()),
      expect: () => [
        isA<SplashNavigateToNotification>().having(
          (state) => state.location,
          'location',
          '/reciter/42',
        ),
      ],
      verify: (_) {
        verifyNever(
          mockReadiness.waitUntilReady(prepareShell: anyNamed('prepareShell')),
        );
      },
    );

    blocTest<SplashBloc, SplashState>(
      'falls back to home when notification launch has no payload data',
      build: () {
        when(mockGetSplashNextRouteUseCase.call()).thenAnswer(
          (_) async => const SplashRouteResult(
            SplashDestination.notificationLaunch,
          ),
        );
        when(mockReadiness.timedOut).thenReturn(false);
        return bloc;
      },
      act: (bloc) => bloc.add(const SplashStarted()),
      expect: () => [const SplashNavigateToHome(timedOut: false)],
      verify: (_) {
        verifyNever(
          mockReadiness.waitUntilReady(prepareShell: anyNamed('prepareShell')),
        );
        verifyNever(mockReadiness.warmShellPrepInBackground());
      },
    );

    blocTest<SplashBloc, SplashState>(
      'emits home with timedOut when shell prep timed out on splash',
      build: () {
        when(
          mockGetSplashNextRouteUseCase.call(),
        ).thenAnswer(
          (_) async => const SplashRouteResult(SplashDestination.home),
        );
        when(mockReadiness.timedOut).thenReturn(true);
        return bloc;
      },
      act: (bloc) => bloc.add(const SplashStarted()),
      expect: () => [const SplashNavigateToHome(timedOut: true)],
      verify: (_) {
        verify(
          mockReadiness.waitUntilReady(prepareShell: true),
        ).called(1);
      },
    );

    blocTest<SplashBloc, SplashState>(
      'falls back to home when route resolution throws',
      build: () {
        when(
          mockGetSplashNextRouteUseCase.call(),
        ).thenThrow(Exception('route failure'));
        return bloc;
      },
      act: (bloc) => bloc.add(const SplashStarted()),
      expect: () => [const SplashNavigateToHome()],
      verify: (_) {
        verifyNever(
          mockReadiness.waitUntilReady(prepareShell: anyNamed('prepareShell')),
        );
      },
    );
  });
}
