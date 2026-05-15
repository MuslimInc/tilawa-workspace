import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/prayer_times/domain/entities/entities.dart';
import 'package:tilawa/features/prayer_times/domain/prayer_times_clock.dart';
import 'package:tilawa/features/prayer_times/presentation/mappers/prayer_row_view_data_mapper.dart';
import 'package:tilawa/features/prayer_times/presentation/models/prayer_row_view_data.dart';
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
      expect(sunriseRow.showAlertIndicators, isTrue);
      expect(sunriseRow.alert.supportsAdhan, isFalse);
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
      expect(fajr.alert.state, PrayerAlertViewState.off);
      expect(fajr.alert.label, l10n.prayerAlertModeOff);
      expect(fajr.statusText, l10n.prayerTimesPassed);
      expect(dhuhr.statusText, '');
      expect(dhuhr.notificationEnabled, isTrue);
      expect(dhuhr.adhanEnabled, isFalse);
      expect(dhuhr.alert.state, PrayerAlertViewState.notification);
      expect(dhuhr.alert.label, l10n.prayerAlertModeNotifyOnly);
      expect(asr.notificationEnabled, isTrue);
      expect(asr.adhanEnabled, isTrue);
      expect(asr.alert.state, PrayerAlertViewState.adhan);
      expect(asr.alert.label, l10n.prayerAlertModeAdhan);
      expect(asr.statusText, '');
    });

    testWidgets(
      'omits the hero next-prayer row when it is the same instant',
      (tester) async {
        late AppLocalizations l10n;
        addTearDown(PrayerTimesClock.clearTestingOverride);

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

        PrayerTimesClock.overrideForTesting(() => DateTime(2030, 6, 15, 10));
        final prayerTimes = PrayerTimeEntity(
          date: DateTime(2030, 6, 15),
          fajr: DateTime(2030, 6, 15, 4),
          sunrise: DateTime(2030, 6, 15, 5),
          dhuhr: DateTime(2030, 6, 15, 12, 30),
          asr: DateTime(2030, 6, 15, 16),
          maghrib: DateTime(2030, 6, 15, 18, 30),
          isha: DateTime(2030, 6, 15, 20),
          midnight: DateTime(2030, 6, 15, 23),
          lastThird: DateTime(2030, 6, 16, 1),
        );
        const settings = PrayerSettingsEntity(showSunrise: true);
        final heroNext = prayerTimes.getCurrentOrNextPrayer()!;

        final withOmit = PrayerRowViewDataMapper.map(
          prayerTimes: prayerTimes,
          settings: settings,
          currentPrayer: heroNext,
          l10n: l10n,
          isArabic: false,
          omitFromListWhenSameInstantAs: heroNext,
        );
        final withoutOmit = PrayerRowViewDataMapper.map(
          prayerTimes: prayerTimes,
          settings: settings,
          currentPrayer: heroNext,
          l10n: l10n,
          isArabic: false,
        );

        expect(heroNext.type, PrayerType.dhuhr);
        expect(withOmit.any((row) => row.type == PrayerType.dhuhr), isFalse);
        expect(withoutOmit.any((row) => row.type == PrayerType.dhuhr), isTrue);
      },
    );

    testWidgets(
      'keeps today Fajr in list when hero counts down to tomorrow Fajr',
      (tester) async {
        late AppLocalizations l10n;
        addTearDown(PrayerTimesClock.clearTestingOverride);

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

        PrayerTimesClock.overrideForTesting(() => DateTime(2030, 6, 15, 21));
        final prayerTimes = PrayerTimeEntity(
          date: DateTime(2030, 6, 15),
          fajr: DateTime(2030, 6, 15, 4),
          sunrise: DateTime(2030, 6, 15, 5),
          dhuhr: DateTime(2030, 6, 15, 12, 30),
          asr: DateTime(2030, 6, 15, 16),
          maghrib: DateTime(2030, 6, 15, 18, 30),
          isha: DateTime(2030, 6, 15, 20),
          midnight: DateTime(2030, 6, 15, 23),
          lastThird: DateTime(2030, 6, 16, 1),
        );
        const settings = PrayerSettingsEntity(showSunrise: false);
        final heroNext = prayerTimes.getCurrentOrNextPrayer()!;

        final rows = PrayerRowViewDataMapper.map(
          prayerTimes: prayerTimes,
          settings: settings,
          currentPrayer: heroNext,
          l10n: l10n,
          isArabic: false,
          omitFromListWhenSameInstantAs: heroNext,
        );

        expect(heroNext.type, PrayerType.fajr);
        expect(heroNext.time, DateTime(2030, 6, 16, 4));
        final fajrRow = rows.firstWhere((row) => row.type == PrayerType.fajr);
        expect(fajrRow.isCurrent, isFalse);
        expect(fajrRow.statusText, l10n.prayerTimesPassed);
      },
    );

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

    test('updates alert mode for supported prayer', () {
      const settings = PrayerSettingsEntity(
        fajrNotification: PrayerNotificationSettings(
          mode: PrayerAlertMode.none,
        ),
      );

      final updated = PrayerRowViewDataMapper.updatedAlertModeSettings(
        settings,
        PrayerType.fajr,
        PrayerAlertMode.adhan,
      );

      expect(updated, isNotNull);
      expect(updated!.fajrNotification.enabled, isTrue);
      expect(updated.fajrNotification.playAdhan, isTrue);
    });

    test('coerces Sunrise Adhan mode to notification only', () {
      const settings = PrayerSettingsEntity(
        sunriseNotification: PrayerNotificationSettings(
          mode: PrayerAlertMode.none,
        ),
      );

      final updated = PrayerRowViewDataMapper.updatedAlertModeSettings(
        settings,
        PrayerType.sunrise,
        PrayerAlertMode.adhan,
      );

      expect(updated, isNotNull);
      expect(updated!.sunriseNotification.enabled, isTrue);
      expect(updated.sunriseNotification.playAdhan, isFalse);
      expect(updated.sunriseNotification.mode, PrayerAlertMode.notification);
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
