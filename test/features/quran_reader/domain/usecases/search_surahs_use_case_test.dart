import 'package:dartz_plus/dartz_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tilawa/core/errors/failures.dart';
import 'package:tilawa/features/quran_reader/domain/entities/entities.dart';
import 'package:tilawa/features/quran_reader/domain/repositories/quran_reader_repository.dart';
import 'package:tilawa/features/quran_reader/domain/usecases/search_surahs_use_case.dart';

class MockQuranReaderRepository extends Mock implements QuranReaderRepository {}

void main() {
  late MockQuranReaderRepository mockRepository;
  late SearchSurahsUseCase useCase;

  setUp(() {
    mockRepository = MockQuranReaderRepository();
    useCase = SearchSurahsUseCase(mockRepository);
  });

  group('SearchSurahsUseCase', () {
    const tQuery = 'Al-Fatiha';
    final tSurahResults = [
      const SurahContentEntity(
        number: 1,
        name: 'Al-Fatiha',
        nameEnglish: 'The Opening',
        nameTranslation: 'The Opening',
        revelationType: 'Meccan',
        numberOfAyahs: 7,
        ayahs: [],
      ),
    ];

    test('should return list of surahs from repository', () async {
      // Arrange
      when(
        () => mockRepository.searchSurahs(any()),
      ).thenAnswer((_) async => tSurahResults);

      // Act
      final Either<Failure, List<SurahContentEntity>> result = await useCase(
        query: tQuery,
      );

      // Assert
      expect(result.isRight, isTrue);
      result.fold(
        (failure) => fail('Should not return failure'),
        (data) => expect(data, tSurahResults),
      );
      verify(() => mockRepository.searchSurahs(tQuery)).called(1);
    });

    test('should return empty list when query is empty', () async {
      // Act
      final Either<Failure, List<SurahContentEntity>> result = await useCase(
        query: '',
      );

      // Assert
      expect(result.isRight, isTrue);
      result.fold(
        (failure) => fail('Should not return failure'),
        (data) => expect(data, isEmpty),
      );
      verifyNever(() => mockRepository.searchSurahs(any()));
    });
  });
}
