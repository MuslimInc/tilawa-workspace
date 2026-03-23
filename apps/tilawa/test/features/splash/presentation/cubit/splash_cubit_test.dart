import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:tilawa/features/splash/domain/usecases/get_splash_next_route_use_case.dart';
import 'package:tilawa/features/splash/presentation/cubit/splash_cubit.dart';
import 'package:tilawa_core/services/interfaces/notification_dispatcher_interface.dart';

import 'splash_cubit_test.mocks.dart';

@GenerateMocks([GetSplashNextRouteUseCase, INotificationDispatcher])
void main() {
  late SplashCubit cubit;
  late MockGetSplashNextRouteUseCase mockGetSplashNextRouteUseCase;
  late MockINotificationDispatcher mockDispatcher;

  setUp(() {
    mockGetSplashNextRouteUseCase = MockGetSplashNextRouteUseCase();
    mockDispatcher = MockINotificationDispatcher();
    cubit = SplashCubit(mockGetSplashNextRouteUseCase, mockDispatcher);
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
        ).thenAnswer((_) async => SplashDestination.home);
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
        ).thenAnswer((_) async => SplashDestination.login);
        return cubit;
      },
      act: (cubit) => cubit.init(),
      expect: () => [const SplashNavigateToLogin()],
    );

    blocTest<SplashCubit, SplashState>(
      'emits [SplashNavigateToOnboarding] when destination is onboarding',
      build: () {
        when(
          mockGetSplashNextRouteUseCase.call(),
        ).thenAnswer((_) async => SplashDestination.onboarding);
        return cubit;
      },
      act: (cubit) => cubit.init(),
      expect: () => [const SplashNavigateToOnboarding()],
    );
  });
}
