import 'package:dartz_plus/dartz_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:tilawa/core/entities/reciter_entity.dart';
import 'package:tilawa/core/errors/failures.dart';
import 'package:tilawa/features/reciters/domain/repositories/reciters_repository.dart';
import 'package:tilawa/features/reciters/domain/usecases/search_reciters_use_case.dart';

import 'search_reciters_use_case_test.mocks.dart';

@GenerateMocks([RecitersRepository])
void main() {
  provideDummy<Either<Failure, List<ReciterEntity>>>(const Right([]));

  late SearchRecitersUseCase useCase;
  late MockRecitersRepository mockRepository;

  setUp(() {
    mockRepository = MockRecitersRepository();
    useCase = SearchRecitersUseCase(mockRepository);
  });

  group('SearchRecitersUseCase', () {
    const tQuery = 'Sudais';
    final tReciters = [
      const ReciterEntity(
        id: 1,
        name: 'Abdul Rahman Al-Sudais',
        letter: 'ع',
        date: '2020-01-01',
        moshaf: [],
      ),
    ];

    test('should return empty list when query is empty', () async {
      // Act
      final Either<Failure, List<ReciterEntity>> result = await useCase('');

      // Assert
      expect(result, const Right<Failure, List<ReciterEntity>>([]));
      verifyZeroInteractions(mockRepository);
    });

    test('should search reciters with query from repository', () async {
      // Arrange
      when(
        mockRepository.searchReciters(any),
      ).thenAnswer((_) async => Right(tReciters));

      // Act
      final Either<Failure, List<ReciterEntity>> result = await useCase(tQuery);

      // Assert
      expect(result, Right<Failure, List<ReciterEntity>>(tReciters));
      verify(mockRepository.searchReciters(tQuery)).called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('should return empty list when no reciters match', () async {
      // Arrange
      when(
        mockRepository.searchReciters(any),
      ).thenAnswer((_) async => const Right([]));

      // Act
      final Either<Failure, List<ReciterEntity>> result = await useCase(tQuery);

      // Assert
      expect(result, const Right<Failure, List<ReciterEntity>>([]));
      verify(mockRepository.searchReciters(tQuery)).called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('should return failure when repository fails', () async {
      // Arrange
      const tFailure = ServerFailure('Failed to search reciters');
      when(
        mockRepository.searchReciters(any),
      ).thenAnswer((_) async => const Left(tFailure));

      // Act
      final Either<Failure, List<ReciterEntity>> result = await useCase(tQuery);

      // Assert
      expect(result, const Left<Failure, List<ReciterEntity>>(tFailure));
      verify(mockRepository.searchReciters(tQuery)).called(1);
      verifyNoMoreInteractions(mockRepository);
    });
  });
}
