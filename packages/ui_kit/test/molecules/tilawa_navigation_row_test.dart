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
        MeMuslimDesignTokens.light(),
        MeMuslimComponentTokens.light(colorScheme: colorScheme),
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

    testWidgets('keeps subtitle rows within the hub navigation height band', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _app(
          SizedBox(
            width: 360,
            child: TilawaNavigationRow(
              icon: Icons.auto_stories_outlined,
              title: 'Daily plan',
              subtitle: 'Track daily reading goals and progress.',
              onTap: () {},
              showDivider: false,
            ),
          ),
        ),
      );

      final rowBox = tester.getSize(find.byType(TilawaNavigationRow));
      expect(rowBox.height, inInclusiveRange(72, 80));
    });

    testWidgets('limits subtitle to one line with ellipsis', (
      WidgetTester tester,
    ) async {
      const subtitle =
          'This supporting copy is intentionally long and should truncate '
          'after the first line with an ellipsis at the end.';

      await tester.pumpWidget(
        _app(
          SizedBox(
            width: 280,
            child: TilawaNavigationRow(
              icon: Icons.auto_stories_outlined,
              title: 'Daily plan',
              subtitle: subtitle,
              onTap: () {},
              showDivider: false,
            ),
          ),
        ),
      );

      final subtitleFinder = find.text(subtitle);
      expect(subtitleFinder, findsOneWidget);

      final subtitleWidget = tester.widget<Text>(subtitleFinder);
      expect(subtitleWidget.maxLines, 1);
      expect(subtitleWidget.overflow, TextOverflow.ellipsis);
    });

    testWidgets('renders tertiary emphasis with outline icon treatment', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _app(
          SizedBox(
            width: 360,
            child: TilawaNavigationRow(
              emphasis: TilawaNavigationRowEmphasis.tertiary,
              icon: Icons.delete_outline_rounded,
              title: 'Delete plan',
              subtitle: 'Deletes plan only.',
              onTap: () {},
              showDivider: false,
            ),
          ),
        ),
      );

      final iconBox = tester.widget<TilawaIconBox>(find.byType(TilawaIconBox));
      expect(iconBox.variant, TilawaIconBoxVariant.outline);
    });

    testWidgets(
      'omits navigation chevron when showsNavigationChevron is false',
      (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          _app(
            SizedBox(
              width: 360,
              child: TilawaNavigationRow(
                icon: Icons.delete_outline_rounded,
                title: 'Delete plan',
                subtitle: 'Deletes plan only.',
                showsNavigationChevron: false,
                onTap: () {},
                showDivider: false,
              ),
            ),
          ),
        );

        expect(find.byIcon(TilawaIcons.chevronRightSmall), findsNothing);
      },
    );
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
