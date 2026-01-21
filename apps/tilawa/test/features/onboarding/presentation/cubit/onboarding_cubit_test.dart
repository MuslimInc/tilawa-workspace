import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:tilawa/features/onboarding/domain/usecases/complete_onboarding.dart';
import 'package:tilawa/features/onboarding/presentation/cubit/onboarding_cubit.dart';

import 'onboarding_cubit_test.mocks.dart';

@GenerateMocks([CompleteOnboarding])
void main() {
  late OnboardingCubit cubit;
  late MockCompleteOnboarding mockCompleteOnboarding;

  setUp(() {
    mockCompleteOnboarding = MockCompleteOnboarding();
    cubit = OnboardingCubit(mockCompleteOnboarding);
  });

  tearDown(() {
    cubit.close();
  });

  test('initial state should be OnboardingInitial', () {
    expect(cubit.state, equals(OnboardingInitial()));
  });

  blocTest<OnboardingCubit, OnboardingState>(
    'emits [OnboardingPageChanged] when pageChanged is called',
    build: () => cubit,
    act: (cubit) => cubit.pageChanged(1),
    expect: () => [const OnboardingPageChanged(1)],
  );

  blocTest<OnboardingCubit, OnboardingState>(
    'emits [OnboardingCompleted] when completeOnboarding is called',
    build: () {
      when(mockCompleteOnboarding()).thenAnswer((_) async => {});
      return cubit;
    },
    act: (cubit) => cubit.completeOnboarding(),
    expect: () => [OnboardingCompleted()],
    verify: (_) {
      verify(mockCompleteOnboarding()).called(1);
    },
  );
}
