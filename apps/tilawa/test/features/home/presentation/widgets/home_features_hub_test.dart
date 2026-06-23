import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/home/presentation/widgets/home_features_hub.dart';
import 'package:tilawa/l10n/generated/app_localizations.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

void main() {
  testWidgets('renders quick actions and discover grid labels', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.getLightTheme(primaryColor: AppColors.defaultPrimary),
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            child: HomeFeaturesHub(onOpenPrayer: () {}),
          ),
        ),
      ),
    );
    await tester.pump();

    final l10n = AppLocalizations.of(
      tester.element(find.byType(HomeFeaturesHub)),
    );

    expect(find.text(l10n.homeExploreTitle), findsOneWidget);
    expect(find.text(l10n.homeQuickAthkar), findsWidgets);
    expect(find.text(l10n.homeQuickQibla), findsWidgets);
    expect(find.text(l10n.homeQuickTasbeeh), findsWidgets);
    expect(find.text(l10n.homeQuickPrayer), findsOneWidget);
    expect(find.text(l10n.bookmarks), findsOneWidget);
    expect(find.text(l10n.supportTilawa), findsOneWidget);
  });
}
