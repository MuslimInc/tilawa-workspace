import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

Widget _app(Widget child) {
  final ColorScheme colorScheme = ColorScheme.fromSeed(
    seedColor: Colors.teal,
  );

  return MaterialApp(
    theme: ThemeData(
      colorScheme: colorScheme,
      extensions: [
        TilawaDesignTokens.light(),
        TilawaComponentTokens.light(colorScheme: colorScheme),
      ],
    ),
    home: Scaffold(body: Center(child: child)),
  );
}

void main() {
  group('TilawaSettingsTile subtitle', () {
    testWidgets('renders supporting copy with settings token style', (
      WidgetTester tester,
    ) async {
      const subtitle = 'Used for downloads, reminders, and reader progress.';

      await tester.pumpWidget(
        _app(
          SizedBox(
            width: 360,
            child: TilawaSettingsTile(
              icon: Icons.lock_outline,
              title: 'Privacy',
              subtitle: subtitle,
              onTap: () {},
              showDivider: false,
            ),
          ),
        ),
      );

      final BuildContext context = tester.element(
        find.byType(TilawaSettingsTile),
      );
      final theme = Theme.of(context);
      final tokens = theme.componentTokens.settingsGroup;
      final Text subtitleWidget = tester.widget(find.text(subtitle));

      expect(subtitleWidget.maxLines, 2);
      expect(subtitleWidget.overflow, TextOverflow.ellipsis);
      expect(subtitleWidget.style?.fontSize, tokens.tileSubtitleFontSize);
      expect(
        subtitleWidget.style?.color,
        theme.colorScheme.onSurfaceVariant.withValues(
          alpha: tokens.tileSubtitleOpacity,
        ),
      );
    });

    testWidgets('switch tile keeps row toggle behavior with subtitle', (
      WidgetTester tester,
    ) async {
      bool? changedValue;

      await tester.pumpWidget(
        _app(
          SizedBox(
            width: 360,
            child: TilawaSettingsSwitchTile(
              icon: Icons.notifications_none,
              title: 'Reminders',
              subtitle: 'Choose whether Tilawa can send quiet reminders.',
              value: false,
              onChanged: (value) => changedValue = value,
              showDivider: false,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(ListTile));
      await tester.pump();

      expect(changedValue, isTrue);
    });
  });
}
