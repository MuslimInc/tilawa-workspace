import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa_core/entities/reciter_entity.dart';
import 'package:tilawa/features/reciters/presentation/utils/reciter_list_order.dart';

ReciterEntity _reciter(int id) => ReciterEntity(
  id: id,
  name: 'Reciter $id',
  letter: 'A',
  date: '2023',
  moshaf: const [],
);

void main() {
  group('sameFavoriteIdSet', () {
    test('returns true for identical sets', () {
      final Set<int> ids = <int>{1, 2};
      expect(sameFavoriteIdSet(ids, ids), isTrue);
    });

    test('returns true for equal sets with different instances', () {
      expect(sameFavoriteIdSet(<int>{1, 2}, <int>{2, 1}), isTrue);
    });

    test('returns false when lengths differ', () {
      expect(sameFavoriteIdSet(<int>{1}, <int>{1, 2}), isFalse);
    });

    test('returns false when membership differs', () {
      expect(sameFavoriteIdSet(<int>{1, 2}, <int>{1, 3}), isFalse);
    });
  });

  group('favoritesInCatalogOrder', () {
    test('returns favorites in catalog order', () {
      final List<ReciterEntity> reciters = <ReciterEntity>[
        _reciter(3),
        _reciter(1),
        _reciter(2),
      ];
      final List<ReciterEntity> ordered = favoritesInCatalogOrder(
        <int>{1, 2},
        reciters,
      );
      expect(ordered.map((ReciterEntity r) => r.id).toList(), <int>[1, 2]);
    });

    test('returns empty list when no favorites', () {
      expect(
        favoritesInCatalogOrder(const <int>{}, <ReciterEntity>[_reciter(1)]),
        isEmpty,
      );
    });
  });

  group('recitersAlreadyFavoritesFirst', () {
    test('returns true when favorites precede others', () {
      final List<ReciterEntity> reciters = <ReciterEntity>[
        _reciter(1),
        _reciter(2),
        _reciter(3),
      ];
      expect(recitersAlreadyFavoritesFirst(reciters, <int>{1, 2}), isTrue);
    });

    test('returns false when a favorite follows a non-favorite', () {
      final List<ReciterEntity> reciters = <ReciterEntity>[
        _reciter(1),
        _reciter(3),
        _reciter(2),
      ];
      expect(recitersAlreadyFavoritesFirst(reciters, <int>{1, 2}), isFalse);
    });
  });

  group('bubbleFavoritesToTop', () {
    test('returns same list when already ordered', () {
      final List<ReciterEntity> reciters = <ReciterEntity>[
        _reciter(1),
        _reciter(2),
        _reciter(3),
      ];
      expect(
        identical(bubbleFavoritesToTop(reciters, <int>{1, 2}), reciters),
        isTrue,
      );
    });

    test('moves favorites to the front preserving relative order', () {
      final List<ReciterEntity> reciters = <ReciterEntity>[
        _reciter(3),
        _reciter(1),
        _reciter(4),
        _reciter(2),
      ];
      final List<ReciterEntity> reordered = bubbleFavoritesToTop(
        reciters,
        <int>{1, 2},
      );
      expect(
        reordered.map((ReciterEntity r) => r.id).toList(),
        <int>[1, 2, 3, 4],
      );
    });
  });
}
