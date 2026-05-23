import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:tilawa/features/auth/domain/usecases/prepare_google_sign_in_use_case.dart';
import 'package:tilawa/features/splash/domain/usecases/get_splash_next_route_use_case.dart';
import 'package:tilawa/features/splash/presentation/cubit/splash_cubit.dart';

import 'splash_cubit_test.mocks.dart';

@GenerateMocks([GetSplashNextRouteUseCase, PrepareGoogleSignInUseCase])
void main() {
  late SplashCubit cubit;
  late MockGetSplashNextRouteUseCase mockGetSplashNextRouteUseCase;
  late MockPrepareGoogleSignInUseCase mockPrepareGoogleSignIn;

  setUp(() {
    mockGetSplashNextRouteUseCase = MockGetSplashNextRouteUseCase();
    mockPrepareGoogleSignIn = MockPrepareGoogleSignInUseCase();
    when(mockPrepareGoogleSignIn.call()).thenAnswer((_) async {});
    cubit = SplashCubit(mockGetSplashNextRouteUseCase, mockPrepareGoogleSignIn);
  });

  tearDown(() {
    cubit.close();
  });

  group('SplashCubit', () {
    test('initial state is SplashInitial', () {
      expect(cubit.state, const SplashInitial());
    });

    blocTest<SplashCubit, SplashState>(
      'emits [SplashNavigateToHome] when destination is home',
      build: () {
        when(
          mockGetSplashNextRouteUseCase.call(),
        ).thenAnswer((_) async => SplashRouteResult(SplashDestination.home));
        return cubit;
      },
      act: (cubit) => cubit.init(),
      expect: () => [const SplashNavigateToHome()],
    );

    blocTest<SplashCubit, SplashState>(
      'emits [SplashNavigateToLogin] when destination is login',
      build: () {
        when(
          mockGetSplashNextRouteUseCase.call(),
        ).thenAnswer((_) async => SplashRouteResult(SplashDestination.login));
        return cubit;
      },
      act: (cubit) => cubit.init(),
      expect: () => [const SplashNavigateToLogin()],
      verify: (_) {
        verify(mockPrepareGoogleSignIn.call()).called(1);
      },
    );

    blocTest<SplashCubit, SplashState>(
      'emits [SplashNavigateToOnboarding] when destination is onboarding',
      build: () {
        when(mockGetSplashNextRouteUseCase.call()).thenAnswer(
          (_) async => SplashRouteResult(SplashDestination.onboarding),
        );
        return cubit;
      },
      act: (cubit) => cubit.init(),
      expect: () => [const SplashNavigateToOnboarding()],
    );

    blocTest<SplashCubit, SplashState>(
      'emits [SplashNavigateToNotification] when destination is notification launch',
      build: () {
        when(mockGetSplashNextRouteUseCase.call()).thenAnswer(
          (_) async => const SplashRouteResult(
            SplashDestination.notificationLaunch,
            notificationData: {'type': 'settings'},
          ),
        );
        return cubit;
      },
      act: (cubit) => cubit.init(),
      expect: () => [
        isA<SplashNavigateToNotification>().having(
          (state) => state.location,
          'location',
          '/settings',
        ),
      ],
    );
  });
}
