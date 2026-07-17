import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/home/presentation/widgets/home_dashboard_content_sliver.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

void main() {
  testWidgets('applies trailing scroll bottom padding to dashboard body', (
    tester,
  ) async {
    const double miniPlayerHeight = 57;
    late double expectedBottomPadding;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.getLightTheme(primaryColor: AppColors.defaultPrimary),
        home: Builder(
          builder: (hostContext) {
            expectedBottomPadding = hostContext.tokens.spaceExtraLarge;

            return const TilawaShellPadding(
              padding: miniPlayerHeight,
              child: Scaffold(
                body: CustomScrollView(
                  slivers: [
                    HomeDashboardContentSliver(
                      child: Text('sheet body'),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
    await tester.pump();

    expect(find.text('sheet body'), findsOneWidget);

    final Finder padded = find.ancestor(
      of: find.text('sheet body'),
      matching: find.byType(Padding),
    );
    final Padding paddingWidget = tester
        .widgetList<Padding>(padded)
        .firstWhere(
          (widget) => widget.padding is EdgeInsets,
        );
    final EdgeInsets insets = paddingWidget.padding as EdgeInsets;
    expect(insets.bottom, expectedBottomPadding);
    expect(insets.bottom, 24);
  });
}
