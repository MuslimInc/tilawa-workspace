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
    mockGetSplashNextRouteUseCase = MockGetSplashNextRouteUseCase();
    mockPrepareGoogleSignIn = MockPrepareGoogleSignInUseCase();
    mockReadiness = MockAppStartupReadiness();
    when(mockPrepareGoogleSignIn.call()).thenAnswer((_) async {});
    when(
      mockReadiness.waitUntilReady(prepareShell: anyNamed('prepareShell')),
    ).thenAnswer((_) async {});
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
  });

  group('SplashBloc', () {
    test('initial state is SplashLoading', () {
      expect(bloc.state, const SplashLoading());
    });

    blocTest<SplashBloc, SplashState>(
      'emits home and waits for shell prep',
      build: () {
        when(
          mockGetSplashNextRouteUseCase.call(),
        ).thenAnswer((_) async => SplashRouteResult(SplashDestination.home));
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
      'emits login without shell prep',
      build: () {
        when(
          mockGetSplashNextRouteUseCase.call(),
        ).thenAnswer((_) async => SplashRouteResult(SplashDestination.login));
        return bloc;
      },
      act: (bloc) => bloc.add(const SplashStarted()),
      expect: () => [const SplashNavigateToLogin()],
      verify: (_) {
        verify(
          mockReadiness.waitUntilReady(prepareShell: false),
        ).called(1);
        verify(mockPrepareGoogleSignIn.call()).called(1);
      },
    );

    blocTest<SplashBloc, SplashState>(
      'emits onboarding',
      build: () {
        when(mockGetSplashNextRouteUseCase.call()).thenAnswer(
          (_) async => SplashRouteResult(SplashDestination.onboarding),
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
        verify(
          mockReadiness.waitUntilReady(prepareShell: false),
        ).called(1);
        verifyNever(
          mockReadiness.waitUntilReady(prepareShell: true),
        );
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
        verify(
          mockReadiness.waitUntilReady(prepareShell: false),
        ).called(1);
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
        verify(
          mockReadiness.waitUntilReady(prepareShell: false),
        ).called(1);
        verifyNever(
          mockReadiness.waitUntilReady(prepareShell: true),
        );
      },
    );

    blocTest<SplashBloc, SplashState>(
      'emits home with timedOut when shell prep timed out on splash',
      build: () {
        when(
          mockGetSplashNextRouteUseCase.call(),
        ).thenAnswer((_) async => SplashRouteResult(SplashDestination.home));
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
