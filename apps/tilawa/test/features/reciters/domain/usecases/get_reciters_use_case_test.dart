import 'package:dartz_plus/dartz_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:tilawa_core/entities/reciter_entity.dart';
import 'package:tilawa_core/errors/failures.dart';
import 'package:tilawa/features/reciters/domain/repositories/reciters_repository.dart';
import 'package:tilawa/features/reciters/domain/usecases/get_reciters_use_case.dart';

import 'get_reciters_use_case_test.mocks.dart';

@GenerateMocks([RecitersRepository])
void main() {
  provideDummy<Either<Failure, List<ReciterEntity>>>(const Right([]));

  late GetRecitersUseCase useCase;
  late MockRecitersRepository mockRepository;

  setUp(() {
    mockRepository = MockRecitersRepository();
    useCase = GetRecitersUseCase(mockRepository);
  });

  group('GetRecitersUseCase', () {
    final tReciters = [
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

    test('should get list of reciters from repository', () async {
      // Arrange
      when(
        mockRepository.getReciters(),
      ).thenAnswer((_) async => Right(tReciters));

      // Act
      final Either<Failure, List<ReciterEntity>> result = await useCase();

      // Assert
      expect(result, Right<Failure, List<ReciterEntity>>(tReciters));
      verify(mockRepository.getReciters()).called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('should return failure when repository fails', () async {
      // Arrange
      const tFailure = ServerFailure('Failed to fetch reciters');
      when(
        mockRepository.getReciters(),
      ).thenAnswer((_) async => const Left(tFailure));

      // Act
      final Either<Failure, List<ReciterEntity>> result = await useCase();

      // Assert
      expect(result, const Left<Failure, List<ReciterEntity>>(tFailure));
      verify(mockRepository.getReciters()).called(1);
      verifyNoMoreInteractions(mockRepository);
    });
  });
}
