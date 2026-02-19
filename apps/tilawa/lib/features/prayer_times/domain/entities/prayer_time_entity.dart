import 'package:freezed_annotation/freezed_annotation.dart';

part 'prayer_time_entity.freezed.dart';
part 'prayer_time_entity.g.dart';

/// Enum representing the five daily prayers plus sunrise, midnight, and last third
enum PrayerType {
  fajr,
  sunrise,
  dhuhr,
  asr,
  maghrib,
  isha,
  midnight,
  lastThird,
}

/// Entity representing prayer times for a specific day
@freezed
abstract class PrayerTimeEntity with _$PrayerTimeEntity {
  const factory PrayerTimeEntity({
    required DateTime date,
    required DateTime fajr,
    required DateTime sunrise,
    required DateTime dhuhr,
    required DateTime asr,
    required DateTime maghrib,
    required DateTime isha,
    required DateTime midnight,
    required DateTime lastThird,
    String? timezone,
    String? locationName,
    double? latitude,
    double? longitude,
  }) = _PrayerTimeEntity;
  const PrayerTimeEntity._();

  factory PrayerTimeEntity.fromJson(Map<String, dynamic> json) =>
      _$PrayerTimeEntityFromJson(json);

  /// Get all prayer times as a list
  List<PrayerTimeItem> get allPrayers => [
    PrayerTimeItem(type: PrayerType.fajr, time: fajr),
    PrayerTimeItem(type: PrayerType.sunrise, time: sunrise),
    PrayerTimeItem(type: PrayerType.dhuhr, time: dhuhr),
    PrayerTimeItem(type: PrayerType.asr, time: asr),
    PrayerTimeItem(type: PrayerType.maghrib, time: maghrib),
    PrayerTimeItem(type: PrayerType.isha, time: isha),
    PrayerTimeItem(type: PrayerType.midnight, time: midnight),
    PrayerTimeItem(type: PrayerType.lastThird, time: lastThird),
  ];

  /// Get the main prayer times (excluding midnight and last third)
  List<PrayerTimeItem> get mainPrayers => [
    PrayerTimeItem(type: PrayerType.fajr, time: fajr),
    PrayerTimeItem(type: PrayerType.sunrise, time: sunrise),
    PrayerTimeItem(type: PrayerType.dhuhr, time: dhuhr),
    PrayerTimeItem(type: PrayerType.asr, time: asr),
    PrayerTimeItem(type: PrayerType.maghrib, time: maghrib),
    PrayerTimeItem(type: PrayerType.isha, time: isha),
  ];

  /// Get the current or next MAIN prayer based on the current time
  PrayerTimeItem? getCurrentOrNextPrayer() {
    final now = DateTime.now();

    for (final PrayerTimeItem prayer in mainPrayers) {
      if (prayer.time.isAfter(now)) {
        return prayer;
      }
    }

    // All main prayers have passed, return Fajr of next day
    return PrayerTimeItem(
      type: PrayerType.fajr,
      time: fajr.add(const Duration(days: 1)),
    );
  }

  /// Get the previous prayer that has passed
  PrayerTimeItem? getPreviousPrayer() {
    final now = DateTime.now();
    PrayerTimeItem? previous;

    for (final PrayerTimeItem prayer in mainPrayers) {
      if (prayer.time.isBefore(now)) {
        previous = prayer;
      } else {
        break;
      }
    }

    return previous;
  }

  /// Get time remaining until next prayer
  Duration? getTimeUntilNextPrayer() {
    final PrayerTimeItem? next = getCurrentOrNextPrayer();
    if (next == null) {
      return null;
    }

    final now = DateTime.now();
    return next.time.difference(now);
  }

  /// Check if a specific prayer time has passed
  bool hasPrayerPassed(PrayerType type) {
    final now = DateTime.now();
    final DateTime prayerTime = _getPrayerTime(type);
    return prayerTime.isBefore(now);
  }

  DateTime _getPrayerTime(PrayerType type) {
    switch (type) {
      case PrayerType.fajr:
        return fajr;
      case PrayerType.sunrise:
        return sunrise;
      case PrayerType.dhuhr:
        return dhuhr;
      case PrayerType.asr:
        return asr;
      case PrayerType.maghrib:
        return maghrib;
      case PrayerType.isha:
        return isha;
      case PrayerType.midnight:
        return midnight;
      case PrayerType.lastThird:
        return lastThird;
    }
  }
}

/// A simple class to hold prayer type and time together
class PrayerTimeItem {
  const PrayerTimeItem({required this.type, required this.time});

  final PrayerType type;
  final DateTime time;

  String get formattedTime {
    final String hour = time.hour.toString().padLeft(2, '0');
    final String minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String getFormattedTime12Hour({bool isArabic = false}) {
    final int hour12 = time.hour > 12 ? time.hour - 12 : time.hour;
    final period = time.hour >= 12
        ? (isArabic ? 'م' : 'PM')
        : (isArabic ? 'ص' : 'AM');
    final String minute = time.minute.toString().padLeft(2, '0');
    return '${hour12 == 0 ? 12 : hour12}:$minute $period';
  }
}

/// Extension to get display name for prayer type
extension PrayerTypeExtension on PrayerType {
  String get displayName {
    switch (this) {
      case PrayerType.fajr:
        return 'Fajr';
      case PrayerType.sunrise:
        return 'Sunrise';
      case PrayerType.dhuhr:
        return 'Dhuhr';
      case PrayerType.asr:
        return 'Asr';
      case PrayerType.maghrib:
        return 'Maghrib';
      case PrayerType.isha:
        return 'Isha';
      case PrayerType.midnight:
        return 'Midnight';
      case PrayerType.lastThird:
        return 'Last Third';
    }
  }

  String get displayNameAr {
    switch (this) {
      case PrayerType.fajr:
        return 'الفجر';
      case PrayerType.sunrise:
        return 'الشروق';
      case PrayerType.dhuhr:
        return 'الظهر';
      case PrayerType.asr:
        return 'العصر';
      case PrayerType.maghrib:
        return 'المغرب';
      case PrayerType.isha:
        return 'العشاء';
      case PrayerType.midnight:
        return 'منتصف الليل';
      case PrayerType.lastThird:
        return 'الثلث الأخير';
    }
  }

  String get iconName {
    switch (this) {
      case PrayerType.fajr:
        return 'fajr';
      case PrayerType.sunrise:
        return 'sunrise';
      case PrayerType.dhuhr:
        return 'dhuhr';
      case PrayerType.asr:
        return 'asr';
      case PrayerType.maghrib:
        return 'maghrib';
      case PrayerType.isha:
        return 'isha';
      case PrayerType.midnight:
        return 'midnight';
      case PrayerType.lastThird:
        return 'lastThird';
    }
  }
}
