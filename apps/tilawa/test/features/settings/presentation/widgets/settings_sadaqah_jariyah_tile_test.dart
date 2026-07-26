import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/settings/presentation/widgets/settings_sadaqah_jariyah_tile.dart';
import 'package:tilawa/l10n/generated/app_localizations.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

Widget _buildHarness({Locale locale = const Locale('en')}) {
  return MaterialApp(
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    theme: AppTheme.getLightTheme(primaryColor: AppColors.defaultPrimary),
    home: const Scaffold(body: SettingsSadaqahJariyahTile()),
  );
}

void main() {
  testWidgets('shows title, subtitle, and leading icon', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_buildHarness());

    expect(find.text('Sadaqah Jariyah'), findsOneWidget);
    expect(
      find.text('Registered names and share requests'),
      findsOneWidget,
    );
    expect(find.byIcon(TilawaIcons.heart), findsOneWidget);
  });

  testWidgets('shows Arabic subtitle copy', (WidgetTester tester) async {
    await tester.pumpWidget(_buildHarness(locale: const Locale('ar')));

    expect(find.text('صدقة جارية'), findsOneWidget);
    expect(find.text('الأسماء المسجلة وطلب سهم'), findsOneWidget);
  });
}
