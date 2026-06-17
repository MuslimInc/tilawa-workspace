import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/home/presentation/widgets/home_dashboard_shortcut_grid.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

void main() {
  testWidgets('odd last item keeps standard cell width in RTL', (tester) async {
    const double viewportWidth = 360;
    final theme = AppTheme.getLightTheme(primaryColor: AppColors.defaultPrimary);
    final double gap = theme.tokens.spaceMedium;

    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: const Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            body: SizedBox(
              width: viewportWidth,
              child: HomeDashboardShortcutGrid(
                columnCount: 2,
                itemCount: 3,
                itemBuilder: _labeledTile,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final first = tester.renderObject<RenderBox>(
      find.byKey(const ValueKey<String>('grid-tile-0')),
    );
    final second = tester.renderObject<RenderBox>(
      find.byKey(const ValueKey<String>('grid-tile-1')),
    );
    final third = tester.renderObject<RenderBox>(
      find.byKey(const ValueKey<String>('grid-tile-2')),
    );

    final double halfWidth = (viewportWidth - gap) / 2;
    expect(first.size.width, closeTo(halfWidth, 1));
    expect(second.size.width, closeTo(halfWidth, 1));
    expect(third.size.width, closeTo(halfWidth, 1));
    expect(first.size.height, closeTo(third.size.height, 1));
    expect(second.size.height, closeTo(third.size.height, 1));

    // Lone last tile aligns with the first column (right in RTL).
    expect(third.localToGlobal(Offset.zero).dx, closeTo(first.localToGlobal(Offset.zero).dx, 1));
  });
}

Widget _labeledTile(BuildContext context, int index) {
  return SizedBox(
    key: ValueKey<String>('grid-tile-$index'),
    width: double.infinity,
    child: Text('tile-$index'),
  );
}
