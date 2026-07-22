import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/home/domain/entities/home_prayer_slot.dart';
import 'package:tilawa/features/home/presentation/widgets/home_prayer_schedule_strip.dart';
import 'package:tilawa/features/prayer_times/domain/entities/prayer_time_entity.dart';
import 'package:tilawa/l10n/generated/app_localizations.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

void main() {
  final DateTime now = DateTime(2026, 7, 22, 16, 38);
  final List<HomePrayerSlot> slots = [
    HomePrayerSlot(
      type: PrayerType.fajr,
      time: now.subtract(const Duration(hours: 12)),
      isNext: false,
      hasPassed: true,
    ),
    HomePrayerSlot(
      type: PrayerType.dhuhr,
      time: now.subtract(const Duration(hours: 5)),
      isNext: false,
      hasPassed: true,
    ),
    HomePrayerSlot(
      type: PrayerType.asr,
      time: now,
      isNext: true,
      hasPassed: false,
    ),
    HomePrayerSlot(
      type: PrayerType.maghrib,
      time: now.add(const Duration(hours: 2)),
      isNext: false,
      hasPassed: false,
    ),
    HomePrayerSlot(
      type: PrayerType.isha,
      time: now.add(const Duration(hours: 3, minutes: 30)),
      isNext: false,
      hasPassed: false,
    ),
  ];

  testWidgets('dark active slot uses lifted dark glass with light ink', (
    tester,
  ) async {
    final ThemeData dark = AppTheme.getDarkTheme(
      primaryColor: AppColors.defaultPrimary,
    );
    final ColorScheme scheme = dark.colorScheme;
    final Color expectedActiveFill = Color.alphaBlend(
      Colors.white.withValues(alpha: 0.16),
      scheme.surface,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: dark,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: HomePrayerScheduleStrip(slots: slots),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final DecoratedBox activeCell = tester
        .widgetList<DecoratedBox>(find.byType(DecoratedBox))
        .firstWhere((DecoratedBox box) {
          final Decoration decoration = box.decoration;
          return decoration is BoxDecoration &&
              decoration.color == expectedActiveFill;
        });
    final BoxDecoration decoration = activeCell.decoration as BoxDecoration;

    expect(decoration.color, expectedActiveFill);
    expect(
      ThemeData.estimateBrightnessForColor(expectedActiveFill),
      Brightness.dark,
    );
    expect(
      ThemeData.estimateBrightnessForColor(scheme.onSurface),
      Brightness.light,
    );
    expect(find.textContaining('16:38'), findsWidgets);
  });
}
