import 'package:dartz_plus/dartz_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:tilawa/core/errors/failures.dart';
import 'package:tilawa/features/localization/domain/repositories/localization_repository.dart';
import 'package:tilawa/features/localization/domain/usecases/set_language_use_case.dart';

import 'set_language_use_case_test.mocks.dart';

@GenerateMocks([LocalizationRepository])
void main() {
  provideDummy<Either<Failure, void>>(const Right(null));

  late SetLanguageUseCase useCase;
  late MockLocalizationRepository mockRepository;

  setUp(() {
    mockRepository = MockLocalizationRepository();
    useCase = SetLanguageUseCase(mockRepository);
  });

  group('SetLanguageUseCase', () {
    const tLanguageCode = 'ar';

    test('should set language through repository', () async {
      // Arrange
      when(
        mockRepository.setLanguage(any),
      ).thenAnswer((_) async => const Right(null));

      // Act
      final Either<Failure, void> result = await useCase(tLanguageCode);

      // Assert
      expect(result, const Right(null));
      verify(mockRepository.setLanguage(tLanguageCode)).called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('should return failure when repository fails', () async {
      // Arrange
      const tFailure = CacheFailure('Failed to set language');
      when(
        mockRepository.setLanguage(any),
      ).thenAnswer((_) async => const Left(tFailure));

      // Act
      final Either<Failure, void> result = await useCase(tLanguageCode);

      // Assert
      expect(result, const Left(tFailure));
      verify(mockRepository.setLanguage(tLanguageCode)).called(1);
      verifyNoMoreInteractions(mockRepository);
    });
  });
}
