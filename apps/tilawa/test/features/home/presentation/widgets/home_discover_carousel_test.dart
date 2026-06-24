import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/home/presentation/widgets/home_discover_carousel.dart';
import 'package:tilawa/features/home/presentation/widgets/home_travel_destination_card.dart';
import 'package:tilawa/l10n/generated/app_localizations.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

void main() {
  testWidgets('renders horizontal featured carousel cards', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.getLightTheme(primaryColor: AppColors.defaultPrimary),
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(
          body: SingleChildScrollView(
            child: HomeDiscoverCarousel(),
          ),
        ),
      ),
    );
    await tester.pump();

    final l10n = AppLocalizations.of(
      tester.element(find.byType(HomeDiscoverCarousel)),
    );

    expect(find.text(l10n.homeFeaturedTitle), findsOneWidget);
    expect(find.text(l10n.homeDailyAyahLabel), findsOneWidget);
    expect(find.text(l10n.supportTilawa), findsOneWidget);
    expect(find.text(l10n.homeSessionsTitle), findsNothing);
    expect(find.byType(HomeTravelDestinationCard), findsWidgets);
  });
}
