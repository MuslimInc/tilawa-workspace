import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/prayer_times/domain/entities/entities.dart';
import 'package:tilawa/features/prayer_times/presentation/models/prayer_row_view_data.dart';
import 'package:tilawa/features/prayer_times/presentation/widgets/next_prayer_countdown_card.dart';
import 'package:tilawa/features/theme/domain/primary_color_preset.dart';
import 'package:tilawa/l10n/generated/app_localizations.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

void main() {
  setUpAll(() {
    AppTheme.useGoogleFonts = false;
  });

  testWidgets('narrow width lays out without exceptions', (tester) async {
    final next = PrayerTimeItem(
      type: PrayerType.fajr,
      time: DateTime(2030, 1, 1, 5, 30),
    );
    const alert = PrayerAlertViewData(
      state: PrayerAlertViewState.notification,
      label: 'Notification',
      supportsAlerts: true,
      supportsAdhan: true,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.getLightTheme(
          primaryColor: PrimaryColorPreset.defaultPreset.value,
          density: TilawaDensity.comfortable,
          useGoogleFontsOverride: false,
        ),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: Center(
          child: SizedBox(
            width: 320,
            child: NextPrayerCountdownCard(
              nextPrayer: next,
              timeUntil: const Duration(hours: 1, minutes: 2, seconds: 3),
              alert: alert,
              showPrayerTimeChipLabels: true,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
  });

  testWidgets('wide width lays out without exceptions', (tester) async {
    final next = PrayerTimeItem(
      type: PrayerType.maghrib,
      time: DateTime(2030, 1, 1, 18, 15),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.getLightTheme(
          primaryColor: PrimaryColorPreset.defaultPreset.value,
          density: TilawaDensity.comfortable,
          useGoogleFontsOverride: false,
        ),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: Center(
          child: SizedBox(
            width: 480,
            child: NextPrayerCountdownCard(
              nextPrayer: next,
              timeUntil: const Duration(minutes: 12, seconds: 1),
              showPrayerTimeChipLabels: true,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
  });
}
