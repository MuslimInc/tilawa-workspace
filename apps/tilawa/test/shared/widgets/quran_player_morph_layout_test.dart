import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/shared/widgets/quran_player_morph_layout.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

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
      final Rect miniBar = const Rect.fromLTWH(0, 600, 400, 72);
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
      final Rect miniBar = const Rect.fromLTWH(0, 600, 400, 72);
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
  });
}
