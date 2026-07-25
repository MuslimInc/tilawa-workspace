import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

void main() {
  group('MushafSpreadLayout', () {
    test('phone portrait stays single page', () {
      expect(
        MushafSpreadLayout.shouldUseDualPage(
          viewportWidth: 390,
          viewportHeight: 844,
        ),
        isFalse,
      );
      expect(
        MushafSpreadLayout.pageOuterPadding(
          pageColumnWidth: 390,
          viewportWidth: 390,
          viewportHeight: 844,
        ),
        0,
      );
    });

    test('phone landscape below min spread stays single page', () {
      expect(
        MushafSpreadLayout.shouldUseDualPage(
          viewportWidth: 844,
          viewportHeight: 390,
        ),
        isFalse,
      );
    });

    test('27-inch dual: outer pad only, content band 1762', () {
      const double width = 2560;
      const double height = 1440;
      const double pageSlot = width / 2;

      final double content = MushafSpreadLayout.pageContentWidth(
        pageColumnWidth: pageSlot,
        viewportWidth: width,
        viewportHeight: height,
      );
      final double outerPad = MushafSpreadLayout.pageOuterPadding(
        pageColumnWidth: pageSlot,
        viewportWidth: width,
        viewportHeight: height,
      );

      expect(
        content * 2,
        closeTo(width * MushafSpreadLayout.maxContentWidthFraction, 0.5),
      );
      // All leftover sits on one outer edge (not split / not middle).
      expect(content + outerPad, closeTo(pageSlot, 0.5));
      expect(outerPad, closeTo(pageSlot - content, 0.5));
      expect(outerPad, greaterThan(content * 0.2));
    });

    test('wide portrait does not force dual page', () {
      expect(
        MushafSpreadLayout.shouldUseDualPage(
          viewportWidth: 1200,
          viewportHeight: 1600,
        ),
        isFalse,
      );
    });

    test('single page respects content max width cap', () {
      expect(
        MushafSpreadLayout.pageColumnWidth(
          viewportWidth: 2000,
          viewportHeight: 2400,
          singlePageMaxWidth: 720,
        ),
        720,
      );
    });
  });
}
