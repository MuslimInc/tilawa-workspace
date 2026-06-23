import 'package:tilawa/features/home/domain/entities/home_prayer_day_boundaries.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

/// Prayer-period phases for the home hero atmospheric gradient.
enum HomeHeroDayPhase {
  day,
  preDawn,
  dusk,
  night,
}

/// Resolves [TilawaHomeNextPrayerHeroTokens] from local prayer boundaries.
abstract final class HomeHeroGradientResolver {
  const HomeHeroGradientResolver._();

  /// Cross-fade duration at sunrise and Isha boundaries.
  static const Duration blendDuration = Duration(minutes: 45);

  /// Pre-sunrise light window — Fajr-adjacent cool mist into day cream.
  static const Duration preSunriseLightDuration = Duration(minutes: 150);

  /// Night eases into pre-dawn mist before the light window opens.
  static const Duration preSunriseNightEaseDuration = Duration(hours: 1);

  /// Hours before Fajr when the light window may open (whichever is earlier).
  static const Duration preSunriseFajrLead = Duration(hours: 2);

  /// Shorter Maghrib blend to avoid muddy blue→gold RGB midpoints.
  static const Duration maghribBlendDuration = Duration(minutes: 25);

  /// Back-compat alias for tests referencing the old pre-dawn constant.
  static const Duration preDawnBlendDuration = preSunriseLightDuration;

  /// Returns hero tokens for a steady-state [phase].
  static TilawaHomeNextPrayerHeroTokens tokensForPhase(HomeHeroDayPhase phase) {
    return switch (phase) {
      HomeHeroDayPhase.day => TilawaHomeNextPrayerHeroTokens.day(),
      HomeHeroDayPhase.preDawn => TilawaHomeNextPrayerHeroTokens.preDawn(),
      HomeHeroDayPhase.dusk => TilawaHomeNextPrayerHeroTokens.dusk(),
      HomeHeroDayPhase.night => TilawaHomeNextPrayerHeroTokens.night(),
    };
  }

  /// Returns phase-appropriate hero tokens, blending across boundary windows.
  static TilawaHomeNextPrayerHeroTokens resolve({
    required DateTime now,
    HomePrayerDayBoundaries? boundaries,
    HomeHeroDayPhase? debugPhaseOverride,
  }) {
    if (debugPhaseOverride != null) {
      return tokensForPhase(debugPhaseOverride);
    }

    if (boundaries == null) {
      return TilawaHomeNextPrayerHeroTokens.day();
    }

    if (now.isBefore(boundaries.sunrise)) {
      return _resolvePreSunrise(now: now, boundaries: boundaries);
    }

    final TilawaHomeNextPrayerHeroTokens day = tokensForPhase(
      HomeHeroDayPhase.day,
    );
    final TilawaHomeNextPrayerHeroTokens dusk = tokensForPhase(
      HomeHeroDayPhase.dusk,
    );
    final TilawaHomeNextPrayerHeroTokens night = tokensForPhase(
      HomeHeroDayPhase.night,
    );

    final TilawaHomeNextPrayerHeroTokens? maghribBlend = _blendAcross(
      now: now,
      boundary: boundaries.maghrib,
      from: day,
      to: dusk,
      duration: maghribBlendDuration,
    );
    if (maghribBlend != null) {
      return maghribBlend;
    }

    final TilawaHomeNextPrayerHeroTokens? ishaBlend = _blendAcross(
      now: now,
      boundary: boundaries.isha,
      from: dusk,
      to: night,
    );
    if (ishaBlend != null) {
      return ishaBlend;
    }

    return switch (phaseAt(now: now, boundaries: boundaries)) {
      HomeHeroDayPhase.day => day,
      HomeHeroDayPhase.dusk => dusk,
      HomeHeroDayPhase.night => night,
      HomeHeroDayPhase.preDawn => TilawaHomeNextPrayerHeroTokens.preDawn(),
    };
  }

  /// Steady-state phase outside blend windows.
  static HomeHeroDayPhase phaseAt({
    required DateTime now,
    required HomePrayerDayBoundaries boundaries,
  }) {
    if (_isNight(now, boundaries)) {
      return HomeHeroDayPhase.night;
    }
    if (!_isBefore(now, boundaries.maghrib) &&
        _isBefore(now, boundaries.isha)) {
      return HomeHeroDayPhase.dusk;
    }
    return HomeHeroDayPhase.day;
  }

  /// Next prayer boundary after [now] for scheduling hero refreshes.
  static DateTime? nextBoundaryAfter({
    required DateTime now,
    required HomePrayerDayBoundaries boundaries,
  }) {
    final List<DateTime> candidates = <DateTime>[
      boundaries.sunrise,
      boundaries.maghrib,
      boundaries.isha,
      boundaries.sunrise.add(const Duration(days: 1)),
    ]..sort();

    for (final DateTime candidate in candidates) {
      if (candidate.isAfter(now)) {
        return candidate;
      }
    }
    return null;
  }

  /// Whether [now] falls inside a hero gradient blend window.
  static bool isBlendingAt({
    required DateTime now,
    required HomePrayerDayBoundaries boundaries,
  }) {
    return _isInPreSunriseBlend(now, boundaries) ||
        _isInBlendWindow(
          now,
          boundaries.maghrib,
          maghribBlendDuration,
        ) ||
        _isInBlendWindow(now, boundaries.isha, blendDuration);
  }

  /// Delay until the hero gradient should refresh again.
  ///
  /// Returns one minute while blending; otherwise waits until the next
  /// prayer boundary when the gradient is steady-state.
  static Duration? delayUntilNextGradientRefresh({
    required DateTime now,
    required HomePrayerDayBoundaries boundaries,
  }) {
    if (isBlendingAt(now: now, boundaries: boundaries)) {
      return const Duration(minutes: 1);
    }

    final DateTime? nextBoundary = nextBoundaryAfter(
      now: now,
      boundaries: boundaries,
    );
    if (nextBoundary == null) {
      return null;
    }

    final Duration untilBoundary = nextBoundary.difference(now);
    if (untilBoundary <= Duration.zero) {
      return const Duration(minutes: 1);
    }
    return untilBoundary;
  }

  static TilawaHomeNextPrayerHeroTokens _resolvePreSunrise({
    required DateTime now,
    required HomePrayerDayBoundaries boundaries,
  }) {
    final TilawaHomeNextPrayerHeroTokens preDawn =
        TilawaHomeNextPrayerHeroTokens.preDawn();
    final TilawaHomeNextPrayerHeroTokens day =
        TilawaHomeNextPrayerHeroTokens.day();
    final TilawaHomeNextPrayerHeroTokens night =
        TilawaHomeNextPrayerHeroTokens.night();

    final DateTime lightWindowStart = _earlier(
      boundaries.fajr.subtract(preSunriseFajrLead),
      boundaries.sunrise.subtract(preSunriseLightDuration),
    );

    if (!now.isBefore(lightWindowStart)) {
      final Duration window = boundaries.sunrise.difference(lightWindowStart);
      final double t = window <= Duration.zero
          ? 1
          : now.difference(lightWindowStart).inMilliseconds /
                window.inMilliseconds;
      return TilawaHomeNextPrayerHeroTokens.lerp(
        preDawn,
        day,
        t.clamp(0.0, 1.0),
      );
    }

    final DateTime nightEaseStart =
        lightWindowStart.subtract(preSunriseNightEaseDuration);
    if (!now.isBefore(nightEaseStart)) {
      final Duration easeWindow =
          lightWindowStart.difference(nightEaseStart);
      final double t = now.difference(nightEaseStart).inMilliseconds /
          easeWindow.inMilliseconds;
      return TilawaHomeNextPrayerHeroTokens.lerp(
        night,
        preDawn,
        t.clamp(0.0, 1.0),
      );
    }

    return night;
  }

  static DateTime _earlier(DateTime a, DateTime b) {
    return a.isBefore(b) ? a : b;
  }

  static bool _isNight(DateTime now, HomePrayerDayBoundaries boundaries) {
    return !now.isBefore(boundaries.isha) || now.isBefore(boundaries.sunrise);
  }

  static bool _isBefore(DateTime now, DateTime boundary) {
    return now.isBefore(boundary);
  }

  static bool _isInBlendWindow(
    DateTime now,
    DateTime boundary,
    Duration duration,
  ) {
    return !now.isBefore(boundary) && now.isBefore(boundary.add(duration));
  }

  static bool _isInPreSunriseBlend(
    DateTime now,
    HomePrayerDayBoundaries boundaries,
  ) {
    if (!now.isBefore(boundaries.sunrise)) {
      return false;
    }

    final DateTime lightWindowStart = _earlier(
      boundaries.fajr.subtract(preSunriseFajrLead),
      boundaries.sunrise.subtract(preSunriseLightDuration),
    );
    final DateTime nightEaseStart =
        lightWindowStart.subtract(preSunriseNightEaseDuration);
    return !now.isBefore(nightEaseStart);
  }

  static TilawaHomeNextPrayerHeroTokens? _blendAcross({
    required DateTime now,
    required DateTime boundary,
    required TilawaHomeNextPrayerHeroTokens from,
    required TilawaHomeNextPrayerHeroTokens to,
    Duration duration = blendDuration,
  }) {
    if (now.isBefore(boundary)) {
      return null;
    }

    final Duration elapsed = now.difference(boundary);
    if (elapsed >= duration) {
      return null;
    }

    final double t = elapsed.inMilliseconds / duration.inMilliseconds;
    return TilawaHomeNextPrayerHeroTokens.lerp(from, to, t.clamp(0.0, 1.0));
  }
}
