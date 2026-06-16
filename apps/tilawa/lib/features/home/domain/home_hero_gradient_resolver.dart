import 'package:tilawa/features/home/domain/entities/home_prayer_day_boundaries.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

/// Prayer-period phases for the home hero atmospheric gradient.
enum HomeHeroDayPhase {
  day,
  dusk,
  night,
}

/// Resolves [TilawaHomeNextPrayerHeroTokens] from local prayer boundaries.
abstract final class HomeHeroGradientResolver {
  const HomeHeroGradientResolver._();

  /// Cross-fade duration at sunrise and Isha boundaries.
  static const Duration blendDuration = Duration(minutes: 45);

  /// Shorter Maghrib blend to avoid muddy blue→gold RGB midpoints.
  static const Duration maghribBlendDuration = Duration(minutes: 25);

  /// Returns hero tokens for a steady-state [phase].
  static TilawaHomeNextPrayerHeroTokens tokensForPhase(HomeHeroDayPhase phase) {
    return switch (phase) {
      HomeHeroDayPhase.day => TilawaHomeNextPrayerHeroTokens.day(),
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

    final TilawaHomeNextPrayerHeroTokens day = tokensForPhase(
      HomeHeroDayPhase.day,
    );
    final TilawaHomeNextPrayerHeroTokens dusk = tokensForPhase(
      HomeHeroDayPhase.dusk,
    );
    final TilawaHomeNextPrayerHeroTokens night = tokensForPhase(
      HomeHeroDayPhase.night,
    );

    final TilawaHomeNextPrayerHeroTokens? sunriseBlend = _blendAcross(
      now: now,
      boundary: boundaries.sunrise,
      from: night,
      to: day,
    );
    if (sunriseBlend != null) {
      return sunriseBlend;
    }

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

  static bool _isNight(DateTime now, HomePrayerDayBoundaries boundaries) {
    return !now.isBefore(boundaries.isha) || now.isBefore(boundaries.sunrise);
  }

  static bool _isBefore(DateTime now, DateTime boundary) {
    return now.isBefore(boundary);
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
