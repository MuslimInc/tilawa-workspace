import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/home/domain/entities/home_prayer_day_boundaries.dart';
import 'package:tilawa/features/home/domain/home_hero_gradient_resolver.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

void main() {
  group('HomeHeroGradientResolver', () {
    late HomePrayerDayBoundaries boundaries;

    setUp(() {
      final DateTime day = DateTime(2026, 6, 15);
      boundaries = HomePrayerDayBoundaries(
        fajr: DateTime(day.year, day.month, day.day, 4),
        sunrise: DateTime(day.year, day.month, day.day, 5, 30),
        maghrib: DateTime(day.year, day.month, day.day, 18, 45),
        isha: DateTime(day.year, day.month, day.day, 20, 10),
      );
    });

    test('returns day palette during daylight hours', () {
      final tokens = HomeHeroGradientResolver.resolve(
        now: DateTime(2026, 6, 15, 12),
        boundaries: boundaries,
      );

      expect(tokens.gradientTopStart, AppColors.homeNextPrayerGradientTop);
      expect(tokens.gradientBottomEnd, AppColors.homeNextPrayerGradientBottom);
    });

    test('returns dusk palette between Maghrib and Isha', () {
      final tokens = HomeHeroGradientResolver.resolve(
        now: DateTime(2026, 6, 15, 19, 30),
        boundaries: boundaries,
      );

      expect(tokens.gradientTopStart, AppColors.homeNextPrayerGradientDuskTop);
      expect(
        tokens.gradientBottomEnd,
        AppColors.homeNextPrayerGradientDuskBottom,
      );
    });

    test('returns night palette after Isha', () {
      final tokens = HomeHeroGradientResolver.resolve(
        now: DateTime(2026, 6, 15, 22),
        boundaries: boundaries,
      );

      expect(tokens.gradientTopStart, AppColors.homeNextPrayerGradientNightTop);
      expect(
        tokens.gradientBottomEnd,
        AppColors.homeNextPrayerGradientNightBottom,
      );
    });

    test('returns night palette before pre-sunrise ease window', () {
      final tokens = HomeHeroGradientResolver.resolve(
        now: DateTime(2026, 6, 15, 1),
        boundaries: boundaries,
      );

      expect(tokens.gradientTopStart, AppColors.homeNextPrayerGradientNightTop);
    });

    test('eases from night toward pre-dawn before the light window', () {
      final TilawaHomeNextPrayerHeroTokens night =
          TilawaHomeNextPrayerHeroTokens.night();
      final TilawaHomeNextPrayerHeroTokens preDawn =
          TilawaHomeNextPrayerHeroTokens.preDawn();
      final DateTime lightWindowStart = boundaries.fajr.subtract(
        HomeHeroGradientResolver.preSunriseFajrLead,
      );
      final DateTime nightEaseStart = lightWindowStart.subtract(
        HomeHeroGradientResolver.preSunriseNightEaseDuration,
      );
      final DateTime now = nightEaseStart.add(const Duration(minutes: 30));
      final TilawaHomeNextPrayerHeroTokens atBlend =
          HomeHeroGradientResolver.resolve(
            now: now,
            boundaries: boundaries,
          );
      final TilawaHomeNextPrayerHeroTokens expected =
          TilawaHomeNextPrayerHeroTokens.lerp(
            night,
            preDawn,
            0.5,
          );

      expect(atBlend.gradientTopStart, expected.gradientTopStart);
      expect(atBlend.gradientBottomEnd, expected.gradientBottomEnd);
    });

    test('blends from pre-dawn toward day during Fajr pre-sunrise window', () {
      final TilawaHomeNextPrayerHeroTokens preDawn =
          TilawaHomeNextPrayerHeroTokens.preDawn();
      final TilawaHomeNextPrayerHeroTokens day =
          TilawaHomeNextPrayerHeroTokens.day();
      final DateTime lightWindowStart = boundaries.fajr.subtract(
        HomeHeroGradientResolver.preSunriseFajrLead,
      );
      final DateTime now = DateTime(2026, 6, 15, 4, 30);
      final TilawaHomeNextPrayerHeroTokens atBlend =
          HomeHeroGradientResolver.resolve(
            now: now,
            boundaries: boundaries,
          );
      final Duration elapsed = now.difference(lightWindowStart);
      final Duration window = boundaries.sunrise.difference(lightWindowStart);
      final TilawaHomeNextPrayerHeroTokens expected =
          TilawaHomeNextPrayerHeroTokens.lerp(
            preDawn,
            day,
            elapsed.inMilliseconds / window.inMilliseconds,
          );

      expect(atBlend.gradientTopStart, expected.gradientTopStart);
      expect(atBlend.gradientBottomEnd, expected.gradientBottomEnd);
    });

    test('returns full day palette at sunrise after pre-sunrise ramp', () {
      final tokens = HomeHeroGradientResolver.resolve(
        now: boundaries.sunrise,
        boundaries: boundaries,
      );

      expect(tokens.gradientTopStart, AppColors.homeNextPrayerGradientTop);
      expect(tokens.gradientBottomEnd, AppColors.homeNextPrayerGradientBottom);
    });

    test('blends from day to dusk across Maghrib with shorter window', () {
      final TilawaHomeNextPrayerHeroTokens day =
          TilawaHomeNextPrayerHeroTokens.day();
      final TilawaHomeNextPrayerHeroTokens dusk =
          TilawaHomeNextPrayerHeroTokens.dusk();
      final TilawaHomeNextPrayerHeroTokens atBlend =
          HomeHeroGradientResolver.resolve(
            now: boundaries.maghrib.add(const Duration(minutes: 10)),
            boundaries: boundaries,
          );
      final TilawaHomeNextPrayerHeroTokens expected =
          TilawaHomeNextPrayerHeroTokens.lerp(
            day,
            dusk,
            10 / HomeHeroGradientResolver.maghribBlendDuration.inMinutes,
          );

      expect(atBlend.gradientTopStart, expected.gradientTopStart);
      expect(atBlend.gradientBottomEnd, expected.gradientBottomEnd);
    });

    test('honors debug phase override when provided', () {
      final tokens = HomeHeroGradientResolver.resolve(
        now: DateTime(2026, 6, 15, 12),
        boundaries: null,
        debugPhaseOverride: HomeHeroDayPhase.preDawn,
      );

      expect(
        tokens.gradientTopStart,
        AppColors.homeNextPrayerGradientPreDawnTop,
      );
    });

    test('isBlendingAt is true inside pre-sunrise window', () {
      expect(
        HomeHeroGradientResolver.isBlendingAt(
          now: DateTime(2026, 6, 15, 4, 30),
          boundaries: boundaries,
        ),
        isTrue,
      );
    });

    test('isBlendingAt is false during steady day phase', () {
      expect(
        HomeHeroGradientResolver.isBlendingAt(
          now: DateTime(2026, 6, 15, 12),
          boundaries: boundaries,
        ),
        isFalse,
      );
    });

    test('delayUntilNextGradientRefresh returns one minute while blending', () {
      expect(
        HomeHeroGradientResolver.delayUntilNextGradientRefresh(
          now: boundaries.maghrib.add(const Duration(minutes: 5)),
          boundaries: boundaries,
        ),
        const Duration(minutes: 1),
      );
    });

    test('delayUntilNextGradientRefresh waits until next boundary', () {
      final DateTime now = DateTime(2026, 6, 15, 12);
      expect(
        HomeHeroGradientResolver.delayUntilNextGradientRefresh(
          now: now,
          boundaries: boundaries,
        ),
        boundaries.maghrib.difference(now),
      );
    });

    test('pre-dawn tokens stay lighter than night tokens', () {
      final preDawn = TilawaHomeNextPrayerHeroTokens.preDawn();
      final night = TilawaHomeNextPrayerHeroTokens.night();

      expect(
        preDawn.gradientTopStart.computeLuminance(),
        greaterThan(night.gradientTopStart.computeLuminance()),
      );
      expect(
        preDawn.gradientBottomEnd.computeLuminance(),
        greaterThan(night.gradientBottomEnd.computeLuminance()),
      );
    });
  });
}
