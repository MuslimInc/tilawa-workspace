import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:tilawa/features/onboarding/domain/repositories/onboarding_repository.dart';
import 'package:tilawa/features/onboarding/domain/usecases/check_onboarding_status.dart';

import 'check_onboarding_status_test.mocks.dart';

@GenerateMocks([OnboardingRepository])
void main() {
  late CheckOnboardingStatus useCase;
  late MockOnboardingRepository mockRepository;

  setUp(() {
    mockRepository = MockOnboardingRepository();
    useCase = CheckOnboardingStatus(mockRepository);
  });

  test('should return onboarding status from repository', () async {
    // Arrange
    when(mockRepository.isOnboardingCompleted()).thenAnswer((_) async => true);

    // Act
    final bool result = await useCase();

    // Assert
    expect(result, true);
    verify(mockRepository.isOnboardingCompleted()).called(1);
    verifyNoMoreInteractions(mockRepository);
  });
}
