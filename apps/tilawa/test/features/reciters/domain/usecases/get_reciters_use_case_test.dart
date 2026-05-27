import 'dart:async';

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

    test('returns one-shot cached success after first load', () async {
      when(
        mockRepository.getReciters(),
      ).thenAnswer((_) async => Right(tReciters));

      final first = await useCase();
      final second = await useCase();

      expect(first, Right<Failure, List<ReciterEntity>>(tReciters));
      expect(second, Right<Failure, List<ReciterEntity>>(tReciters));
      verify(mockRepository.getReciters()).called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('takeCachedSuccessForStartup consumes cached reciters', () async {
      when(
        mockRepository.getReciters(),
      ).thenAnswer((_) async => Right(tReciters));

      await useCase();

      expect(useCase.takeCachedSuccessForStartup(), tReciters);
      expect(useCase.takeCachedSuccessForStartup(), isNull);
      verify(mockRepository.getReciters()).called(1);
    });

    test('shares in-flight fetch between concurrent calls', () async {
      final completer = Completer<Either<Failure, List<ReciterEntity>>>();
      when(
        mockRepository.getReciters(),
      ).thenAnswer((_) => completer.future);

      final first = useCase();
      final second = useCase();

      completer.complete(Right(tReciters));

      expect(await first, Right<Failure, List<ReciterEntity>>(tReciters));
      expect(await second, Right<Failure, List<ReciterEntity>>(tReciters));
      verify(mockRepository.getReciters()).called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('does not cache failures', () async {
      const tFailure = ServerFailure('Failed to fetch reciters');
      when(mockRepository.getReciters()).thenAnswer(
        (_) async => const Left<Failure, List<ReciterEntity>>(tFailure),
      );

      final first = await useCase();
      final second = await useCase();

      expect(first, const Left<Failure, List<ReciterEntity>>(tFailure));
      expect(second, const Left<Failure, List<ReciterEntity>>(tFailure));
      verify(mockRepository.getReciters()).called(2);
    });
  });
}
