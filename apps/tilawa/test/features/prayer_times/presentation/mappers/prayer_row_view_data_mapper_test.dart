import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/prayer_times/domain/entities/entities.dart';
import 'package:tilawa/features/prayer_times/presentation/mappers/prayer_row_view_data_mapper.dart';
import 'package:tilawa/l10n/generated/app_localizations.dart';

void main() {
  group('PrayerRowViewDataMapper', () {
    testWidgets('excludes Sunrise when showSunrise is false', (tester) async {
      late AppLocalizations l10n;
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) {
              l10n = AppLocalizations.of(context)!;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      final now = DateTime.now();
      final prayerTimes = _buildPrayerTimes(now);
      final settings = const PrayerSettingsEntity(showSunrise: false);
      final currentPrayer = PrayerTimeItem(
        type: PrayerType.dhuhr,
        time: prayerTimes.dhuhr,
      );

      final rows = PrayerRowViewDataMapper.map(
        prayerTimes: prayerTimes,
        settings: settings,
        currentPrayer: currentPrayer,
        l10n: l10n,
        isArabic: false,
      );

      expect(rows.any((row) => row.type == PrayerType.sunrise), isFalse);
    });

    testWidgets('includes Sunrise as secondary when enabled', (tester) async {
      late AppLocalizations l10n;
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) {
              l10n = AppLocalizations.of(context)!;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      final now = DateTime.now();
      final prayerTimes = _buildPrayerTimes(now);
      final settings = const PrayerSettingsEntity(showSunrise: true);
      final currentPrayer = PrayerTimeItem(
        type: PrayerType.dhuhr,
        time: prayerTimes.dhuhr,
      );

      final rows = PrayerRowViewDataMapper.map(
        prayerTimes: prayerTimes,
        settings: settings,
        currentPrayer: currentPrayer,
        l10n: l10n,
        isArabic: false,
      );

      final sunriseRow = rows.firstWhere(
        (row) => row.type == PrayerType.sunrise,
      );
      expect(sunriseRow.isSecondary, isTrue);
      expect(sunriseRow.showAlertIndicators, isFalse);
    });

    testWidgets('maps notification and adhan status per prayer', (
      tester,
    ) async {
      late AppLocalizations l10n;
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) {
              l10n = AppLocalizations.of(context)!;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      final now = DateTime.now();
      final prayerTimes = _buildPrayerTimes(now);
      final settings = PrayerSettingsEntity(
        fajrNotification: const PrayerNotificationSettings(
          mode: PrayerAlertMode.none,
        ),
        dhuhrNotification: const PrayerNotificationSettings(
          mode: PrayerAlertMode.notification,
        ),
        asrNotification: const PrayerNotificationSettings(
          mode: PrayerAlertMode.adhan,
        ),
      );

      final rows = PrayerRowViewDataMapper.map(
        prayerTimes: prayerTimes,
        settings: settings,
        currentPrayer: null,
        l10n: l10n,
        isArabic: false,
      );

      final fajr = rows.firstWhere((row) => row.type == PrayerType.fajr);
      final dhuhr = rows.firstWhere((row) => row.type == PrayerType.dhuhr);
      final asr = rows.firstWhere((row) => row.type == PrayerType.asr);

      expect(fajr.notificationEnabled, isFalse);
      expect(fajr.adhanEnabled, isFalse);
      expect(fajr.statusText, l10n.prayerTimesPassed);
      expect(dhuhr.notificationEnabled, isTrue);
      expect(dhuhr.adhanEnabled, isFalse);
      expect(dhuhr.statusText, l10n.prayerTimesUpcoming);
      expect(asr.notificationEnabled, isTrue);
      expect(asr.adhanEnabled, isTrue);
      expect(asr.statusText, l10n.prayerTimesUpcoming);
    });

    test('toggles notification settings for supported prayer', () {
      const settings = PrayerSettingsEntity(
        fajrNotification: PrayerNotificationSettings(
          mode: PrayerAlertMode.none,
        ),
      );

      final updated = PrayerRowViewDataMapper.toggledNotificationSettings(
        settings,
        PrayerType.fajr,
      );

      expect(updated, isNotNull);
      expect(updated!.fajrNotification.enabled, isTrue);
      expect(updated.fajrNotification.playAdhan, isFalse);
    });

    test('does not toggle adhan when notification disabled', () {
      const settings = PrayerSettingsEntity(
        fajrNotification: PrayerNotificationSettings(
          mode: PrayerAlertMode.none,
        ),
      );

      final updated = PrayerRowViewDataMapper.toggledAdhanSettings(
        settings,
        PrayerType.fajr,
      );

      expect(updated, isNull);
    });
  });
}

PrayerTimeEntity _buildPrayerTimes(DateTime now) {
  return PrayerTimeEntity(
    date: DateTime(now.year, now.month, now.day),
    fajr: now.subtract(const Duration(hours: 5)),
    sunrise: now.subtract(const Duration(hours: 4)),
    dhuhr: now.add(const Duration(minutes: 30)),
    asr: now.add(const Duration(hours: 3)),
    maghrib: now.add(const Duration(hours: 6)),
    isha: now.add(const Duration(hours: 8)),
    midnight: now.add(const Duration(hours: 10)),
    lastThird: now.add(const Duration(hours: 12)),
  );
}
