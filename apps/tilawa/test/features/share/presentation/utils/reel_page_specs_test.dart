import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/share/presentation/utils/reel_page_specs.dart';

void main() {
  group('buildReelPageSpecs', () {
    test(
      'returns one page spec when the selected range fits a single page',
      () {
        final List<ReelPageSpec> specs = buildReelPageSpecs(
          surahNumber: 1,
          fromAyah: 1,
          toAyah: 7,
        );

        expect(specs, hasLength(1));
        expect(specs.single.pageNumber, 1);
        expect(specs.single.fromAyah, 1);
        expect(specs.single.toAyah, 7);
      },
    );

    test('splits the selected range across Mushaf pages', () {
      final List<ReelPageSpec> specs = buildReelPageSpecs(
        surahNumber: 2,
        fromAyah: 1,
        toAyah: 16,
      );

      expect(specs, hasLength(2));

      expect(specs[0].pageNumber, 2);
      expect(specs[0].fromAyah, 1);
      expect(specs[0].toAyah, 5);

      expect(specs[1].pageNumber, 3);
      expect(specs[1].fromAyah, 6);
      expect(specs[1].toAyah, 16);
    });

    test(
      'trims the first and last Mushaf pages to the selected ayah range',
      () {
        final List<ReelPageSpec> specs = buildReelPageSpecs(
          surahNumber: 2,
          fromAyah: 4,
          toAyah: 10,
        );

        expect(specs, hasLength(2));
        expect(specs[0].pageNumber, 2);
        expect(specs[0].fromAyah, 4);
        expect(specs[0].toAyah, 5);
        expect(specs[1].pageNumber, 3);
        expect(specs[1].fromAyah, 6);
        expect(specs[1].toAyah, 10);
      },
    );
  });
}
