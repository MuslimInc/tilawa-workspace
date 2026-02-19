import 'package:freezed_annotation/freezed_annotation.dart';

import 'prayer_time_entity.dart';

part 'prayer_settings_entity.freezed.dart';
part 'prayer_settings_entity.g.dart';

/// Calculation methods for prayer times
enum CalculationMethod {
  /// Muslim World League
  muslimWorldLeague,

  /// Egyptian General Authority of Survey
  egyptian,

  /// University of Islamic Sciences, Karachi
  karachi,

  /// Umm al-Qura University, Makkah
  ummAlQura,

  /// Islamic Society of North America
  isna,

  /// Tehran, Institute of Geophysics
  tehran,

  /// Gulf Region
  gulf,

  /// Kuwait
  kuwait,

  /// Qatar
  qatar,

  /// Singapore, MUIS
  singapore,

  /// Turkey, Diyanet
  turkey,
}

/// Madhab (juristic school) for Asr calculation
enum AsrJuristicMethod {
  /// Standard method (Shafi, Hanbali, Maliki) - shadow length equals object height
  shafii,

  /// Hanafi method - shadow length is twice the object height
  hanafi,
}

/// High latitude adjustment method
enum HighLatitudeMethod {
  /// No adjustment
  none,

  /// Middle of the night method
  middleOfTheNight,

  /// One-seventh of the night method
  oneSeventhOfTheNight,

  /// Angle-based method
  angleBased,
}

/// Notification settings for a specific prayer
@freezed
abstract class PrayerNotificationSettings with _$PrayerNotificationSettings {
  const factory PrayerNotificationSettings({
    @Default(true) bool enabled,
    @Default(0) int minutesBefore,
    @Default(false) bool playAdhan,
    String? customAdhanUrl,
  }) = _PrayerNotificationSettings;

  factory PrayerNotificationSettings.fromJson(Map<String, dynamic> json) =>
      _$PrayerNotificationSettingsFromJson(json);
}

/// Entity representing all prayer-related settings
@freezed
abstract class PrayerSettingsEntity with _$PrayerSettingsEntity {
  const factory PrayerSettingsEntity({
    @Default(CalculationMethod.ummAlQura) CalculationMethod calculationMethod,
    @Default(AsrJuristicMethod.shafii) AsrJuristicMethod asrJuristicMethod,
    @Default(HighLatitudeMethod.none) HighLatitudeMethod highLatitudeMethod,
    @Default(0) int fajrAdjustment,
    @Default(0) int sunriseAdjustment,
    @Default(0) int dhuhrAdjustment,
    @Default(0) int asrAdjustment,
    @Default(0) int maghribAdjustment,
    @Default(0) int ishaAdjustment,
    @Default(PrayerNotificationSettings())
    PrayerNotificationSettings fajrNotification,
    @Default(PrayerNotificationSettings())
    PrayerNotificationSettings dhuhrNotification,
    @Default(PrayerNotificationSettings())
    PrayerNotificationSettings asrNotification,
    @Default(PrayerNotificationSettings())
    PrayerNotificationSettings maghribNotification,
    @Default(PrayerNotificationSettings())
    PrayerNotificationSettings ishaNotification,
    @Default(false) bool use24HourFormat,
    @Default(false) bool showSunrise,
    double? savedLatitude,
    double? savedLongitude,
    String? savedLocationName,
  }) = _PrayerSettingsEntity;
  const PrayerSettingsEntity._();

  factory PrayerSettingsEntity.fromJson(Map<String, dynamic> json) =>
      _$PrayerSettingsEntityFromJson(json);

  /// Get adjustment in minutes for a specific prayer type
  int getAdjustmentFor(PrayerType prayerType) {
    switch (prayerType) {
      case PrayerType.fajr:
        return fajrAdjustment;
      case PrayerType.sunrise:
        return sunriseAdjustment;
      case PrayerType.dhuhr:
        return dhuhrAdjustment;
      case PrayerType.asr:
        return asrAdjustment;
      case PrayerType.maghrib:
        return maghribAdjustment;
      case PrayerType.isha:
        return ishaAdjustment;
      case PrayerType.midnight:
      case PrayerType.lastThird:
        return 0;
    }
  }

  /// Get default calculation method for a specific country code (ISO 3166-1 alpha-2)
  static CalculationMethod? defaultForCountry(String? countryCode) {
    if (countryCode == null) return null;

    switch (countryCode.toUpperCase()) {
      case 'EG': // Egypt
        return CalculationMethod.egyptian;
      case 'PK': // Pakistan
        return CalculationMethod.karachi;
      case 'TR': // Turkey
        return CalculationMethod.turkey;
      case 'SG': // Singapore
        return CalculationMethod.singapore;
      case 'KW': // Kuwait
        return CalculationMethod.kuwait;
      case 'QA': // Qatar
        return CalculationMethod.qatar;
      case 'AE': // United Arab Emirates
      case 'BH': // Bahrain
      case 'OM': // Oman
        return CalculationMethod.gulf;
      case 'IR': // Iran
        return CalculationMethod.tehran;
      case 'US': // United States
      case 'CA': // Canada
      case 'GB': // United Kingdom
        return CalculationMethod.isna;
      case 'SA': // Saudi Arabia
        return CalculationMethod.ummAlQura;
      default:
        return null;
    }
  }
}

/// Extension for calculation method display names
extension CalculationMethodExtension on CalculationMethod {
  String get displayName {
    return switch (this) {
      CalculationMethod.muslimWorldLeague => 'Muslim World League',
      CalculationMethod.egyptian => 'Egyptian General Authority',
      CalculationMethod.karachi => 'University of Karachi',
      CalculationMethod.ummAlQura => 'Umm Al-Qura, Makkah',
      CalculationMethod.isna => 'ISNA (North America)',
      CalculationMethod.tehran => 'Tehran',
      CalculationMethod.gulf => 'Gulf Region',
      CalculationMethod.kuwait => 'Kuwait',
      CalculationMethod.qatar => 'Qatar',
      CalculationMethod.singapore => 'Singapore (MUIS)',
      CalculationMethod.turkey => 'Turkey (Diyanet)',
    };
  }

  String get displayNameAr {
    return switch (this) {
      CalculationMethod.muslimWorldLeague => 'رابطة العالم الإسلامي',
      CalculationMethod.egyptian => 'الهيئة المصرية العامة',
      CalculationMethod.karachi => 'جامعة كراتشي',
      CalculationMethod.ummAlQura => 'أم القرى، مكة',
      CalculationMethod.isna => 'الجمعية الإسلامية لأمريكا الشمالية',
      CalculationMethod.tehran => 'طهران',
      CalculationMethod.gulf => 'منطقة الخليج',
      CalculationMethod.kuwait => 'الكويت',
      CalculationMethod.qatar => 'قطر',
      CalculationMethod.singapore => 'سنغافورة',
      CalculationMethod.turkey => 'تركيا (الديانة)',
    };
  }
}
