import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/reciters/presentation/utils/reciter_list_moshaf_label.dart';
import 'package:tilawa_core/entities/moshaf_entity.dart';

void main() {
  group('compactMoshafName', () {
    test('strips Rewayat prefix and keeps riwaya and last style', () {
      expect(
        compactMoshafName(
          "Rewayat Hafs A'n Assem - Murattal - Mojawwad",
        ),
        "Hafs A'n Assem · Mojawwad",
      );
    });

    test('returns trimmed name when no hyphen segments', () {
      expect(compactMoshafName('Murattal'), 'Murattal');
    });

    test('handles empty input', () {
      expect(compactMoshafName(''), '');
    });
  });

  group('buildReciterListMoshafLabel', () {
    const moshaf = MoshafEntity(
      id: 1,
      name: "Rewayat Hafs A'n Assem - Murattal",
      server: 'https://example.com',
      surahTotal: 114,
      moshafType: 0,
      surahList: '1',
    );

    test('returns compact primary label for one moshaf', () {
      expect(
        buildReciterListMoshafLabel(
          moshaf: const [moshaf],
          additionalMoshafLabel: (int count) => ' · $count more',
        ),
        "Hafs A'n Assem · Murattal",
      );
    });

    test('appends additional count suffix for multiple moshaf', () {
      expect(
        buildReciterListMoshafLabel(
          moshaf: const [moshaf, moshaf],
          additionalMoshafLabel: (int count) => ' · $count more',
        ),
        "Hafs A'n Assem · Murattal · 1 more",
      );
    });
  });
}
