import 'package:dartz_plus/dartz_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:tilawa_core/entities/reciter_entity.dart';
import 'package:tilawa_core/errors/failures.dart';
import 'package:tilawa/features/reciters/domain/repositories/reciters_repository.dart';
import 'package:tilawa/features/reciters/domain/usecases/get_reciters_use_case.dart';
import 'package:tilawa/features/reciters/domain/usecases/search_reciters_use_case.dart';

import 'search_reciters_use_case_test.mocks.dart';

@GenerateMocks([RecitersRepository])
void main() {
  provideDummy<Either<Failure, List<ReciterEntity>>>(const Right([]));

  late SearchRecitersUseCase useCase;
  late GetRecitersUseCase getReciters;
  late MockRecitersRepository mockRepository;

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
      date: '2020-01-02',
      moshaf: [],
    ),
  ];

  setUp(() {
    mockRepository = MockRecitersRepository();
    getReciters = GetRecitersUseCase(mockRepository);
    useCase = SearchRecitersUseCase(getReciters);
  });

  group('SearchRecitersUseCase', () {
    test('should return empty list when query is empty', () async {
      final Either<Failure, List<ReciterEntity>> result = await useCase('');

      expect(result, const Right<Failure, List<ReciterEntity>>([]));
      verifyZeroInteractions(mockRepository);
    });

    test('should search reciters by normalized name substring', () async {
      when(
        mockRepository.getReciters(),
      ).thenAnswer((_) async => Right(tReciters));

      final Either<Failure, List<ReciterEntity>> result =
          await useCase('Sudais');

      expect(result, Right<Failure, List<ReciterEntity>>([tReciters.first]));
      verify(mockRepository.getReciters()).called(1);
    });

    test('should return empty list when no reciters match', () async {
      when(
        mockRepository.getReciters(),
      ).thenAnswer((_) async => Right(tReciters));

      final Either<Failure, List<ReciterEntity>> result =
          await useCase('zzznomatch');

      expect(result, const Right<Failure, List<ReciterEntity>>([]));
      verify(mockRepository.getReciters()).called(1);
    });

    test('should return failure when getReciters fails', () async {
      const tFailure = ServerFailure('Failed to load reciters');
      when(
        mockRepository.getReciters(),
      ).thenAnswer((_) async => const Left(tFailure));

      final Either<Failure, List<ReciterEntity>> result =
          await useCase('Sudais');

      expect(result, const Left<Failure, List<ReciterEntity>>(tFailure));
      verify(mockRepository.getReciters()).called(1);
    });
  });
}
