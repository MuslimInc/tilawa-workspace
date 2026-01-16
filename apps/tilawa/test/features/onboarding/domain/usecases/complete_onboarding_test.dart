import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:tilawa/features/onboarding/domain/repositories/onboarding_repository.dart';
import 'package:tilawa/features/onboarding/domain/usecases/complete_onboarding.dart';

import 'complete_onboarding_test.mocks.dart';

@GenerateMocks([OnboardingRepository])
void main() {
  late CompleteOnboarding useCase;
  late MockOnboardingRepository mockRepository;

  setUp(() {
    mockRepository = MockOnboardingRepository();
    useCase = CompleteOnboarding(mockRepository);
  });

  test('should call completeOnboarding on the repository', () async {
    // Arrange
    when(mockRepository.completeOnboarding()).thenAnswer((_) async => {});

    // Act
    await useCase();

    // Assert
    verify(mockRepository.completeOnboarding()).called(1);
    verifyNoMoreInteractions(mockRepository);
  });
}
