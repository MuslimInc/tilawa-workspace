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
              l10n = AppLocalizations.of(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      final label = PrayerLocationLabelFormatter.abbreviatedLocationLabel(
        locationName: 'Mohye El-Isawy, Al Isaweyah',
        l10n: l10n,
      );

      expect(label, 'Al Isaweyah');
    });

    testWidgets('returns unknown when all comma-separated segments are empty', (
      tester,
    ) async {
      late AppLocalizations l10n;
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) {
              l10n = AppLocalizations.of(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      final label = PrayerLocationLabelFormatter.abbreviatedLocationLabel(
        locationName: ', ,',
        l10n: l10n,
      );

      expect(label, l10n.unknownLocation);
    });

    testWidgets('returns last segment when every segment looks street-level', (
      tester,
    ) async {
      late AppLocalizations l10n;
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) {
              l10n = AppLocalizations.of(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      final label = PrayerLocationLabelFormatter.abbreviatedLocationLabel(
        locationName: '123 Main Street, 456 Oak Road',
        l10n: l10n,
      );

      expect(label, '456 Oak Road');
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
              l10n = AppLocalizations.of(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      final label = PrayerLocationLabelFormatter.abbreviatedLocationLabel(
        locationName: '123 Main Street',
        l10n: l10n,
      );

      expect(label, l10n.unknownLocation);
    });

    testWidgets('returns single non-street segment as label', (tester) async {
      late AppLocalizations l10n;
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) {
              l10n = AppLocalizations.of(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      final label = PrayerLocationLabelFormatter.abbreviatedLocationLabel(
        locationName: 'العيسوية',
        l10n: l10n,
      );

      expect(label, 'العيسوية');
    });

    testWidgets('returns unknown for null or blank location', (tester) async {
      late AppLocalizations l10n;
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) {
              l10n = AppLocalizations.of(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(
        PrayerLocationLabelFormatter.abbreviatedLocationLabel(
          locationName: null,
          l10n: l10n,
        ),
        l10n.unknownLocation,
      );
      expect(
        PrayerLocationLabelFormatter.abbreviatedLocationLabel(
          locationName: '   ',
          l10n: l10n,
        ),
        l10n.unknownLocation,
      );
    });
  });
}
