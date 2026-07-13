import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/shared/widgets/quran_player_morph_layout.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import 'quran_player_mini_bar_layout_expectations.dart';

void main() {
  group('QuranPlayerMorphLayout', () {
    late QuranPlayerMorphThemeGeometry geometry;

    setUp(() {
      final barTokens = TilawaMediaPlayerBarTokens.defaults();
      geometry = QuranPlayerMorphThemeGeometry.fromBarTokens(
        spaceLarge: 16,
        progressHeight: 3,
        barContentPadding: barTokens.contentPadding,
        barTokens: barTokens,
        expandedArtBorderRadius: 16,
      );
    });

    test('art rect lerps between mini and expanded anchors', () {
      const Rect miniBar = Rect.fromLTWH(0, 600, 400, 72);
      const Size viewport = Size(400, 800);
      final collapsed = QuranPlayerMorphLayout.compute(
        progress: 0,
        viewport: viewport,
        miniBarRect: miniBar,
        sheetOffsetY: 0,
        geometry: geometry,
      );
      final expanded = QuranPlayerMorphLayout.compute(
        progress: 1,
        viewport: viewport,
        miniBarRect: miniBar,
        sheetOffsetY: 0,
        geometry: geometry,
      );
      expect(collapsed.artRect.width, lessThan(expanded.artRect.width));
      expect(collapsed.artRect.top, greaterThan(expanded.artRect.top));
    });

    test('mid progress produces intermediate art size', () {
      const Rect miniBar = Rect.fromLTWH(0, 600, 400, 72);
      final mid = QuranPlayerMorphLayout.compute(
        progress: 0.5,
        viewport: const Size(400, 800),
        miniBarRect: miniBar,
        sheetOffsetY: 200,
        geometry: geometry,
      );
      final collapsed = QuranPlayerMorphLayout.compute(
        progress: 0,
        viewport: const Size(400, 800),
        miniBarRect: miniBar,
        sheetOffsetY: 200,
        geometry: geometry,
      );
      final expanded = QuranPlayerMorphLayout.compute(
        progress: 1,
        viewport: const Size(400, 800),
        miniBarRect: miniBar,
        sheetOffsetY: 200,
        geometry: geometry,
      );
      expect(
        mid.artRect.width,
        inInclusiveRange(collapsed.artRect.width, expanded.artRect.width),
      );
    });

    test('LTR progress 0 matches media bar artwork expectations', () {
      const Rect miniBar = Rect.fromLTWH(0, 600, 400, 72);
      final QuranPlayerMorphLayout collapsed = QuranPlayerMorphLayout.compute(
        progress: 0,
        viewport: const Size(400, 800),
        miniBarRect: miniBar,
        sheetOffsetY: 0,
        geometry: geometry,
        textDirection: TextDirection.ltr,
      );
      expect(
        collapsed.artRect,
        quranPlayerExpectedMiniArtRect(
          miniBarRect: miniBar,
          geometry: geometry,
          textDirection: TextDirection.ltr,
        ),
      );
    });

    test('RTL progress 0 places artwork on trailing edge', () {
      const Rect miniBar = Rect.fromLTWH(16, 600, 368, 72);
      final QuranPlayerMorphLayout collapsed = QuranPlayerMorphLayout.compute(
        progress: 0,
        viewport: const Size(400, 800),
        miniBarRect: miniBar,
        sheetOffsetY: 0,
        geometry: geometry,
        textDirection: TextDirection.rtl,
      );
      final Rect expected = quranPlayerExpectedMiniArtRect(
        miniBarRect: miniBar,
        geometry: geometry,
        textDirection: TextDirection.rtl,
      );
      expect(collapsed.artRect, expected);
      expect(collapsed.titleScaleAlignment, Alignment.topRight);
      expect(collapsed.showMorphSubtitle, isTrue);
    });

    test(
      'collapse mid-progress uses horizontal identity not vertical stack',
      () {
        const Rect miniBar = Rect.fromLTWH(16, 620, 368, 76);
        final QuranPlayerMorphLayout mid = QuranPlayerMorphLayout.compute(
          progress: 0.25,
          viewport: const Size(400, 800),
          miniBarRect: miniBar,
          sheetOffsetY: 120,
          geometry: geometry,
          textDirection: TextDirection.ltr,
        );
        expect(mid.horizontalIdentity, isTrue);
        expect(mid.metadataIsVerticallyStacked, isFalse);
        expect(
          quranPlayerMorphMetadataIsBesideArt(
            artRect: mid.artRect,
            titleRect: mid.titleRect,
            textDirection: TextDirection.ltr,
          ),
          isTrue,
        );
        expect(
          quranPlayerMorphMetadataSharesArtRow(
            artRect: mid.artRect,
            titleRect: mid.titleRect,
          ),
          isTrue,
        );
      },
    );

    test('compute uses default optional parameters', () {
      const Rect miniBar = Rect.fromLTWH(0, 600, 400, 72);
      final QuranPlayerMorphLayout layout = QuranPlayerMorphLayout.compute(
        progress: 0.9,
        viewport: const Size(400, 800),
        miniBarRect: miniBar,
        sheetOffsetY: 0,
        geometry: geometry,
      );
      expect(layout.horizontalIdentity, isFalse);
      expect(layout.titleScaleAlignment, Alignment.topCenter);
      expect(layout.titleMaxLines, 2);
    });

    test('late expand progress uses vertical metadata under artwork', () {
      const Rect miniBar = Rect.fromLTWH(16, 620, 368, 76);
      final QuranPlayerMorphLayout late = QuranPlayerMorphLayout.compute(
        progress: 0.85,
        viewport: const Size(400, 800),
        miniBarRect: miniBar,
        sheetOffsetY: 0,
        geometry: geometry,
        textDirection: TextDirection.ltr,
      );
      expect(late.horizontalIdentity, isFalse);
      expect(late.metadataIsVerticallyStacked, isTrue);
      expect(late.titleAlign, TextAlign.center);
    });
  });
}
