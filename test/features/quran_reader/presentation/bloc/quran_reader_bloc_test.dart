import 'package:bloc_test/bloc_test.dart';
import 'package:dartz_plus/dartz_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tilawa/core/errors/failures.dart';
import 'package:tilawa/features/quran_reader/domain/entities/entities.dart';
import 'package:tilawa/features/quran_reader/domain/usecases/get_all_pages_use_case.dart';
import 'package:tilawa/features/quran_reader/domain/usecases/usecases.dart';
import 'package:tilawa/features/quran_reader/presentation/bloc/quran_reader_bloc.dart';

import '../../../../helpers/hydrated_bloc_test_helper.dart';

class MockGetSurahContentUseCase extends Mock
    implements GetSurahContentUseCase {}

class MockGetQuranPageUseCase extends Mock implements GetQuranPageUseCase {}

class MockSaveLastReadPositionUseCase extends Mock
    implements SaveLastReadPositionUseCase {}

class MockSearchAyahsUseCase extends Mock implements SearchAyahsUseCase {}

class MockSearchSurahsUseCase extends Mock implements SearchSurahsUseCase {}

class MockGetAllPagesUseCase extends Mock implements GetAllPagesUseCase {}

void main() {
  late MockGetSurahContentUseCase getSurahContentUseCase;
  late MockGetQuranPageUseCase getQuranPageUseCase;

  late MockSaveLastReadPositionUseCase saveLastReadPositionUseCase;
  late MockSearchAyahsUseCase searchAyahsUseCase;
  late MockSearchSurahsUseCase searchSurahsUseCase;
  late MockGetAllPagesUseCase getAllPagesUseCase;
  late QuranReaderBloc bloc;

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

  Map<int, QuranPageEntity> getInitialPages() {
    return {
      for (int i = 1; i <= 604; i++)
        i: QuranPageEntity(
          pageNumber: i,
          ayahs: [],
          juz: ((i - 1) ~/ 20) + 1,
          hizb: ((i - 1) ~/ 10) + 1,
        ),
    };
  }

  final Map<int, QuranPageEntity> initialPages = getInitialPages();

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
    saveLastReadPositionUseCase = MockSaveLastReadPositionUseCase();
    searchAyahsUseCase = MockSearchAyahsUseCase();
    searchSurahsUseCase = MockSearchSurahsUseCase();
    getAllPagesUseCase = MockGetAllPagesUseCase();

    // Stub for preloadAllPages which is called in constructor
    when(
      () => getQuranPageUseCase.call(pageNumber: any(named: 'pageNumber')),
    ).thenAnswer((_) async => const Right(tPage));

    bloc = QuranReaderBloc(
      getSurahContentUseCase,
      getQuranPageUseCase,
      saveLastReadPositionUseCase,
      searchAyahsUseCase,
      searchSurahsUseCase,
      getAllPagesUseCase,
    );
  });

  tearDown(() {
    bloc.close();
  });

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
          QuranReaderState(
            status: QuranReaderStatus.loading,
            pages: initialPages,
          ),
          QuranReaderState(
            status: QuranReaderStatus.loaded,
            currentSurah: tSurah,
            pages: initialPages,
          ),
          QuranReaderState(
            status: QuranReaderStatus.loaded,
            currentSurah: tSurah,
            jumpToPage: 1,
            pages: initialPages,
          ),
          QuranReaderState(
            status: QuranReaderStatus.loaded,
            currentSurah: tSurah,
            pages: initialPages,
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
          QuranReaderState(
            status: QuranReaderStatus.loading,
            pages: initialPages,
          ),
          QuranReaderState(
            status: QuranReaderStatus.error,
            errorMessage: 'UnexpectedFailure(err)',
            pages: initialPages,
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
          isA<QuranReaderState>()
              .having((s) => s.status, 'status', QuranReaderStatus.loaded)
              .having((s) => s.currentPage, 'currentPage', tPage)
              .having((s) => s.pages[1], 'pages[1]', tPage)
              .having((s) => s.pages.length, 'pages.length', 604),
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
          QuranReaderState(
            status: QuranReaderStatus.error,
            errorMessage: 'UnexpectedFailure(err)',
            pages: initialPages,
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
            saveLastReadPositionUseCase,
            searchAyahsUseCase,
            searchSurahsUseCase,
            getAllPagesUseCase,
          )..emit(QuranReaderState(pages: {1: pageWithWords}));
        },
        act: (bloc) => bloc.add(const QuranReaderEvent.loadPage(1)),
        expect: () => [
          isA<QuranReaderState>()
              .having((s) => s.currentPage?.pageNumber, 'pageNumber', 1)
              .having((s) => s.status, 'status', QuranReaderStatus.loaded),
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
          QuranReaderState(
            isSearching: true,
            searchQuery: 'test',
            pages: initialPages,
          ),
          QuranReaderState(searchQuery: 'test', pages: initialPages),
        ],
      );

      blocTest<QuranReaderBloc, QuranReaderState>(
        'clears search on clearSearch',
        build: () => bloc,
        act: (bloc) => bloc.add(const QuranReaderEvent.clearSearch()),
        expect: () => [QuranReaderState(pages: initialPages)],
      );
    });

    group('Navigation', () {
      blocTest<QuranReaderBloc, QuranReaderState>(
        'emits [scrollToAyah, null] on scrollToAyah',
        build: () => bloc,
        act: (bloc) => bloc.add(const QuranReaderEvent.scrollToAyah(5)),
        expect: () => [
          QuranReaderState(scrollToAyah: 5, pages: initialPages),
          QuranReaderState(pages: initialPages),
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
          QuranReaderState(jumpToPage: 10, pages: initialPages),
          QuranReaderState(pages: initialPages),
        ],
      );
    });

    group('preloadAllPages', () {
      blocTest<QuranReaderBloc, QuranReaderState>(
        'emits [loading, loaded] with full pages on success',
        build: () {
          when(
            () => getAllPagesUseCase.call(),
          ).thenAnswer((_) async => Right(initialPages));
          return bloc;
        },
        act: (bloc) => bloc.add(const QuranReaderEvent.preloadAllPages()),
        expect: () => [
          isA<QuranReaderState>().having(
            (p) => p.isPreloading,
            'loading',
            true,
          ),
          isA<QuranReaderState>()
              .having((p) => p.isPreloading, 'loading', false)
              .having((p) => p.pages, 'pages', isNotEmpty),
        ],
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
          QuranReaderState(
            isSearching: true,
            searchQuery: 'test',
            pages: initialPages,
          ),
          isA<QuranReaderState>()
              .having((s) => s.isSearching, 'isSearching', false)
              .having((s) => s.searchQuery, 'searchQuery', 'test')
              .having((s) => s.errorMessage, 'errorMessage', isNotEmpty)
              .having((s) => s.pages, 'pages', initialPages),
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
          QuranReaderState(
            isSearching: true,
            searchQuery: 'test',
            pages: initialPages,
          ),
          isA<QuranReaderState>()
              .having((s) => s.searchResults.length, 'searchResults', 1)
              .having((s) => s.surahSearchResults.length, 'surahResults', 1),
        ],
      );
    });

    group('prefetchPages', () {
      const tPage2 = QuranPageEntity(
        pageNumber: 2,
        ayahs: [
          PageAyahInfo(
            surahNumber: 2,
            surahName: 'Al-Baqarah',
            surahNameEnglish: 'The Cow',
            ayahNumber: 1,
            text: 'Alif Lam Mim',
          ),
        ],
        juz: 1,
        hizb: 1,
      );

      blocTest<QuranReaderBloc, QuranReaderState>(
        'adds pages to state without changing currentPage',
        build: () {
          when(
            () => getQuranPageUseCase.call(pageNumber: 2),
          ).thenAnswer((_) async => const Right(tPage2));
          return bloc;
        },
        seed: () => QuranReaderState(
          status: QuranReaderStatus.loaded,
          currentPage: tPage,
          pages: {...initialPages, 1: tPage},
        ),
        act: (bloc) => bloc.add(const QuranReaderEvent.prefetchPages([2])),
        wait: const Duration(milliseconds: 500),
        expect: () => [
          isA<QuranReaderState>()
              .having((s) => s.currentPage, 'currentPage', tPage)
              .having((s) => s.pages[1], 'pages[1]', tPage)
              .having((s) => s.pages[2], 'pages[2]', tPage2)
              .having((s) => s.pages.length, 'pages.length', 604),
        ],
        verify: (_) {
          verify(() => getQuranPageUseCase.call(pageNumber: 2)).called(1);
        },
      );
    });
  });
}
