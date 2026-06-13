import 'package:bloc_test/bloc_test.dart';
import 'package:dartz_plus/dartz_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:tilawa/features/reciters/domain/usecases/get_reciters_use_case.dart';
import 'package:tilawa/features/reciters/presentation/bloc/reciters_bloc.dart';
import 'package:tilawa_core/entities/reciter_entity.dart';
import 'package:tilawa_core/errors/failures.dart';

import 'reciters_bloc_test.mocks.dart';

@GenerateMocks([GetRecitersUseCase])
void main() {
  late RecitersBloc bloc;
  late MockGetRecitersUseCase mockGetReciters;

  const tReciter1 = ReciterEntity(
    id: 1,
    name: 'A',
    letter: 'A',
    date: '2023',
    moshaf: [],
  );
  const tReciter2 = ReciterEntity(
    id: 2,
    name: 'B',
    letter: 'B',
    date: '2023',
    moshaf: [],
  );
  const tReciter3 = ReciterEntity(
    id: 3,
    name: 'C',
    letter: 'C',
    date: '2023',
    moshaf: [],
  );
  const tReciters = [tReciter1, tReciter2, tReciter3];

  setUp(() {
    provideDummy<Either<Failure, List<ReciterEntity>>>(const Right([]));
    mockGetReciters = MockGetRecitersUseCase();
    bloc = RecitersBloc(mockGetReciters);
  });

  tearDown(() async {
    await bloc.close();
  });

  group('RecitersBloc Filtering', () {
    test('starts loaded when splash provided initial reciters', () {
      final startupBloc = RecitersBloc(
        mockGetReciters,
        initialReciters: tReciters,
      );
      addTearDown(startupBloc.close);

      expect(startupBloc.state, isA<RecitersLoaded>());
      final loaded = startupBloc.state as RecitersLoaded;
      expect(loaded.reciters, tReciters);
      expect(loaded.filteredReciters, tReciters);
    });

    blocTest<RecitersBloc, RecitersState>(
      'should NOT lose favoriteIds when ClearFavoritesFilter is dispatched',
      build: () {
        return bloc;
      },
      seed: () => const RecitersLoaded(
        reciters: tReciters,
        filteredReciters: [tReciter2],
        showFavoritesOnly: true,
        favoriteIds: {2},
      ),
      act: (bloc) => bloc.add(const ClearFavoritesFilter()),
      expect: () => [
        isA<RecitersLoaded>()
            .having((s) => s.showFavoritesOnly, 'showFavoritesOnly', false)
            .having((s) => s.favoriteIds, 'favoriteIds', {2})
            .having(
              (s) => s.filteredReciters.length,
              'filteredReciters count',
              3,
            ),
      ],
    );

    blocTest<RecitersBloc, RecitersState>(
      'ClearFavoritesFilter restores full catalog order',
      build: () {
        return bloc;
      },
      seed: () => const RecitersLoaded(
        reciters: tReciters,
        filteredReciters: [tReciter2],
        showFavoritesOnly: true,
        favoriteIds: {2},
      ),
      act: (bloc) => bloc.add(const ClearFavoritesFilter()),
      expect: () => [
        isA<RecitersLoaded>().having(
          (s) => s.filteredReciters.map((r) => r.id).toList(),
          'filtered ids',
          [1, 2, 3],
        ),
      ],
    );

    blocTest<RecitersBloc, RecitersState>(
      'SyncFavoriteIds keeps catalog order during optimistic toggles',
      build: () => bloc,
      seed: () => const RecitersLoaded(
        reciters: tReciters,
        filteredReciters: tReciters,
        favoriteIds: {2},
      ),
      act: (bloc) => bloc.add(const SyncFavoriteIds({1, 3})),
      expect: () => [
        isA<RecitersLoaded>()
            .having((s) => s.showFavoritesOnly, 'showFavoritesOnly', isFalse)
            .having((s) => s.favoriteIds, 'favoriteIds', {1, 3})
            .having(
              (s) => s.filteredReciters.map((r) => r.id).toList(),
              'filtered ids',
              [1, 2, 3],
            ),
      ],
    );

    blocTest<RecitersBloc, RecitersState>(
      'ApplyFavoriteOrdering bubbles favorites to the top',
      build: () => bloc,
      seed: () => const RecitersLoaded(
        reciters: tReciters,
        filteredReciters: tReciters,
        favoriteIds: {1, 3},
      ),
      act: (bloc) => bloc.add(const ApplyFavoriteOrdering()),
      expect: () => [
        isA<RecitersLoaded>().having(
          (s) => s.filteredReciters.map((r) => r.id).toList(),
          'filtered ids',
          [1, 3, 2],
        ),
      ],
    );

    blocTest<RecitersBloc, RecitersState>(
      'SyncFavoriteIds repopulates favorites-only filtered list',
      build: () => bloc,
      seed: () => const RecitersLoaded(
        reciters: tReciters,
        filteredReciters: [],
        showFavoritesOnly: true,
        favoriteIds: {},
      ),
      act: (bloc) => bloc.add(const SyncFavoriteIds({1, 2})),
      expect: () => [
        isA<RecitersLoaded>()
            .having((s) => s.showFavoritesOnly, 'showFavoritesOnly', isTrue)
            .having((s) => s.favoriteIds, 'favoriteIds', {1, 2})
            .having(
              (s) => s.filteredReciters.map((r) => r.id).toList(),
              'filtered ids',
              [1, 2],
            ),
      ],
    );

    blocTest<RecitersBloc, RecitersState>(
      'favorites-only filter respects an active letter filter',
      build: () => bloc,
      seed: () => const RecitersLoaded(
        reciters: tReciters,
        filteredReciters: [],
        selectedLetter: 'A',
        showFavoritesOnly: true,
        favoriteIds: {},
      ),
      act: (bloc) => bloc.add(const SyncFavoriteIds({1, 2})),
      expect: () => [
        isA<RecitersLoaded>().having(
          (s) => s.filteredReciters.map((r) => r.id).toList(),
          'filtered ids',
          [1],
        ),
      ],
    );
  });

  group('RecitersBloc refresh ordering', () {
    blocTest<RecitersBloc, RecitersState>(
      'LoadReciters reorders with favorite ids synced during fetch',
      build: () {
        when(mockGetReciters.call()).thenAnswer((_) async {
          await Future<void>.delayed(const Duration(milliseconds: 50));
          return const Right(tReciters);
        });
        return bloc;
      },
      seed: () => const RecitersLoaded(
        reciters: tReciters,
        filteredReciters: tReciters,
        favoriteIds: {1},
      ),
      act: (bloc) async {
        final Future<void> loadFuture = bloc.stream
            .firstWhere((RecitersState state) => state is RecitersLoaded)
            .then((_) {});
        bloc.add(const LoadReciters());
        await Future<void>.delayed(const Duration(milliseconds: 10));
        bloc.add(const SyncFavoriteIds({1, 3}));
        await loadFuture;
      },
      expect: () => [
        const RecitersLoading(),
        isA<RecitersLoaded>()
            .having((s) => s.favoriteIds, 'favoriteIds', {1, 3})
            .having(
              (s) => s.filteredReciters.map((r) => r.id).toList(),
              'filtered ids',
              [1, 3, 2],
            ),
      ],
    );

    blocTest<RecitersBloc, RecitersState>(
      'SyncFavoriteIds during RecitersLoading updates ids for next loaded emit',
      build: () {
        when(mockGetReciters.call()).thenAnswer((_) async {
          await Future<void>.delayed(const Duration(milliseconds: 50));
          return const Right(tReciters);
        });
        return bloc;
      },
      seed: () => const RecitersLoaded(
        reciters: tReciters,
        filteredReciters: tReciters,
        favoriteIds: {},
      ),
      act: (bloc) async {
        final Future<void> loadFuture = bloc.stream
            .firstWhere((RecitersState state) => state is RecitersLoaded)
            .then((_) {});
        bloc.add(const LoadReciters());
        await Future<void>.delayed(const Duration(milliseconds: 10));
        bloc.add(const SyncFavoriteIds({2, 3}));
        await loadFuture;
      },
      expect: () => [
        const RecitersLoading(),
        isA<RecitersLoaded>()
            .having((s) => s.favoriteIds, 'favoriteIds', {2, 3})
            .having(
              (s) => s.filteredReciters.map((r) => r.id).toList(),
              'filtered ids',
              [2, 3, 1],
            ),
      ],
    );

    blocTest<RecitersBloc, RecitersState>(
      'LoadReciters places favorites first on refresh',
      build: () {
        when(mockGetReciters.call()).thenAnswer(
          (_) async => const Right(tReciters),
        );
        return RecitersBloc(mockGetReciters);
      },
      seed: () => const RecitersLoaded(
        reciters: tReciters,
        filteredReciters: tReciters,
        favoriteIds: {1, 3},
      ),
      act: (bloc) async {
        bloc.add(const LoadReciters());
        await bloc.stream.firstWhere(
          (RecitersState state) => state is RecitersLoaded,
        );
      },
      expect: () => [
        const RecitersLoading(),
        isA<RecitersLoaded>().having(
          (s) => s.filteredReciters.map((r) => r.id).toList(),
          'filtered ids',
          [1, 3, 2],
        ),
      ],
    );
  });

  group('RecitersBloc catalog operations', () {
    blocTest<RecitersBloc, RecitersState>(
      'FilterByLetter narrows the visible catalog',
      build: () => bloc,
      seed: () => const RecitersLoaded(
        reciters: tReciters,
        filteredReciters: tReciters,
      ),
      act: (bloc) => bloc.add(const FilterByLetter('B')),
      expect: () => [
        isA<RecitersLoaded>()
            .having((s) => s.selectedLetter, 'selectedLetter', 'B')
            .having(
              (s) => s.filteredReciters.map((r) => r.id).toList(),
              'filtered ids',
              [2],
            ),
      ],
    );

    blocTest<RecitersBloc, RecitersState>(
      'ClearLetterFilter restores the full catalog',
      build: () => bloc,
      seed: () => const RecitersLoaded(
        reciters: tReciters,
        filteredReciters: [tReciter1],
        selectedLetter: 'A',
      ),
      act: (bloc) => bloc.add(const ClearLetterFilter()),
      expect: () => [
        isA<RecitersLoaded>()
            .having((s) => s.selectedLetter, 'selectedLetter', isNull)
            .having(
              (s) => s.filteredReciters.map((r) => r.id).toList(),
              'filtered ids',
              [1, 2, 3],
            ),
      ],
    );

    blocTest<RecitersBloc, RecitersState>(
      'LoadReciters emits RecitersError when repository fails',
      build: () {
        when(mockGetReciters.call()).thenAnswer(
          (_) async => const Left(ServerFailure('offline')),
        );
        return RecitersBloc(mockGetReciters);
      },
      seed: () => const RecitersLoaded(
        reciters: tReciters,
        filteredReciters: tReciters,
      ),
      act: (bloc) async {
        bloc.add(const LoadReciters());
        await bloc.stream.firstWhere(
          (RecitersState state) => state is RecitersError,
        );
      },
      expect: () => [
        const RecitersLoading(),
        const RecitersError(ServerFailure('offline')),
      ],
    );

    blocTest<RecitersBloc, RecitersState>(
      'LanguageChanged clears letter filter and reloads reciters',
      build: () {
        when(mockGetReciters.call()).thenAnswer(
          (_) async => const Right(tReciters),
        );
        return RecitersBloc(mockGetReciters);
      },
      seed: () => const RecitersLoaded(
        reciters: tReciters,
        filteredReciters: [tReciter1],
        selectedLetter: 'A',
        favoriteIds: {1},
      ),
      act: (bloc) async {
        bloc.add(const LanguageChanged());
        await bloc.stream.firstWhere(
          (RecitersState state) =>
              state is RecitersLoaded && (state).filteredReciters.length == 3,
        );
      },
      expect: () => [
        isA<RecitersLoaded>().having(
          (s) => s.selectedLetter,
          'selectedLetter',
          isNull,
        ),
        const RecitersLoading(),
        isA<RecitersLoaded>()
            .having((s) => s.selectedLetter, 'selectedLetter', isNull)
            .having(
              (s) => s.filteredReciters.map((r) => r.id).toList(),
              'filtered ids',
              [1, 2, 3],
            ),
      ],
    );

    blocTest<RecitersBloc, RecitersState>(
      'ApplyFavoriteOrdering is a no-op when favorites already lead',
      build: () => bloc,
      seed: () => const RecitersLoaded(
        reciters: tReciters,
        filteredReciters: [tReciter1, tReciter3, tReciter2],
        favoriteIds: {1, 3},
      ),
      act: (bloc) => bloc.add(const ApplyFavoriteOrdering()),
      expect: () => <RecitersState>[],
    );

    blocTest<RecitersBloc, RecitersState>(
      'SyncFavoriteIds is a no-op when ids are unchanged',
      build: () => bloc,
      seed: () => const RecitersLoaded(
        reciters: tReciters,
        filteredReciters: tReciters,
        favoriteIds: {1},
      ),
      act: (bloc) => bloc.add(const SyncFavoriteIds({1})),
      expect: () => <RecitersState>[],
    );

    test('ignores filter events while not loaded', () async {
      expect(bloc.state, isA<RecitersInitial>());
      bloc.add(const FilterByLetter('A'));
      bloc.add(const ClearLetterFilter());
      bloc.add(const ClearFavoritesFilter());
      bloc.add(const ApplyFavoriteOrdering());
      await Future<void>.delayed(Duration.zero);
      expect(bloc.state, isA<RecitersInitial>());
    });
  });
}
