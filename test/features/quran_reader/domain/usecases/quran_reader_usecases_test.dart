import 'package:dartz_plus/dartz_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tilawa/core/errors/failures.dart';
import 'package:tilawa/features/quran_reader/domain/entities/entities.dart';
import 'package:tilawa/features/quran_reader/domain/repositories/quran_reader_repository.dart';
import 'package:tilawa/features/quran_reader/domain/usecases/usecases.dart';

class MockQuranReaderRepository extends Mock implements QuranReaderRepository {}

void main() {
  late MockQuranReaderRepository mockRepository;

  setUpAll(() {
    registerFallbackValue(const ReaderSettingsEntity());
  });

  setUp(() {
    mockRepository = MockQuranReaderRepository();
  });

  group('GetQuranPageUseCase', () {
    const tPage = QuranPageEntity(pageNumber: 1, ayahs: [], juz: 1, hizb: 1);

    test('should get page from repository', () async {
      final useCase = GetQuranPageUseCase(mockRepository);
      when(() => mockRepository.getPage(any())).thenAnswer((_) async => tPage);

      final Either<Failure, QuranPageEntity> result = await useCase(
        pageNumber: 1,
      );

      expect(result.isRight, isTrue);
      result.fold((l) => fail('Should be right'), (r) => expect(r, tPage));
      verify(() => mockRepository.getPage(1)).called(1);
    });

    test('should return validation failure for invalid page (0)', () async {
      final useCase = GetQuranPageUseCase(mockRepository);
      final Either<Failure, QuranPageEntity> result = await useCase(
        pageNumber: 0,
      );
      expect(result.isLeft, isTrue);
      result.fold(
        (l) => expect(l, isA<ValidationFailure>()),
        (r) => fail('Should be left'),
      );
    });

    test('should return failure when repository throws', () async {
      final useCase = GetQuranPageUseCase(mockRepository);
      when(() => mockRepository.getPage(any())).thenThrow(Exception('error'));

      final Either<Failure, QuranPageEntity> result = await useCase(
        pageNumber: 1,
      );

      expect(result.isLeft, isTrue);
    });
  });

  group('GetSurahContentUseCase', () {
    const tSurah = SurahContentEntity(
      number: 1,
      name: 'test',
      nameEnglish: 'test',
      nameTranslation: 'test',
      revelationType: 'test',
      numberOfAyahs: 1,
      ayahs: [],
    );

    test('should get surah content from repository', () async {
      final useCase = GetSurahContentUseCase(mockRepository);
      when(
        () => mockRepository.getSurahContent(any()),
      ).thenAnswer((_) async => tSurah);

      final Either<Failure, SurahContentEntity> result = await useCase(
        surahNumber: 1,
      );

      expect(result.isRight, isTrue);
      result.fold((l) => fail('Should be right'), (r) => expect(r, tSurah));
      verify(() => mockRepository.getSurahContent(1)).called(1);
    });

    test('should return failure when repository throws', () async {
      final useCase = GetSurahContentUseCase(mockRepository);
      when(
        () => mockRepository.getSurahContent(any()),
      ).thenThrow(Exception('error'));

      final Either<Failure, SurahContentEntity> result = await useCase(
        surahNumber: 1,
      );

      expect(result.isLeft, isTrue);
    });
  });

  group('LoadReaderSettingsUseCase', () {
    test('should load settings from repository', () async {
      const tSettings = ReaderSettingsEntity();
      final useCase = LoadReaderSettingsUseCase(mockRepository);
      when(
        () => mockRepository.loadSettings(),
      ).thenAnswer((_) async => tSettings);

      final Either<Failure, ReaderSettingsEntity> result = await useCase();

      expect(result.isRight, isTrue);
      result.fold((l) => fail('Should be right'), (r) => expect(r, tSettings));
      verify(() => mockRepository.loadSettings()).called(1);
    });

    test('should return failure when repository throws', () async {
      final useCase = LoadReaderSettingsUseCase(mockRepository);
      when(() => mockRepository.loadSettings()).thenThrow(Exception('error'));

      final Either<Failure, ReaderSettingsEntity> result = await useCase();

      expect(result.isLeft, isTrue);
    });
  });

  group('SaveReaderSettingsUseCase', () {
    test('should save settings in repository', () async {
      const tSettings = ReaderSettingsEntity();
      final useCase = SaveReaderSettingsUseCase(mockRepository);
      when(() => mockRepository.saveSettings(any())).thenAnswer((_) async {});

      final Either<Failure, void> result = await useCase(settings: tSettings);

      expect(result.isRight, isTrue);
      verify(() => mockRepository.saveSettings(tSettings)).called(1);
    });

    test('should return failure when repository throws', () async {
      const tSettings = ReaderSettingsEntity();
      final useCase = SaveReaderSettingsUseCase(mockRepository);
      when(
        () => mockRepository.saveSettings(any()),
      ).thenThrow(Exception('error'));

      final Either<Failure, void> result = await useCase(settings: tSettings);

      expect(result.isLeft, isTrue);
    });
  });

  group('SaveLastReadPositionUseCase', () {
    test('should save position in repository', () async {
      final useCase = SaveLastReadPositionUseCase(mockRepository);
      when(
        () => mockRepository.saveLastReadPosition(
          surahNumber: any(named: 'surahNumber'),
          ayahNumber: any(named: 'ayahNumber'),
          page: any(named: 'page'),
        ),
      ).thenAnswer((_) async {});

      final Either<Failure, void> result = await useCase(
        surahNumber: 1,
        ayahNumber: 1,
        page: 1,
      );

      expect(result.isRight, isTrue);
      verify(
        () => mockRepository.saveLastReadPosition(
          surahNumber: 1,
          ayahNumber: 1,
          page: 1,
        ),
      ).called(1);
    });

    test('should return failure when repository throws', () async {
      final useCase = SaveLastReadPositionUseCase(mockRepository);
      when(
        () => mockRepository.saveLastReadPosition(
          surahNumber: any(named: 'surahNumber'),
          ayahNumber: any(named: 'ayahNumber'),
          page: any(named: 'page'),
        ),
      ).thenThrow(Exception('error'));

      final Either<Failure, void> result = await useCase(
        surahNumber: 1,
        ayahNumber: 1,
        page: 1,
      );

      expect(result.isLeft, isTrue);
    });
  });

  group('SearchAyahsUseCase', () {
    const tAyahs = [
      AyahEntity(
        number: 1,
        numberInSurah: 1,
        surahNumber: 1,
        text: 'text',
        page: 1,
      ),
    ];

    test('should search ayahs in repository', () async {
      final useCase = SearchAyahsUseCase(mockRepository);
      when(
        () => mockRepository.searchAyahs(any()),
      ).thenAnswer((_) async => tAyahs);

      final Either<Failure, List<AyahEntity>> result = await useCase(
        query: 'test',
      );

      expect(result.isRight, isTrue);
      result.fold((l) => fail('Should be right'), (r) => expect(r, tAyahs));
      verify(() => mockRepository.searchAyahs('test')).called(1);
    });

    test('should return failure when repository throws', () async {
      final useCase = SearchAyahsUseCase(mockRepository);
      when(
        () => mockRepository.searchAyahs(any()),
      ).thenThrow(Exception('error'));

      final Either<Failure, List<AyahEntity>> result = await useCase(
        query: 'test',
      );

      expect(result.isLeft, isTrue);
    });

    test('should return empty list for empty query', () async {
      final useCase = SearchAyahsUseCase(mockRepository);
      final Either<Failure, List<AyahEntity>> result = await useCase(query: '');
      expect(result.isRight, isTrue);
      result.fold((l) => fail('Should be right'), (r) => expect(r, isEmpty));
    });
  });

  group('SearchSurahsUseCase', () {
    const tSurahs = [
      SurahContentEntity(
        number: 1,
        name: 'test',
        nameEnglish: 'test',
        nameTranslation: 'test',
        revelationType: 'test',
        numberOfAyahs: 1,
        ayahs: [],
      ),
    ];

    test('should search surahs in repository', () async {
      final useCase = SearchSurahsUseCase(mockRepository);
      when(
        () => mockRepository.searchSurahs(any()),
      ).thenAnswer((_) async => tSurahs);

      final Either<Failure, List<SurahContentEntity>> result = await useCase(
        query: 'test',
      );

      expect(result.isRight, isTrue);
      result.fold((l) => fail('Should be right'), (r) => expect(r, tSurahs));
      verify(() => mockRepository.searchSurahs('test')).called(1);
    });

    test('should return failure when repository throws', () async {
      final useCase = SearchSurahsUseCase(mockRepository);
      when(
        () => mockRepository.searchSurahs(any()),
      ).thenThrow(Exception('error'));

      final Either<Failure, List<SurahContentEntity>> result = await useCase(
        query: 'test',
      );

      expect(result.isLeft, isTrue);
    });

    test('should return empty list for empty query', () async {
      final useCase = SearchSurahsUseCase(mockRepository);
      final Either<Failure, List<SurahContentEntity>> result = await useCase(
        query: '',
      );
      expect(result.isRight, isTrue);
      result.fold((l) => fail('Should be right'), (r) => expect(r, isEmpty));
    });
  });
}
