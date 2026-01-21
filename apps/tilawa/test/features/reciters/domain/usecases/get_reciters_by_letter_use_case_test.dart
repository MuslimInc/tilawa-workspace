import 'package:dartz_plus/dartz_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:tilawa_core/entities/reciter_entity.dart';
import 'package:tilawa_core/errors/failures.dart';
import 'package:tilawa/features/reciters/domain/repositories/reciters_repository.dart';
import 'package:tilawa/features/reciters/domain/usecases/get_reciters_by_letter_use_case.dart';

import 'get_reciters_by_letter_use_case_test.mocks.dart';

@GenerateMocks([RecitersRepository])
void main() {
  provideDummy<Either<Failure, List<ReciterEntity>>>(const Right([]));

  late GetRecitersByLetterUseCase useCase;
  late MockRecitersRepository mockRepository;

  setUp(() {
    mockRepository = MockRecitersRepository();
    useCase = GetRecitersByLetterUseCase(mockRepository);
  });

  group('GetRecitersByLetterUseCase', () {
    const tLetter = 'ع';
    final tReciters = [
      const ReciterEntity(
        id: 1,
        name: 'Abdul Rahman Al-Sudais',
        letter: 'ع',
        date: '2020-01-01',
        moshaf: [],
      ),
    ];

    test('should get reciters filtered by letter from repository', () async {
      // Arrange
      when(
        mockRepository.getRecitersByLetter(any),
      ).thenAnswer((_) async => Right(tReciters));

      // Act
      final Either<Failure, List<ReciterEntity>> result = await useCase(
        tLetter,
      );

      // Assert
      expect(result, Right<Failure, List<ReciterEntity>>(tReciters));
      verify(mockRepository.getRecitersByLetter(tLetter)).called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('should return failure when repository fails', () async {
      // Arrange
      const tFailure = ServerFailure('Failed to fetch reciters by letter');
      when(
        mockRepository.getRecitersByLetter(any),
      ).thenAnswer((_) async => const Left(tFailure));

      // Act
      final Either<Failure, List<ReciterEntity>> result = await useCase(
        tLetter,
      );

      // Assert
      expect(result, const Left<Failure, List<ReciterEntity>>(tFailure));
      verify(mockRepository.getRecitersByLetter(tLetter)).called(1);
      verifyNoMoreInteractions(mockRepository);
    });
  });
}
