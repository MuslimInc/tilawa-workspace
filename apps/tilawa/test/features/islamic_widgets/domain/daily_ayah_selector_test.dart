import 'package:checks/checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/islamic_widgets/domain/entities/curated_ayah.dart';
import 'package:tilawa/features/islamic_widgets/domain/services/daily_ayah_selector.dart';

void main() {
  const DailyAyahSelector selector = DailyAyahSelector();
  const List<CuratedAyah> catalog = <CuratedAyah>[
    CuratedAyah(surahNumber: 1, ayahNumber: 1, pageNumber: 1),
    CuratedAyah(surahNumber: 2, ayahNumber: 255, pageNumber: 42),
    CuratedAyah(surahNumber: 94, ayahNumber: 5, pageNumber: 596),
  ];

  group('DailyAyahSelector', () {
    test('same local day and seed remain stable across times', () {
      final CuratedAyah morning = selector.select(
        localDate: DateTime(2026, 7, 11, 1),
        seed: 17,
        catalog: catalog,
      );
      final CuratedAyah evening = selector.select(
        localDate: DateTime(2026, 7, 11, 23, 59),
        seed: 17,
        catalog: catalog,
      );

      check(evening).equals(morning);
    });

    test('consecutive days exhaust the catalog before repeating', () {
      final DateTime firstDay = DateTime(2026, 7, 11);
      final List<CuratedAyah> selections = List<CuratedAyah>.generate(
        catalog.length,
        (int offset) => selector.select(
          localDate: firstDay.add(Duration(days: offset)),
          seed: 17,
          catalog: catalog,
        ),
      );

      check(selections.toSet().length).equals(catalog.length);
      check(
        selector.select(
          localDate: firstDay.add(Duration(days: catalog.length)),
          seed: 17,
          catalog: catalog,
        ),
      ).equals(selections.first);
    });

    test('installation seed shifts the rotation', () {
      final DateTime date = DateTime(2026, 7, 11);

      final CuratedAyah first = selector.select(
        localDate: date,
        seed: 0,
        catalog: catalog,
      );
      final CuratedAyah shifted = selector.select(
        localDate: date,
        seed: 1,
        catalog: catalog,
      );

      check(shifted == first).isFalse();
    });

    test('empty catalog is rejected', () {
      expect(
        () => selector.select(
          localDate: DateTime(2026, 7, 11),
          seed: 0,
          catalog: const <CuratedAyah>[],
        ),
        throwsArgumentError,
      );
    });
  });
}
