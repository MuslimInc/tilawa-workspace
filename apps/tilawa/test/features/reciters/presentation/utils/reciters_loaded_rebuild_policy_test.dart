import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/reciters/presentation/bloc/reciters_bloc.dart';
import 'package:tilawa/features/reciters/presentation/utils/reciters_loaded_rebuild_policy.dart';
import 'package:tilawa_core/entities/reciter_entity.dart';

void main() {
  const reciter1 = ReciterEntity(
    id: 1,
    name: 'Alpha',
    letter: 'A',
    date: '',
    moshaf: [],
  );
  const reciter2 = ReciterEntity(
    id: 2,
    name: 'Beta',
    letter: 'B',
    date: '',
    moshaf: [],
  );
  const reciter3 = ReciterEntity(
    id: 3,
    name: 'Gamma',
    letter: 'G',
    date: '',
    moshaf: [],
  );

  group('sameReciterOrder', () {
    test('returns true for identical order', () {
      expect(
        sameReciterOrder(
          const [reciter1, reciter2],
          const [reciter1, reciter2],
        ),
        isTrue,
      );
    });

    test('returns false when lengths differ', () {
      expect(sameReciterOrder(const [reciter1], const []), isFalse);
    });

    test('returns false when ids differ at same index', () {
      expect(
        sameReciterOrder(
          const [reciter1, reciter2],
          const [reciter2, reciter1],
        ),
        isFalse,
      );
    });
  });

  group('shouldRebuildRecitersLoaded', () {
    test(
      'skips rebuild when only favorite ids changed but list order unchanged',
      () {
        const previous = RecitersLoaded(
          reciters: [reciter1, reciter2, reciter3],
          filteredReciters: [reciter1, reciter2, reciter3],
          favoriteIds: {1},
        );
        const current = RecitersLoaded(
          reciters: [reciter1, reciter2, reciter3],
          filteredReciters: [reciter1, reciter2, reciter3],
          favoriteIds: {1, 2},
        );

        expect(shouldRebuildRecitersLoaded(previous, current), isFalse);
      },
    );

    test('rebuilds when favorites filter populates the visible list', () {
      const previous = RecitersLoaded(
        reciters: [reciter1, reciter2, reciter3],
        filteredReciters: [],
        showFavoritesOnly: true,
        favoriteIds: {},
      );
      const current = RecitersLoaded(
        reciters: [reciter1, reciter2, reciter3],
        filteredReciters: [reciter1, reciter2],
        showFavoritesOnly: true,
        favoriteIds: {1, 2},
      );

      expect(shouldRebuildRecitersLoaded(previous, current), isTrue);
    });

    test('skips rebuild when loaded state is unchanged', () {
      const previous = RecitersLoaded(
        reciters: [reciter1, reciter2, reciter3],
        filteredReciters: [reciter1, reciter2, reciter3],
        favoriteIds: {1},
      );
      const current = RecitersLoaded(
        reciters: [reciter1, reciter2, reciter3],
        filteredReciters: [reciter1, reciter2, reciter3],
        favoriteIds: {1},
      );

      expect(shouldRebuildRecitersLoaded(previous, current), isFalse);
    });

    test('rebuilds when catalog display content changes', () {
      const previous = RecitersLoaded(
        reciters: [reciter1, reciter2],
        filteredReciters: [reciter1, reciter2],
      );
      const localizedReciter1 = ReciterEntity(
        id: 1,
        name: 'Localized Alpha',
        letter: 'A',
        date: '',
        moshaf: [],
      );
      const current = RecitersLoaded(
        reciters: [localizedReciter1, reciter2],
        filteredReciters: [localizedReciter1, reciter2],
      );

      expect(shouldRebuildRecitersLoaded(previous, current), isTrue);
    });

    test('rebuilds when showFavoritesOnly changes', () {
      const previous = RecitersLoaded(
        reciters: [reciter1, reciter2],
        filteredReciters: [reciter1, reciter2],
      );
      const current = RecitersLoaded(
        reciters: [reciter1, reciter2],
        filteredReciters: [reciter1],
        showFavoritesOnly: true,
        favoriteIds: {1},
      );

      expect(shouldRebuildRecitersLoaded(previous, current), isTrue);
    });

    test('rebuilds when selected letter changes', () {
      const previous = RecitersLoaded(
        reciters: [reciter1, reciter2],
        filteredReciters: [reciter1, reciter2],
      );
      const current = RecitersLoaded(
        reciters: [reciter1, reciter2],
        filteredReciters: [reciter1],
        selectedLetter: 'A',
      );

      expect(shouldRebuildRecitersLoaded(previous, current), isTrue);
    });

    test('rebuilds when filtered list order changes', () {
      const previous = RecitersLoaded(
        reciters: [reciter1, reciter2, reciter3],
        filteredReciters: [reciter1, reciter2, reciter3],
        favoriteIds: {1, 3},
      );
      const current = RecitersLoaded(
        reciters: [reciter1, reciter2, reciter3],
        filteredReciters: [reciter1, reciter3, reciter2],
        favoriteIds: {1, 3},
      );

      expect(shouldRebuildRecitersLoaded(previous, current), isTrue);
    });
  });
}
