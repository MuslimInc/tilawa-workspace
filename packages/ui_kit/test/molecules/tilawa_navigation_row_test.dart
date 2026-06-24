import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

Widget _app(Widget child) {
  final ColorScheme colorScheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF219653),
  );

  return MaterialApp(
    theme: ThemeData(
      colorScheme: colorScheme,
      extensions: [
        TilawaDesignTokens.light(),
        TilawaComponentTokens.light(colorScheme: colorScheme),
      ],
    ),
    home: Scaffold(body: child),
  );
}

void main() {
  group('TilawaNavigationRow', () {
    testWidgets('invokes onTap and shows subtitle', (
      WidgetTester tester,
    ) async {
      var tapped = false;
      const subtitle = 'Track daily reading goals and progress.';

      await tester.pumpWidget(
        _app(
          SizedBox(
            width: 360,
            child: TilawaNavigationRow(
              icon: Icons.auto_stories_outlined,
              title: 'Daily plan',
              subtitle: subtitle,
              onTap: () => tapped = true,
              showDivider: false,
            ),
          ),
        ),
      );

      expect(find.text(subtitle), findsOneWidget);
      await tester.tap(find.text('Daily plan'));
      await tester.pump();
      expect(tapped, isTrue);
    });

    testWidgets('uses shared interactive surface for press feedback', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _app(
          SizedBox(
            width: 360,
            child: TilawaNavigationRow(
              icon: Icons.auto_stories_outlined,
              title: 'Daily plan',
              subtitle: 'Track goals.',
              onTap: () {},
              showDivider: false,
            ),
          ),
        ),
      );

      expect(find.byType(TilawaInteractiveSurface), findsOneWidget);
    });
  });

  group('TilawaHubNavigationGroup', () {
    testWidgets('renders navigation rows inside hub panel', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _app(
          TilawaHubNavigationGroup(
            children: [
              TilawaNavigationRow(
                icon: Icons.history,
                title: 'History',
                subtitle: 'Past sessions and milestones.',
                onTap: () {},
                showDivider: true,
              ),
              TilawaNavigationRow(
                icon: Icons.insights_outlined,
                title: 'Statistics',
                subtitle: 'Pages read over time.',
                onTap: () {},
                showDivider: false,
              ),
            ],
          ),
        ),
      );

      expect(find.byType(TilawaHubNavigationGroup), findsOneWidget);
      expect(find.byType(TilawaNavigationRow), findsNWidgets(2));
      expect(find.text('History'), findsOneWidget);
      expect(find.text('Statistics'), findsOneWidget);
    });
  });
}
