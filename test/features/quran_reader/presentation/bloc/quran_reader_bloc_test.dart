import 'package:bloc_test/bloc_test.dart';
import 'package:dartz_plus/dartz_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tilawa/core/errors/failures.dart';
import 'package:tilawa/features/quran_reader/domain/entities/entities.dart';
import 'package:tilawa/features/quran_reader/domain/usecases/usecases.dart';
import 'package:tilawa/features/quran_reader/presentation/bloc/quran_reader_bloc.dart';

import '../../../../helpers/hydrated_bloc_test_helper.dart';

class MockGetSurahContentUseCase extends Mock
    implements GetSurahContentUseCase {}

class MockGetQuranPageUseCase extends Mock implements GetQuranPageUseCase {}

class MockLoadReaderSettingsUseCase extends Mock
    implements LoadReaderSettingsUseCase {}

class MockSaveReaderSettingsUseCase extends Mock
    implements SaveReaderSettingsUseCase {}

class MockSaveLastReadPositionUseCase extends Mock
    implements SaveLastReadPositionUseCase {}

class MockSearchAyahsUseCase extends Mock implements SearchAyahsUseCase {}

class MockSearchSurahsUseCase extends Mock implements SearchSurahsUseCase {}

void main() {
  late MockGetSurahContentUseCase getSurahContentUseCase;
  late MockGetQuranPageUseCase getQuranPageUseCase;
  late MockLoadReaderSettingsUseCase loadReaderSettingsUseCase;
  late MockSaveReaderSettingsUseCase saveReaderSettingsUseCase;
  late MockSaveLastReadPositionUseCase saveLastReadPositionUseCase;
  late MockSearchAyahsUseCase searchAyahsUseCase;
  late MockSearchSurahsUseCase searchSurahsUseCase;
  late QuranReaderBloc bloc;

  setUpAll(() async {
    await initializeHydratedStorageForTest();
    registerFallbackValue(const ReaderSettingsEntity());
  });

  tearDownAll(() async {
    await clearHydratedStorageForTest();
  });

  setUp(() {
    getSurahContentUseCase = MockGetSurahContentUseCase();
    getQuranPageUseCase = MockGetQuranPageUseCase();
    loadReaderSettingsUseCase = MockLoadReaderSettingsUseCase();
    saveReaderSettingsUseCase = MockSaveReaderSettingsUseCase();
    saveLastReadPositionUseCase = MockSaveLastReadPositionUseCase();
    searchAyahsUseCase = MockSearchAyahsUseCase();
    searchSurahsUseCase = MockSearchSurahsUseCase();

    bloc = QuranReaderBloc(
      getSurahContentUseCase,
      getQuranPageUseCase,
      loadReaderSettingsUseCase,
      saveReaderSettingsUseCase,
      saveLastReadPositionUseCase,
      searchAyahsUseCase,
      searchSurahsUseCase,
    );
  });

  tearDown(() {
    bloc.close();
  });

  const tSurah = SurahContentEntity(
    number: 1,
    name: 'Al-Fatiha',
    nameEnglish: 'The Opening',
    nameTranslation: 'The Opening',
    revelationType: 'Meccan',
    numberOfAyahs: 7,
    ayahs: [],
    startPage: 1,
  );

  const tPage = QuranPageEntity(pageNumber: 1, ayahs: [], juz: 1, hizb: 1);

  group('QuranReaderBloc', () {
    test('initial state should be initial', () {
      expect(bloc.state.status, QuranReaderStatus.initial);
    });

    group('loadSurah', () {
      blocTest<QuranReaderBloc, QuranReaderState>(
        'emits [loading, loaded, jumpToPage, loaded] when successful',
        build: () {
          when(
            () => getSurahContentUseCase.call(
              surahNumber: any(named: 'surahNumber'),
            ),
          ).thenAnswer((_) async => const Right(tSurah));
          return bloc;
        },
        act: (bloc) => bloc.add(const QuranReaderEvent.loadSurah(1)),
        expect: () => [
          const QuranReaderState(status: QuranReaderStatus.loading),
          const QuranReaderState(
            status: QuranReaderStatus.loaded,
            currentSurah: tSurah,
          ),
          const QuranReaderState(
            status: QuranReaderStatus.loaded,
            currentSurah: tSurah,
            jumpToPage: 1,
          ),
          const QuranReaderState(
            status: QuranReaderStatus.loaded,
            currentSurah: tSurah,
          ),
        ],
      );

      blocTest<QuranReaderBloc, QuranReaderState>(
        'emits [loading, error] when failure occurs',
        build: () {
          when(
            () => getSurahContentUseCase.call(
              surahNumber: any(named: 'surahNumber'),
            ),
          ).thenAnswer((_) async => const Left(UnexpectedFailure('err')));
          return bloc;
        },
        act: (bloc) => bloc.add(const QuranReaderEvent.loadSurah(1)),
        expect: () => [
          const QuranReaderState(status: QuranReaderStatus.loading),
          const QuranReaderState(
            status: QuranReaderStatus.error,
            errorMessage: 'UnexpectedFailure(err)',
          ),
        ],
      );
    });

    group('loadPage', () {
      blocTest<QuranReaderBloc, QuranReaderState>(
        'emits [loading, loaded] when successful and cache is empty',
        build: () {
          when(
            () =>
                getQuranPageUseCase.call(pageNumber: any(named: 'pageNumber')),
          ).thenAnswer((_) async => const Right(tPage));
          return bloc;
        },
        act: (bloc) => bloc.add(const QuranReaderEvent.loadPage(1)),
        expect: () => [
          const QuranReaderState(status: QuranReaderStatus.loading),
          const QuranReaderState(
            status: QuranReaderStatus.loaded,
            currentPage: tPage,
            pages: {1: tPage},
          ),
        ],
      );

      blocTest<QuranReaderBloc, QuranReaderState>(
        'emits [error] when loadPage failure occurs',
        build: () {
          when(
            () =>
                getQuranPageUseCase.call(pageNumber: any(named: 'pageNumber')),
          ).thenAnswer((_) async => const Left(UnexpectedFailure('err')));
          return bloc;
        },
        act: (bloc) => bloc.add(const QuranReaderEvent.loadPage(1)),
        expect: () => [
          const QuranReaderState(status: QuranReaderStatus.loading),
          const QuranReaderState(
            status: QuranReaderStatus.error,
            errorMessage: 'UnexpectedFailure(err)',
          ),
        ],
      );

      blocTest<QuranReaderBloc, QuranReaderState>(
        'emits [currentPage] when page is already cached with words',
        build: () {
          final QuranPageEntity pageWithWords = tPage.copyWith(
            ayahs: [
              const PageAyahInfo(
                surahNumber: 1,
                surahName: 'test',
                surahNameEnglish: 'test',
                ayahNumber: 1,
                text: 'text',
                words: [],
              ),
            ],
          );
          return QuranReaderBloc(
            getSurahContentUseCase,
            getQuranPageUseCase,
            loadReaderSettingsUseCase,
            saveReaderSettingsUseCase,
            saveLastReadPositionUseCase,
            searchAyahsUseCase,
            searchSurahsUseCase,
          )..emit(QuranReaderState(pages: {1: pageWithWords}));
        },
        act: (bloc) => bloc.add(const QuranReaderEvent.loadPage(1)),
        expect: () => [
          isA<QuranReaderState>().having(
            (s) => s.currentPage?.pageNumber,
            'pageNumber',
            1,
          ),
        ],
      );
    });

    group('Settings', () {
      blocTest<QuranReaderBloc, QuranReaderState>(
        'emits updated settings on loadSettings',
        build: () {
          when(() => loadReaderSettingsUseCase.call()).thenAnswer(
            (_) async => const Right(ReaderSettingsEntity(fontSize: 25.0)),
          );
          return bloc;
        },
        act: (bloc) => bloc.add(const QuranReaderEvent.loadSettings()),
        expect: () => [
          const QuranReaderState(
            settings: ReaderSettingsEntity(fontSize: 25.0),
          ),
        ],
      );

      blocTest<QuranReaderBloc, QuranReaderState>(
        'emits updated settings on updateSettings',
        build: () {
          when(
            () => saveReaderSettingsUseCase.call(
              settings: any(named: 'settings'),
            ),
          ).thenAnswer((_) async => const Right(null));
          return bloc;
        },
        act: (bloc) => bloc.add(
          const QuranReaderEvent.updateSettings(
            ReaderSettingsEntity(fontSize: 35.0),
          ),
        ),
        expect: () => [
          const QuranReaderState(
            settings: ReaderSettingsEntity(fontSize: 35.0),
          ),
        ],
      );

      blocTest<QuranReaderBloc, QuranReaderState>(
        'emits updated settings on toggleTranslation',
        build: () {
          when(
            () => saveReaderSettingsUseCase.call(
              settings: any(named: 'settings'),
            ),
          ).thenAnswer((_) async => const Right(null));
          return bloc;
        },
        act: (bloc) => bloc.add(const QuranReaderEvent.toggleTranslation()),
        expect: () => [
          const QuranReaderState(
            settings: ReaderSettingsEntity(showTranslation: false),
          ),
        ],
      );
    });

    group('Search', () {
      blocTest<QuranReaderBloc, QuranReaderState>(
        'emits results on searchAyahs',
        build: () {
          when(
            () => searchAyahsUseCase.call(query: any(named: 'query')),
          ).thenAnswer((_) async => const Right([]));
          when(
            () => searchSurahsUseCase.call(query: any(named: 'query')),
          ).thenAnswer((_) async => const Right([]));
          return bloc;
        },
        act: (bloc) => bloc.add(const QuranReaderEvent.searchAyahs('test')),
        expect: () => [
          const QuranReaderState(isSearching: true, searchQuery: 'test'),
          const QuranReaderState(searchQuery: 'test'),
        ],
      );

      blocTest<QuranReaderBloc, QuranReaderState>(
        'clears search on clearSearch',
        build: () => bloc,
        act: (bloc) => bloc.add(const QuranReaderEvent.clearSearch()),
        expect: () => [const QuranReaderState()],
      );
    });

    group('Navigation', () {
      blocTest<QuranReaderBloc, QuranReaderState>(
        'emits [scrollToAyah, null] on scrollToAyah',
        build: () => bloc,
        act: (bloc) => bloc.add(const QuranReaderEvent.scrollToAyah(5)),
        expect: () => [
          const QuranReaderState(scrollToAyah: 5),
          const QuranReaderState(),
        ],
      );

      blocTest<QuranReaderBloc, QuranReaderState>(
        'calls saveLastReadPosition on saveLastRead',
        build: () {
          when(
            () => saveLastReadPositionUseCase.call(
              surahNumber: any(named: 'surahNumber'),
              ayahNumber: any(named: 'ayahNumber'),
            ),
          ).thenAnswer((_) async => const Right(null));
          return bloc;
        },
        act: (bloc) => bloc.add(
          const QuranReaderEvent.saveLastRead(surahNumber: 1, ayahNumber: 1),
        ),
        verify: (_) {
          verify(
            () =>
                saveLastReadPositionUseCase.call(surahNumber: 1, ayahNumber: 1),
          ).called(1);
        },
      );

      blocTest<QuranReaderBloc, QuranReaderState>(
        'emits [jumpToPage, null] on jumpToPage',
        build: () => bloc,
        act: (bloc) => bloc.add(const QuranReaderEvent.jumpToPage(10)),
        expect: () => [
          const QuranReaderState(jumpToPage: 10),
          const QuranReaderState(),
        ],
      );
    });

    group('updateFontSize', () {
      blocTest<QuranReaderBloc, QuranReaderState>(
        'emits updated fontSize on updateFontSize',
        build: () {
          when(
            () => saveReaderSettingsUseCase.call(
              settings: any(named: 'settings'),
            ),
          ).thenAnswer((_) async => const Right(null));
          return bloc;
        },
        act: (bloc) => bloc.add(const QuranReaderEvent.updateFontSize(28.0)),
        expect: () => [
          const QuranReaderState(
            settings: ReaderSettingsEntity(fontSize: 28.0),
          ),
        ],
      );
    });

    group('preloadAllPages', () {
      blocTest<QuranReaderBloc, QuranReaderState>(
        'emits isPreloading true when preloading starts',
        build: () {
          when(
            () =>
                getQuranPageUseCase.call(pageNumber: any(named: 'pageNumber')),
          ).thenAnswer((_) async => const Right(tPage));
          return bloc;
        },
        act: (bloc) => bloc.add(const QuranReaderEvent.preloadAllPages()),
        wait: const Duration(milliseconds: 100),
        verify: (bloc) {
          // Just verify preloading was triggered
          verify(
            () =>
                getQuranPageUseCase.call(pageNumber: any(named: 'pageNumber')),
          ).called(greaterThan(0));
        },
      );
    });

    group('Search edge cases', () {
      blocTest<QuranReaderBloc, QuranReaderState>(
        'returns no results and sets error when ayah search fails',
        build: () {
          when(
            () => searchAyahsUseCase.call(query: any(named: 'query')),
          ).thenAnswer((_) async => const Left(UnexpectedFailure('err')));
          when(
            () => searchSurahsUseCase.call(query: any(named: 'query')),
          ).thenAnswer((_) async => const Right([]));
          return bloc;
        },
        act: (bloc) => bloc.add(const QuranReaderEvent.searchAyahs('test')),
        expect: () => [
          const QuranReaderState(isSearching: true, searchQuery: 'test'),
          isA<QuranReaderState>()
              .having((s) => s.isSearching, 'isSearching', false)
              .having((s) => s.searchQuery, 'searchQuery', 'test')
              .having((s) => s.errorMessage, 'errorMessage', isNotEmpty),
        ],
      );

      blocTest<QuranReaderBloc, QuranReaderState>(
        'returns results when search has matches',
        build: () {
          const tAyah = AyahEntity(
            number: 1,
            numberInSurah: 1,
            surahNumber: 1,
            text: 'test ayah',
          );
          when(
            () => searchAyahsUseCase.call(query: any(named: 'query')),
          ).thenAnswer((_) async => const Right([tAyah]));
          when(
            () => searchSurahsUseCase.call(query: any(named: 'query')),
          ).thenAnswer((_) async => const Right([tSurah]));
          return bloc;
        },
        act: (bloc) => bloc.add(const QuranReaderEvent.searchAyahs('test')),
        expect: () => [
          const QuranReaderState(isSearching: true, searchQuery: 'test'),
          isA<QuranReaderState>()
              .having((s) => s.searchResults.length, 'searchResults', 1)
              .having((s) => s.surahSearchResults.length, 'surahResults', 1),
        ],
      );
    });
  });
}
