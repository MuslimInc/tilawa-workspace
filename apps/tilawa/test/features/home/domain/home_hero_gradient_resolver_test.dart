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

    test('returns night palette before sunrise', () {
      final tokens = HomeHeroGradientResolver.resolve(
        now: DateTime(2026, 6, 15, 4, 30),
        boundaries: boundaries,
      );

      expect(tokens.gradientTopStart, AppColors.homeNextPrayerGradientNightTop);
    });

    test('blends from night to day across sunrise', () {
      final TilawaHomeNextPrayerHeroTokens night =
          TilawaHomeNextPrayerHeroTokens.night();
      final TilawaHomeNextPrayerHeroTokens day =
          TilawaHomeNextPrayerHeroTokens.day();
      final TilawaHomeNextPrayerHeroTokens atQuarterBlend =
          HomeHeroGradientResolver.resolve(
            now: boundaries.sunrise.add(const Duration(minutes: 11)),
            boundaries: boundaries,
          );
      final TilawaHomeNextPrayerHeroTokens expected =
          TilawaHomeNextPrayerHeroTokens.lerp(night, day, 11 / 45);

      expect(
        atQuarterBlend.gradientTopStart,
        expected.gradientTopStart,
      );
      expect(
        atQuarterBlend.gradientBottomEnd,
        expected.gradientBottomEnd,
      );
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
        debugPhaseOverride: HomeHeroDayPhase.night,
      );

      expect(tokens.gradientTopStart, AppColors.homeNextPrayerGradientNightTop);
    });

    test('isBlendingAt is true inside sunrise blend window', () {
      expect(
        HomeHeroGradientResolver.isBlendingAt(
          now: boundaries.sunrise.add(const Duration(minutes: 10)),
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
  });
}
