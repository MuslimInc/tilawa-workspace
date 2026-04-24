import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../lib/src/foundation/content_bounds.dart';
import '../../lib/src/foundation/design_tokens.dart';
import '../rtl_test_matrix.dart';

Widget _wrap({
  required Widget child,
  required TextDirection direction,
  Size viewSize = const Size(2000, 1000),
}) {
  return MediaQuery(
    data: MediaQueryData(size: viewSize),
    child: Directionality(
      textDirection: direction,
      child: Theme(
        data: ThemeData(extensions: [TilawaDesignTokens.light()]),
        child: child,
      ),
    ),
  );
}

void main() {
  group('TilawaContentBounds max-width clamping', () {
    final cases = <TilawaContentKind, double>{
      TilawaContentKind.reader: 720,
      TilawaContentKind.form: 560,
      TilawaContentKind.media: 1200,
      TilawaContentKind.settings: 760,
    };

    for (final entry in cases.entries) {
      testInBothDirections('${entry.key.name} caps at ${entry.value.toInt()}', (
        tester,
        direction,
      ) async {
        await tester.binding.setSurfaceSize(const Size(2000, 1000));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        final childKey = GlobalKey();
        await pumpWithDirection(
          tester,
          _wrap(
            direction: direction,
            child: TilawaContentBounds(
              kind: entry.key,
              child: Container(key: childKey, color: const Color(0xFFFFFFFF)),
            ),
          ),
          direction,
        );

        final rendered = tester.getSize(find.byKey(childKey));
        expect(rendered.width, entry.value);
      });
    }

    testInBothDirections('maxWidth override wins over kind', (
      tester,
      direction,
    ) async {
      await tester.binding.setSurfaceSize(const Size(2000, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final childKey = GlobalKey();
      await pumpWithDirection(
        tester,
        _wrap(
          direction: direction,
          child: TilawaContentBounds(
            kind: TilawaContentKind.reader,
            maxWidth: 400,
            child: Container(key: childKey, color: const Color(0xFFFFFFFF)),
          ),
        ),
        direction,
      );

      expect(tester.getSize(find.byKey(childKey)).width, 400);
    });

    testInBothDirections('on narrow screens child fills available width', (
      tester,
      direction,
    ) async {
      await tester.binding.setSurfaceSize(const Size(360, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final childKey = GlobalKey();
      await pumpWithDirection(
        tester,
        _wrap(
          direction: direction,
          viewSize: const Size(360, 800),
          child: TilawaContentBounds(
            kind: TilawaContentKind.reader,
            child: Container(key: childKey, color: const Color(0xFFFFFFFF)),
          ),
        ),
        direction,
      );

      // Narrow (<720) → child takes full width.
      expect(tester.getSize(find.byKey(childKey)).width, 360);
    });
  });

  group('TilawaContentBounds alignment', () {
    testInBothDirections('child is horizontally centered on wide screens', (
      tester,
      direction,
    ) async {
      await tester.binding.setSurfaceSize(const Size(2000, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final childKey = GlobalKey();
      await pumpWithDirection(
        tester,
        _wrap(
          direction: direction,
          child: TilawaContentBounds(
            kind: TilawaContentKind.reader,
            child: Container(key: childKey, color: const Color(0xFFFFFFFF)),
          ),
        ),
        direction,
      );

      final topLeft = tester.getTopLeft(find.byKey(childKey));
      final topRight = tester.getTopRight(find.byKey(childKey));
      // Reader cap = 720 on a 2000-wide surface → 640 margin, 320 each side.
      expect(topLeft.dx, closeTo(640, 0.5));
      expect(topRight.dx, closeTo(1360, 0.5));
    });
  });
}
