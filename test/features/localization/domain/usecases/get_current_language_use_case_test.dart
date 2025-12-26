import 'package:dartz_plus/dartz_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:tilawa/core/errors/failures.dart';
import 'package:tilawa/features/localization/domain/repositories/localization_repository.dart';
import 'package:tilawa/features/localization/domain/usecases/get_current_language_use_case.dart';

import 'get_current_language_use_case_test.mocks.dart';

@GenerateMocks([LocalizationRepository])
void main() {
  provideDummy<Either<Failure, String>>(const Right(''));

  late GetCurrentLanguageUseCase useCase;
  late MockLocalizationRepository mockRepository;

  setUp(() {
    mockRepository = MockLocalizationRepository();
    useCase = GetCurrentLanguageUseCase(mockRepository);
  });

  group('GetCurrentLanguageUseCase', () {
    const tLanguageCode = 'en';

    test('should get current language from repository', () async {
      // Arrange
      when(
        mockRepository.getCurrentLanguage(),
      ).thenAnswer((_) async => const Right(tLanguageCode));

      // Act
      final Either<Failure, String> result = await useCase();

      // Assert
      expect(result, const Right(tLanguageCode));
      verify(mockRepository.getCurrentLanguage()).called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('should return failure when repository fails', () async {
      // Arrange
      const tFailure = CacheFailure('Failed to get language');
      when(
        mockRepository.getCurrentLanguage(),
      ).thenAnswer((_) async => const Left(tFailure));

      // Act
      final Either<Failure, String> result = await useCase();

      // Assert
      expect(result, const Left(tFailure));
      verify(mockRepository.getCurrentLanguage()).called(1);
      verifyNoMoreInteractions(mockRepository);
    });
  });
}
