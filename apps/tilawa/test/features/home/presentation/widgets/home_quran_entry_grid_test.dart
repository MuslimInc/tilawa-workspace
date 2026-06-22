import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/home/presentation/widgets/home_dashboard_card.dart';
import 'package:tilawa/features/home/presentation/widgets/home_quran_entry_grid.dart';
import 'package:tilawa/l10n/generated/app_localizations.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

void main() {
  testWidgets('english quran entry tiles share equal height', (tester) async {
    final view = tester.view;
    view.physicalSize = const Size(360, 640);
    view.devicePixelRatio = 1;
    addTearDown(view.resetPhysicalSize);
    addTearDown(view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.getLightTheme(primaryColor: AppColors.defaultPrimary),
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(
          body: Padding(
            padding: EdgeInsets.all(16),
            child: HomeQuranEntryGrid(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final cards = find.byType(HomeDashboardCard);
    expect(cards, findsNWidgets(2));

    final double recitersHeight = tester.getSize(cards.at(0)).height;
    final double quranHeight = tester.getSize(cards.at(1)).height;

    expect(recitersHeight, quranHeight);
    expect(tester.takeException(), isNull);
  });
}
