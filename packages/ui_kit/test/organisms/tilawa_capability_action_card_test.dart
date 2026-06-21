import 'package:checks/checks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

Widget _wrap({
  required Widget child,
  required Brightness brightness,
  TextDirection textDirection = TextDirection.ltr,
}) {
  final ColorScheme colorScheme = ColorScheme.fromSeed(
    seedColor: AppColors.defaultPrimary,
    brightness: brightness,
  );

  return MaterialApp(
    theme: ThemeData(
      colorScheme: colorScheme,
      brightness: brightness,
      extensions: [
        TilawaDesignTokens.light(),
        TilawaComponentTokens.light(colorScheme: colorScheme),
      ],
    ),
    darkTheme: ThemeData(
      colorScheme: colorScheme,
      brightness: brightness,
      extensions: [
        TilawaDesignTokens.dark(),
        TilawaComponentTokens.dark(colorScheme: colorScheme),
      ],
    ),
    themeMode: brightness == Brightness.dark ? ThemeMode.dark : ThemeMode.light,
    home: Directionality(
      textDirection: textDirection,
      child: Scaffold(body: child),
    ),
  );
}

void main() {
  group('TilawaCapabilityActionCard', () {
    testWidgets('renders title, subtitle, badge, and chevron', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          brightness: Brightness.light,
          child: TilawaCapabilityActionCard(
            title: 'لوحة تحكم المحفظ',
            subtitle: 'يمكنك إدارة مواعيدك وجلساتك من هنا',
            leadingIcon: TilawaIcons.teacherCapability,
            badgeLabel: 'محفظ معتمد',
            onTap: () {},
          ),
        ),
      );

      check(find.text('لوحة تحكم المحفظ').evaluate().length).equals(1);
      check(
        find.text('يمكنك إدارة مواعيدك وجلساتك من هنا').evaluate().length,
      ).equals(1);
      check(find.text('محفظ معتمد').evaluate().length).equals(1);
      check(
        find.byType(TilawaVerifiedTeacherBadge).evaluate().length,
      ).equals(1);
      check(
        find.byIcon(TilawaIcons.chevronRightSmall).evaluate().length,
      ).equals(1);
    });

    testWidgets('meets minimum tap target height', (WidgetTester tester) async {
      await tester.pumpWidget(
        _wrap(
          brightness: Brightness.light,
          child: TilawaCapabilityActionCard(
            title: 'Teacher dashboard',
            subtitle: 'Manage sessions',
            leadingIcon: TilawaIcons.teacherCapability,
            onTap: () {},
          ),
        ),
      );

      final Size cardSize = tester.getSize(
        find.byType(TilawaCapabilityActionCard),
      );
      check(cardSize.height >= kTilawaMinInteractiveDimension).isTrue();
    });

    testWidgets('Arabic copy does not clip in RTL layout', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(360, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        _wrap(
          brightness: Brightness.light,
          textDirection: TextDirection.rtl,
          child: const SizedBox(
            width: 320,
            child: TilawaCapabilityActionCard(
              title: 'لوحة تحكم المحفظ',
              subtitle: 'يمكنك إدارة مواعيدك وجلساتك من هنا',
              leadingIcon: TilawaIcons.teacherCapability,
              badgeLabel: 'محفظ معتمد',
              onTap: _noop,
            ),
          ),
        ),
      );

      final titleSize = tester.getSize(find.text('لوحة تحكم المحفظ'));
      final subtitleSize = tester.getSize(
        find.text('يمكنك إدارة مواعيدك وجلساتك من هنا'),
      );

      check(titleSize.height).isGreaterThan(0);
      check(subtitleSize.height).isGreaterThan(0);
    });

    testWidgets('dark theme keeps readable title and subtitle colors', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          brightness: Brightness.dark,
          child: TilawaCapabilityActionCard(
            title: 'Teacher dashboard',
            subtitle: 'Manage sessions',
            leadingIcon: TilawaIcons.teacherCapability,
            onTap: () {},
          ),
        ),
      );

      final titleStyle = tester
          .widget<Text>(find.text('Teacher dashboard'))
          .style;
      final subtitleStyle = tester
          .widget<Text>(find.text('Manage sessions'))
          .style;

      check(titleStyle?.color).isNotNull();
      check(subtitleStyle?.color).isNotNull();
      check(titleStyle!.color != subtitleStyle!.color).isTrue();
    });
  });
}

void _noop() {}
