import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/prayer_times/presentation/formatters/prayer_location_label_formatter.dart';
import 'package:tilawa/l10n/generated/app_localizations.dart';

void main() {
  group('PrayerLocationLabelFormatter', () {
    testWidgets('prefers broader non-street segment', (tester) async {
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

      final label = PrayerLocationLabelFormatter.compactLabel(
        locationName: 'Mohye El-Isawy, Al Isaweyah',
        l10n: l10n,
      );

      expect(label, 'Al Isaweyah');
    });

    testWidgets('falls back to unknown for single street-like segment', (
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

      final label = PrayerLocationLabelFormatter.compactLabel(
        locationName: '123 Main Street',
        l10n: l10n,
      );

      expect(label, l10n.unknownLocation);
    });
  });
}
