import 'package:dartz_plus/dartz_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:tilawa/core/errors/failures.dart';
import 'package:tilawa/features/reciters/domain/repositories/reciters_repository.dart';
import 'package:tilawa/features/reciters/domain/usecases/toggle_favorite_reciter_use_case.dart';

import 'toggle_favorite_reciter_use_case_test.mocks.dart';

@GenerateMocks([RecitersRepository])
void main() {
  provideDummy<Either<Failure, void>>(const Right(null));

  late ToggleFavoriteReciterUseCase useCase;
  late MockRecitersRepository mockRepository;

  setUp(() {
    mockRepository = MockRecitersRepository();
    useCase = ToggleFavoriteReciterUseCase(mockRepository);
  });

  group('ToggleFavoriteReciterUseCase', () {
    const tReciterId = 1;

    test('should toggle favorite status for reciter', () async {
      // Arrange
      when(
        mockRepository.toggleFavoriteReciter(any),
      ).thenAnswer((_) async => const Right(null));

      // Act
      final Either<Failure, void> result = await useCase(tReciterId);

      // Assert
      expect(result, const Right<Failure, void>(null));
      verify(mockRepository.toggleFavoriteReciter(tReciterId)).called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('should return failure when repository fails', () async {
      // Arrange
      const tFailure = CacheFailure('Failed to toggle favorite');
      when(
        mockRepository.toggleFavoriteReciter(any),
      ).thenAnswer((_) async => const Left(tFailure));

      // Act
      final Either<Failure, void> result = await useCase(tReciterId);

      // Assert
      expect(result, const Left<Failure, void>(tFailure));
      verify(mockRepository.toggleFavoriteReciter(tReciterId)).called(1);
      verifyNoMoreInteractions(mockRepository);
    });
  });
}
