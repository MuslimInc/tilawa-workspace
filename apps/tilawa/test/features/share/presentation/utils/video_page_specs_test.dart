import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/share/presentation/utils/share_feature_flags.dart';
import 'package:tilawa/features/share/presentation/utils/video_page_specs.dart';

void main() {
  group('buildVideoPageSpecs', () {
    test('uses conservative reel feature flag defaults', () {
      expect(kReelComposerV2, isFalse);
      expect(reelCanvasWidth, 1080);
      expect(reelCanvasHeight, 1920);
      expect(reelSafeZoneTopFraction, 0.08);
      expect(reelSafeZoneBottomFraction, 0.14);
    });

    test(
      'returns one page spec when the selected range fits a single page',
      () {
        final List<VideoPageSpec> specs = buildVideoPageSpecs(
          surahNumber: 1,
          fromAyah: 1,
          toAyah: 7,
        );

        expect(specs, hasLength(1));
        expect(specs.single.pageNumber, 1);
        expect(specs.single.fromAyah, 1);
        expect(specs.single.toAyah, 7);
        expect(specs.single.isInitialSelection, isFalse);
      },
    );

    test('splits the selected range across Mushaf pages', () {
      final List<VideoPageSpec> specs = buildVideoPageSpecs(
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
        final List<VideoPageSpec> specs = buildVideoPageSpecs(
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

    test('marks specs that represent the initial untouched selection', () {
      final List<VideoPageSpec> specs = buildVideoPageSpecs(
        surahNumber: 1,
        fromAyah: 1,
        toAyah: 7,
        isInitialSelection: true,
      );

      expect(specs.single.isInitialSelection, isTrue);
    });
  });
}
