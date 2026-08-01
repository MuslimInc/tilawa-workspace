import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

Widget _app(Widget child) {
  final colorScheme = ColorScheme.fromSeed(seedColor: Colors.teal);

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
  testWidgets('renders rows directly on the shared page surface', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        TilawaSettingsSection(
          title: 'Appearance',
          children: [
            TilawaSettingsTile(title: 'Theme', onTap: () {}),
            TilawaSettingsTile(
              title: 'Language',
              onTap: () {},
              showDivider: false,
            ),
          ],
        ),
      ),
    );

    expect(find.text('Appearance'), findsOneWidget);
    expect(find.text('Theme'), findsOneWidget);
    expect(find.text('Language'), findsOneWidget);
    expect(find.byType(TilawaSettingsGroupPanel), findsNothing);
    expect(find.byType(Divider), findsOneWidget);
  });
}
