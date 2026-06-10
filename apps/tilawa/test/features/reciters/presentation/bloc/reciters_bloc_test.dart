import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:tilawa/features/reciters/domain/usecases/get_reciters_use_case.dart';
import 'package:tilawa/features/reciters/presentation/bloc/reciters_bloc.dart';
import 'package:tilawa_core/entities/reciter_entity.dart';

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
      'should maintain favorites at top when filters are cleared',
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
          (s) => s.filteredReciters.first.id,
          'first reciter is favorite',
          2,
        ),
      ],
    );

    blocTest<RecitersBloc, RecitersState>(
      'SyncFavoriteIds keeps favorites filter off but bubbles favorites to top',
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
}
