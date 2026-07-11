import 'package:flutter_test/flutter_test.dart';
import 'package:quran_image/verse_marker_layout.dart';

void main() {
  group('VerseMarkerLayout', () {
    test('marker scales linearly with layout width', () {
      expect(
        VerseMarkerLayout.markerWidth(360),
        closeTo(360 * VerseMarkerLayout.markerWidthRatio, 1e-6),
      );
      expect(
        VerseMarkerLayout.markerHeight(360),
        closeTo(360 * VerseMarkerLayout.markerHeightRatio, 1e-6),
      );
    });

    test('unclamped center tracks normalized centerX * layoutWidth', () {
      const layoutWidth = 360.0;
      const centerX = 0.37;
      const expectedCenter = centerX * layoutWidth;
      final actualCenter = VerseMarkerLayout.markerCenterXAfterLayout(
        centerX: centerX,
        layoutWidth: layoutWidth,
      );
      expect(actualCenter, closeTo(expectedCenter, 0.02));
    });

    test('left edge clamps when centerX is 0', () {
      const layoutWidth = 320.0;
      expect(
        VerseMarkerLayout.markerLeftOffset(
          centerX: 0,
          layoutWidth: layoutWidth,
        ),
        0.0,
      );
      final mw = VerseMarkerLayout.markerWidth(layoutWidth);
      expect(
        VerseMarkerLayout.markerCenterXAfterLayout(
          centerX: 0,
          layoutWidth: layoutWidth,
        ),
        closeTo(mw / 2, 1e-9),
      );
    });

    test('right edge clamps when centerX is 1', () {
      const layoutWidth = 414.0;
      final mw = VerseMarkerLayout.markerWidth(layoutWidth);
      final left = VerseMarkerLayout.markerLeftOffset(
        centerX: 1,
        layoutWidth: layoutWidth,
      );
      expect(left, layoutWidth - mw);
      expect(
        VerseMarkerLayout.markerCenterXAfterLayout(
          centerX: 1,
          layoutWidth: layoutWidth,
        ),
        closeTo(layoutWidth - mw / 2, 1e-9),
      );
    });

    /// Representative **logical** widths (dp) seen on phones and small tablets
    /// in **portrait** (narrow side).
    test('marker center stable across common portrait logical widths', () {
      const centerX = 0.42;
      for (final w in <double>[
        280,
        320,
        360,
        375,
        390,
        393,
        412,
        414,
        428,
        480,
        600,
        768,
        834,
      ]) {
        final center = VerseMarkerLayout.markerCenterXAfterLayout(
          centerX: centerX,
          layoutWidth: w,
        );
        expect(
          center,
          closeTo(centerX * w, 0.03 * w / 360 + 0.5),
          reason: 'width=$w',
        );
      }
    });

    /// Long-edge logical widths when the same devices are in **landscape**.
    test('marker center stable across common landscape logical widths', () {
      const centerX = 0.38;
      for (final w in <double>[
        640,
        568,
        780,
        812,
        844,
        852,
        915,
        896,
        926,
        854,
        960,
        1024,
        1194,
      ]) {
        final center = VerseMarkerLayout.markerCenterXAfterLayout(
          centerX: centerX,
          layoutWidth: w,
        );
        expect(
          center,
          closeTo(centerX * w, 0.03 * w / 360 + 0.5),
          reason: 'width=$w',
        );
      }
    });
  });
}
