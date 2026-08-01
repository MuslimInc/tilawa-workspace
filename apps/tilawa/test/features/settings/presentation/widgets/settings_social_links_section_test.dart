import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/core/app_social_urls.dart';
import 'package:tilawa/core/utils/legal_url_launcher.dart';
import 'package:tilawa/features/settings/presentation/widgets/settings_social_links_section.dart';
import 'package:tilawa/l10n/generated/app_localizations.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

Widget _buildHarness({Locale locale = const Locale('en')}) {
  return MaterialApp(
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    theme: AppTheme.getLightTheme(primaryColor: AppColors.defaultPrimary),
    home: const Scaffold(
      body: SettingsSocialLinksSection(),
    ),
  );
}

void main() {
  tearDown(() {
    openLegalUrlOverride = null;
  });

  testWidgets('shows follow-us section with three channel rows', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_buildHarness());

    expect(find.text('Follow us'), findsOneWidget);
    expect(find.text('Facebook'), findsOneWidget);
    expect(find.text('Instagram'), findsOneWidget);
    expect(find.text('YouTube'), findsOneWidget);
  });

  testWidgets('shows Arabic labels', (WidgetTester tester) async {
    await tester.pumpWidget(_buildHarness(locale: const Locale('ar')));

    expect(find.text('تابعنا'), findsOneWidget);
    expect(find.text('فيسبوك'), findsOneWidget);
    expect(find.text('إنستغرام'), findsOneWidget);
    expect(find.text('يوتيوب'), findsOneWidget);
  });

  testWidgets('Facebook row opens Facebook URL', (WidgetTester tester) async {
    Uri? launched;
    openLegalUrlOverride = (Uri uri) async {
      launched = uri;
      return true;
    };

    await tester.pumpWidget(_buildHarness());
    await tester.tap(find.text('Facebook'));
    await tester.pumpAndSettle();

    expect(launched, Uri.parse(AppSocialUrls.facebook));
  });

  testWidgets('Instagram and YouTube rows open matching URLs', (
    WidgetTester tester,
  ) async {
    final List<Uri> launched = <Uri>[];
    openLegalUrlOverride = (Uri uri) async {
      launched.add(uri);
      return true;
    };

    await tester.pumpWidget(_buildHarness());

    await tester.tap(find.text('Instagram'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('YouTube'));
    await tester.pumpAndSettle();

    expect(launched, [
      Uri.parse(AppSocialUrls.instagram),
      Uri.parse(AppSocialUrls.youtube),
    ]);
  });
}
