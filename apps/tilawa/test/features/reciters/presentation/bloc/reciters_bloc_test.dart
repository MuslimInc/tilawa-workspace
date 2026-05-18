import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:tilawa_core/entities/reciter_entity.dart';
import 'package:tilawa/features/reciters/domain/usecases/get_reciters_use_case.dart';
import 'package:tilawa/features/reciters/presentation/bloc/reciters_bloc.dart';

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
  const tReciters = [tReciter1, tReciter2];

  setUp(() {
    mockGetReciters = MockGetRecitersUseCase();
    bloc = RecitersBloc(mockGetReciters);
  });

  group('RecitersBloc Filtering', () {
    blocTest<RecitersBloc, RecitersState>(
      'should NOT lose favoriteIds when ClearFavoritesFilter is dispatched',
      build: () {
        return bloc;
      },
      seed: () => const RecitersLoaded(
        reciters: tReciters,
        filteredReciters: [tReciter2],
        showFavoritesOnly: true,
        favoriteIds: [2],
      ),
      act: (bloc) => bloc.add(const ClearFavoritesFilter()),
      expect: () => [
        isA<RecitersLoaded>()
            .having((s) => s.showFavoritesOnly, 'showFavoritesOnly', false)
            .having((s) => s.favoriteIds, 'favoriteIds', [2])
            .having(
              (s) => s.filteredReciters.length,
              'filteredReciters count',
              2,
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
        favoriteIds: [2],
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
  });
}
