import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:tilawa/features/premium/domain/repositories/premium_repository.dart';
import 'package:tilawa/features/premium/domain/usecases/check_feature_access_use_case.dart';

import 'check_feature_access_use_case_test.mocks.dart';

@GenerateMocks([PremiumRepository])
void main() {
  late CheckFeatureAccessUseCase useCase;
  late MockPremiumRepository mockRepository;

  setUp(() {
    mockRepository = MockPremiumRepository();
    useCase = CheckFeatureAccessUseCase(mockRepository);
  });

  test('should return access status from repository', () async {
    // Arrange
    const featureName = 'downloads';
    when(
      mockRepository.canAccessFeature(featureName),
    ).thenAnswer((_) async => true);

    // Act
    final bool result = await useCase(featureName);

    // Assert
    expect(result, true);
    verify(mockRepository.canAccessFeature(featureName)).called(1);
    verifyNoMoreInteractions(mockRepository);
  });
}
