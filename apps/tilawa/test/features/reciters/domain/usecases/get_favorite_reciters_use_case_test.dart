import 'package:dartz_plus/dartz_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:tilawa_core/entities/reciter_entity.dart';
import 'package:tilawa_core/errors/failures.dart';
import 'package:tilawa_core/usecases/usecase.dart';
import 'package:tilawa/features/reciters/domain/repositories/reciters_repository.dart';
import 'package:tilawa/features/reciters/domain/usecases/get_favorite_reciters_use_case.dart';

import 'get_favorite_reciters_use_case_test.mocks.dart';

@GenerateMocks([RecitersRepository])
void main() {
  provideDummy<Either<Failure, List<ReciterEntity>>>(const Right([]));

  late GetFavoriteRecitersUseCase useCase;
  late MockRecitersRepository mockRepository;

  setUp(() {
    mockRepository = MockRecitersRepository();
    useCase = GetFavoriteRecitersUseCase(mockRepository);
  });

  group('GetFavoriteRecitersUseCase', () {
    final tFavoriteReciters = [
      const ReciterEntity(
        id: 1,
        name: 'Abdul Rahman Al-Sudais',
        letter: 'ع',
        date: '2020-01-01',
        moshaf: [],
      ),
      const ReciterEntity(
        id: 2,
        name: 'Mishary Rashid Alafasy',
        letter: 'م',
        date: '2020-01-01',
        moshaf: [],
      ),
    ];

    test('should get favorite reciters from repository', () async {
      // Arrange
      when(
        mockRepository.getFavoriteReciters(),
      ).thenAnswer((_) async => Right(tFavoriteReciters));

      // Act
      final Either<Failure, List<ReciterEntity>> result = await useCase(
        const NoParams(),
      );

      // Assert
      expect(result, Right<Failure, List<ReciterEntity>>(tFavoriteReciters));
      verify(mockRepository.getFavoriteReciters()).called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('should return empty list when no favorites exist', () async {
      // Arrange
      when(
        mockRepository.getFavoriteReciters(),
      ).thenAnswer((_) async => const Right([]));

      // Act
      final Either<Failure, List<ReciterEntity>> result = await useCase(
        const NoParams(),
      );

      // Assert
      expect(result, const Right<Failure, List<ReciterEntity>>([]));
      verify(mockRepository.getFavoriteReciters()).called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('should return failure when repository fails', () async {
      // Arrange
      const tFailure = CacheFailure('Failed to fetch favorite reciters');
      when(
        mockRepository.getFavoriteReciters(),
      ).thenAnswer((_) async => const Left(tFailure));

      // Act
      final Either<Failure, List<ReciterEntity>> result = await useCase(
        const NoParams(),
      );

      // Assert
      expect(result, const Left<Failure, List<ReciterEntity>>(tFailure));
      verify(mockRepository.getFavoriteReciters()).called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('takeCachedSuccessForStartup consumes cached favorites', () async {
      when(
        mockRepository.getFavoriteReciters(),
      ).thenAnswer((_) async => Right(tFavoriteReciters));

      await useCase(const NoParams());

      expect(useCase.takeCachedSuccessForStartup(), tFavoriteReciters);
      expect(useCase.takeCachedSuccessForStartup(), isNull);
      verify(mockRepository.getFavoriteReciters()).called(1);
    });

    test('returns one-shot cached success after first load', () async {
      when(
        mockRepository.getFavoriteReciters(),
      ).thenAnswer((_) async => Right(tFavoriteReciters));

      final first = await useCase(const NoParams());
      final second = await useCase(const NoParams());

      expect(first, Right<Failure, List<ReciterEntity>>(tFavoriteReciters));
      expect(second, Right<Failure, List<ReciterEntity>>(tFavoriteReciters));
      verify(mockRepository.getFavoriteReciters()).called(1);
    });

    test('does not cache failures', () async {
      const tFailure = CacheFailure('Failed');
      when(mockRepository.getFavoriteReciters()).thenAnswer(
        (_) async => const Left<Failure, List<ReciterEntity>>(tFailure),
      );

      await useCase(const NoParams());
      await useCase(const NoParams());

      expect(useCase.takeCachedSuccessForStartup(), isNull);
      verify(mockRepository.getFavoriteReciters()).called(2);
    });
  });
}
