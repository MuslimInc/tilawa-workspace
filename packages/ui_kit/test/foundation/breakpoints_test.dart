import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../lib/src/foundation/breakpoints.dart';
import '../../lib/src/foundation/content_bounds.dart';
import '../rtl_test_matrix.dart';

/// Harness that exposes the current [BuildContext] through a callback so
/// extension-based assertions can be evaluated against a real MediaQuery
/// subtree produced by the test's viewSize.
class _ContextProbe extends StatelessWidget {
  const _ContextProbe({required this.onBuild});

  final ValueChanged<BuildContext> onBuild;

  @override
  Widget build(BuildContext context) {
    onBuild(context);
    return const SizedBox.shrink();
  }
}

Future<BuildContext> _pump(
  WidgetTester tester,
  Size size,
  TextDirection direction,
) async {
  late BuildContext captured;
  await tester.binding.setSurfaceSize(size);
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  await pumpWithDirection(
    tester,
    MediaQuery(
      data: MediaQueryData(size: size),
      child: _ContextProbe(onBuild: (context) => captured = context),
    ),
    direction,
  );
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  return captured;
}

void main() {
  group('TilawaWindowSize resolution', () {
    testInBothDirections('narrow below 600', (tester, direction) async {
      final ctx = await _pump(tester, const Size(480, 800), direction);
      expect(ctx.windowSize, TilawaWindowSize.narrow);
      expect(ctx.isNarrow, isTrue);
      expect(ctx.isAtLeastMedium, isFalse);
      expect(ctx.isAtLeastExpanded, isFalse);
      expect(ctx.isAtLeastLarge, isFalse);
    });

    testInBothDirections('medium at 600', (tester, direction) async {
      final ctx = await _pump(tester, const Size(600, 800), direction);
      expect(ctx.windowSize, TilawaWindowSize.medium);
      expect(ctx.isNarrow, isFalse);
      expect(ctx.isAtLeastMedium, isTrue);
      expect(ctx.isAtLeastExpanded, isFalse);
    });

    testInBothDirections('expanded at 840', (tester, direction) async {
      final ctx = await _pump(tester, const Size(840, 900), direction);
      expect(ctx.windowSize, TilawaWindowSize.expanded);
      expect(ctx.isAtLeastMedium, isTrue);
      expect(ctx.isAtLeastExpanded, isTrue);
      expect(ctx.isAtLeastLarge, isFalse);
    });

    testInBothDirections('large at 1200', (tester, direction) async {
      final ctx = await _pump(tester, const Size(1200, 900), direction);
      expect(ctx.windowSize, TilawaWindowSize.large);
      expect(ctx.isAtLeastExpanded, isTrue);
      expect(ctx.isAtLeastLarge, isTrue);
    });
  });

  // resolveContentWidth depends on a Theme with MeMuslimDesignTokens; it is
  // exercised end-to-end via content_bounds_test.dart. Unit coverage of the
  // raw BuildContext extension is intentionally omitted here to avoid
  // duplicating theme setup.

  test('TilawaBreakpoints constants are MD3 aligned', () {
    expect(TilawaBreakpoints.narrowUpperBound, 600);
    expect(TilawaBreakpoints.medium, 840);
    expect(TilawaBreakpoints.expanded, 1200);
  });

  test('TilawaContentKind has four canonical kinds', () {
    expect(TilawaContentKind.values.length, 4);
    expect(TilawaContentKind.values.toSet(), {
      TilawaContentKind.reader,
      TilawaContentKind.form,
      TilawaContentKind.media,
      TilawaContentKind.settings,
    });
  });
}
