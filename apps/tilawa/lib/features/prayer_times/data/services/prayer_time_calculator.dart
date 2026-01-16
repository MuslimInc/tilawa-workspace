import 'dart:math' as math;

import '../../domain/entities/entities.dart';

/// Service to calculate prayer times based on astronomical calculations
class PrayerTimeCalculator {
  /// Calculate prayer times for a specific date and location
  PrayerTimeEntity calculatePrayerTimes({
    required double latitude,
    required double longitude,
    required DateTime date,
    required PrayerSettingsEntity settings,
  }) {
    final CalculationParams params = _getCalculationParams(settings);

    // Calculate Julian date
    final double jd = _julianDate(date.year, date.month, date.day);

    // Calculate sun position
    final double declination = _sunDeclination(jd);
    final double equationOfTime = _equationOfTime(jd);

    // Calculate prayer times
    final double dhuhrTime =
        12 + _getTimeZoneOffset(date) - longitude / 15 - equationOfTime / 60;

    final double fajrTime =
        dhuhrTime -
        _timeDifference(latitude, declination, params.fajrAngle) / 15;
    final double sunriseTime =
        dhuhrTime -
        _timeDifference(
              latitude,
              declination,
              0.833 + 0.0347 * math.sqrt(_getElevation()),
            ) /
            15;
    final double asrTime =
        dhuhrTime +
        _asrTime(latitude, declination, settings.asrJuristicMethod) / 15;
    final double maghribTime =
        dhuhrTime +
        _timeDifference(
              latitude,
              declination,
              0.833 + 0.0347 * math.sqrt(_getElevation()),
            ) /
            15;

    // Calculate Isha time - handle methods that use minutes after Maghrib
    late final double ishaTime;
    if (params.ishaMinutes != null && params.ishaMinutes! > 0) {
      // For methods like Umm Al-Qura, Gulf, Qatar: Isha is X minutes after Maghrib
      ishaTime = maghribTime + params.ishaMinutes! / 60;
    } else {
      // For methods using angle calculation
      ishaTime =
          dhuhrTime +
          _timeDifference(latitude, declination, params.ishaAngle) / 15;
    }

    // Apply adjustments
    final DateTime fajr = _timeToDateTime(
      date,
      fajrTime + settings.fajrAdjustment / 60,
    );
    final DateTime sunrise = _timeToDateTime(
      date,
      sunriseTime + settings.sunriseAdjustment / 60,
    );
    final DateTime dhuhr = _timeToDateTime(
      date,
      dhuhrTime + settings.dhuhrAdjustment / 60,
    );
    final DateTime asr = _timeToDateTime(
      date,
      asrTime + settings.asrAdjustment / 60,
    );
    final DateTime maghrib = _timeToDateTime(
      date,
      maghribTime + settings.maghribAdjustment / 60,
    );
    final DateTime isha = _timeToDateTime(
      date,
      ishaTime + settings.ishaAdjustment / 60,
    );

    return PrayerTimeEntity(
      date: date,
      fajr: fajr,
      sunrise: sunrise,
      dhuhr: dhuhr,
      asr: asr,
      maghrib: maghrib,
      isha: isha,
      latitude: latitude,
      longitude: longitude,
    );
  }

  /// Calculate prayer times for a date range
  List<PrayerTimeEntity> calculatePrayerTimesForRange({
    required double latitude,
    required double longitude,
    required DateTime startDate,
    required DateTime endDate,
    required PrayerSettingsEntity settings,
  }) {
    final List<PrayerTimeEntity> prayerTimes = [];
    var currentDate = startDate;

    while (currentDate.isBefore(endDate) ||
        currentDate.isAtSameMomentAs(endDate)) {
      prayerTimes.add(
        calculatePrayerTimes(
          latitude: latitude,
          longitude: longitude,
          date: currentDate,
          settings: settings,
        ),
      );
      currentDate = currentDate.add(const Duration(days: 1));
    }

    return prayerTimes;
  }

  /// Get calculation parameters based on method
  CalculationParams _getCalculationParams(PrayerSettingsEntity settings) {
    switch (settings.calculationMethod) {
      case CalculationMethod.muslimWorldLeague:
        return const CalculationParams(fajrAngle: 18.0, ishaAngle: 17.0);
      case CalculationMethod.egyptian:
        return const CalculationParams(fajrAngle: 19.5, ishaAngle: 17.5);
      case CalculationMethod.karachi:
        return const CalculationParams(fajrAngle: 18.0, ishaAngle: 18.0);
      case CalculationMethod.ummAlQura:
        return const CalculationParams(
          fajrAngle: 18.5,
          ishaAngle: 0,
          ishaMinutes: 90,
        );
      case CalculationMethod.isna:
        return const CalculationParams(fajrAngle: 15.0, ishaAngle: 15.0);
      case CalculationMethod.tehran:
        return const CalculationParams(fajrAngle: 17.7, ishaAngle: 14.0);
      case CalculationMethod.gulf:
        return const CalculationParams(
          fajrAngle: 19.5,
          ishaAngle: 0,
          ishaMinutes: 90,
        );
      case CalculationMethod.kuwait:
        return const CalculationParams(fajrAngle: 18.0, ishaAngle: 17.5);
      case CalculationMethod.qatar:
        return const CalculationParams(
          fajrAngle: 18.0,
          ishaAngle: 0,
          ishaMinutes: 90,
        );
      case CalculationMethod.singapore:
        return const CalculationParams(fajrAngle: 20.0, ishaAngle: 18.0);
      case CalculationMethod.turkey:
        return const CalculationParams(fajrAngle: 18.0, ishaAngle: 17.0);
    }
  }

  /// Calculate Julian Date
  double _julianDate(int year, int month, int day) {
    if (month <= 2) {
      year -= 1;
      month += 12;
    }
    final double a = (year / 100).floorToDouble();
    final double b = 2 - a + (a / 4).floorToDouble();
    return (365.25 * (year + 4716)).floorToDouble() +
        (30.6001 * (month + 1)).floorToDouble() +
        day +
        b -
        1524.5;
  }

  /// Calculate sun declination
  double _sunDeclination(double jd) {
    final double d = jd - 2451545.0;
    final double g = _fixAngle(357.529 + 0.98560028 * d);
    final double q = _fixAngle(280.459 + 0.98564736 * d);
    final double l = _fixAngle(q + 1.915 * _sin(g) + 0.020 * _sin(2 * g));
    final double e = 23.439 - 0.00000036 * d;
    // Right ascension calculated but only declination needed here
    return _arcsin(_sin(e) * _sin(l));
  }

  /// Calculate equation of time
  double _equationOfTime(double jd) {
    final double d = jd - 2451545.0;
    final double g = _fixAngle(357.529 + 0.98560028 * d);
    final double q = _fixAngle(280.459 + 0.98564736 * d);
    final double l = _fixAngle(q + 1.915 * _sin(g) + 0.020 * _sin(2 * g));
    final double e = 23.439 - 0.00000036 * d;
    final double ra = _arctan2(_cos(e) * _sin(l), _cos(l)) / 15.0;
    return (q / 15.0 - _fixHour(ra)) * 60;
  }

  /// Calculate time difference based on angle
  double _timeDifference(double lat, double decl, double angle) {
    final double part1 = -_sin(angle) - _sin(lat) * _sin(decl);
    final double part2 = _cos(lat) * _cos(decl);
    return _arccos(part1 / part2);
  }

  /// Calculate Asr time based on juristic method
  double _asrTime(double lat, double decl, AsrJuristicMethod method) {
    final factor = method == AsrJuristicMethod.hanafi ? 2.0 : 1.0;
    final double angle = _arccot(factor + _tan((lat - decl).abs()));
    return _timeDifference(lat, decl, -angle);
  }

  /// Convert decimal time to DateTime
  DateTime _timeToDateTime(DateTime date, double time) {
    final double fixedTime = _fixHour(time);
    final int hours = fixedTime.floor();
    final int minutes = ((fixedTime - hours) * 60).floor();
    final int seconds = ((((fixedTime - hours) * 60) - minutes) * 60).floor();

    return DateTime(
      date.year,
      date.month,
      date.day,
      hours.clamp(0, 23),
      minutes.clamp(0, 59),
      seconds.clamp(0, 59),
    );
  }

  /// Get timezone offset for a date
  double _getTimeZoneOffset(DateTime date) {
    return date.timeZoneOffset.inMinutes / 60.0;
  }

  /// Get elevation (default to 0 for now)
  double _getElevation() => 0;

  // Trigonometric helper functions
  double _sin(double d) => math.sin(_degreesToRadians(d));
  double _cos(double d) => math.cos(_degreesToRadians(d));
  double _tan(double d) => math.tan(_degreesToRadians(d));

  double _arcsin(double x) => _radiansToDegrees(math.asin(x));
  double _arccos(double x) => _radiansToDegrees(math.acos(x));
  double _arctan2(double y, double x) => _radiansToDegrees(math.atan2(y, x));
  double _arccot(double x) => _radiansToDegrees(math.atan(1 / x));

  double _degreesToRadians(double d) => d * math.pi / 180.0;
  double _radiansToDegrees(double r) => r * 180.0 / math.pi;

  double _fixAngle(double a) => a - 360.0 * (a / 360.0).floor();
  double _fixHour(double a) => a - 24.0 * (a / 24.0).floor();
}

/// Parameters for prayer time calculation
class CalculationParams {
  const CalculationParams({
    required this.fajrAngle,
    required this.ishaAngle,
    this.ishaMinutes,
  });

  final double fajrAngle;
  final double ishaAngle;
  final int? ishaMinutes;
}
