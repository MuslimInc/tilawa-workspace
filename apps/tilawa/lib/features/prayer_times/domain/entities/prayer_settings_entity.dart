import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../../l10n/generated/app_localizations.dart';

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

/// Extension for Asr juristic method display names
extension AsrJuristicMethodExtension on AsrJuristicMethod {
  String localize(AppLocalizations l10n) {
    return switch (this) {
      AsrJuristicMethod.shafii => l10n.asrCalculationShafii,
      AsrJuristicMethod.hanafi => l10n.asrCalculationHanafi,
    };
  }
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

/// Mode of prayer alert
enum PrayerAlertMode {
  /// No alert
  none,

  /// Visual notification only
  notification,

  /// Visual notification and Adhan sound
  adhan;

  bool get isNotificationEnabled => this != PrayerAlertMode.none;
  bool get isAdhanEnabled => this == PrayerAlertMode.adhan;

  /// Factory to create from bools, enforcing the dependency logic
  static PrayerAlertMode fromBools({
    required bool enabled,
    required bool playAdhan,
  }) {
    if (!enabled) return PrayerAlertMode.none;
    return playAdhan ? PrayerAlertMode.adhan : PrayerAlertMode.notification;
  }
}

/// Notification settings for a specific prayer
@freezed
abstract class PrayerNotificationSettings with _$PrayerNotificationSettings {
  const factory PrayerNotificationSettings({
    @Default(PrayerAlertMode.adhan) PrayerAlertMode mode,
    @Default(0) int minutesBefore,
    @Default('adhan') String adhanSound,
    String? customAdhanUrl,
  }) = _PrayerNotificationSettings;

  const PrayerNotificationSettings._();

  bool get enabled => mode.isNotificationEnabled;
  bool get playAdhan => mode.isAdhanEnabled;

  factory PrayerNotificationSettings.fromJson(Map<String, dynamic> json) =>
      _$PrayerNotificationSettingsFromJson(json);
}

/// Entity representing all prayer-related settings
@freezed
abstract class PrayerSettingsEntity with _$PrayerSettingsEntity {
  const factory PrayerSettingsEntity({
    @Default(CalculationMethod.egyptian) CalculationMethod calculationMethod,
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
    @Default(PrayerNotificationSettings(mode: PrayerAlertMode.none))
    PrayerNotificationSettings sunriseNotification,
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
    double? lastResolvedLatitude,
    double? lastResolvedLongitude,
    String? lastResolvedLocationName,
  }) = _PrayerSettingsEntity;
  const PrayerSettingsEntity._();

  /// Latitude used by background scheduling recovery.
  ///
  /// Manual saved location wins. If the user has not chosen one, the last
  /// location successfully used to calculate visible prayer times is used.
  double? get effectiveSchedulingLatitude =>
      savedLatitude ?? lastResolvedLatitude;

  /// Longitude used by background scheduling recovery.
  double? get effectiveSchedulingLongitude =>
      savedLongitude ?? lastResolvedLongitude;

  /// Location label paired with [effectiveSchedulingLatitude] and
  /// [effectiveSchedulingLongitude].
  String? get effectiveSchedulingLocationName =>
      savedLocationName ?? lastResolvedLocationName;

  /// Returns true if the settings that affect prayer time calculations have changed
  /// compared to [other].
  bool requiresRecalculation(PrayerSettingsEntity other) {
    return calculationMethod != other.calculationMethod ||
        asrJuristicMethod != other.asrJuristicMethod ||
        highLatitudeMethod != other.highLatitudeMethod ||
        fajrAdjustment != other.fajrAdjustment ||
        sunriseAdjustment != other.sunriseAdjustment ||
        dhuhrAdjustment != other.dhuhrAdjustment ||
        asrAdjustment != other.asrAdjustment ||
        maghribAdjustment != other.maghribAdjustment ||
        ishaAdjustment != other.ishaAdjustment ||
        savedLatitude != other.savedLatitude ||
        savedLongitude != other.savedLongitude;
  }

  /// Check if all prayer notifications are enabled
  bool get allNotificationsEnabled =>
      fajrNotification.enabled &&
      sunriseNotification.enabled &&
      dhuhrNotification.enabled &&
      asrNotification.enabled &&
      maghribNotification.enabled &&
      ishaNotification.enabled;

  /// Check if all prayer adhans are enabled
  bool get allAdhanEnabled =>
      fajrNotification.playAdhan &&
      dhuhrNotification.playAdhan &&
      asrNotification.playAdhan &&
      maghribNotification.playAdhan &&
      ishaNotification.playAdhan;

  /// Copy with all notifications enabled or disabled.
  /// If notifications are disabled, Adhan is also disabled.
  PrayerSettingsEntity copyWithToggledNotifications(bool enabled) {
    // We preserve existing Adhan state if enabling, but the business rule
    // from earlier says "If notifications are disabled, Adhan is also disabled."
    // If enabling, we might want to restore to silent or adhan?
    // Let's use a logic that makes sense:

    PrayerNotificationSettings toggle(PrayerNotificationSettings current) {
      if (!enabled) return current.copyWith(mode: PrayerAlertMode.none);
      // If enabling, if it was none, we go to notification (silent).
      // If it was already notification or adhan, we keep it.
      if (current.mode == PrayerAlertMode.none) {
        return current.copyWith(mode: PrayerAlertMode.notification);
      }
      return current;
    }

    return copyWith(
      fajrNotification: toggle(fajrNotification),
      sunriseNotification: toggle(sunriseNotification),
      dhuhrNotification: toggle(dhuhrNotification),
      asrNotification: toggle(asrNotification),
      maghribNotification: toggle(maghribNotification),
      ishaNotification: toggle(ishaNotification),
    );
  }

  /// Copy with all adhans enabled or disabled.
  /// Adhan can only be enabled if notification is already enabled.
  PrayerSettingsEntity copyWithToggledAdhan(bool enabled) {
    PrayerNotificationSettings toggle(PrayerNotificationSettings current) {
      if (enabled) {
        // Can only enable adhan if notification is enabled
        return current.copyWith(
          mode: current.enabled ? PrayerAlertMode.adhan : current.mode,
        );
      } else {
        // If disabling adhan, we go to notification (silent) if it was adhan
        return current.copyWith(
          mode: current.mode == PrayerAlertMode.adhan
              ? PrayerAlertMode.notification
              : current.mode,
        );
      }
    }

    return copyWith(
      fajrNotification: toggle(fajrNotification),
      sunriseNotification: sunriseNotification,
      dhuhrNotification: toggle(dhuhrNotification),
      asrNotification: toggle(asrNotification),
      maghribNotification: toggle(maghribNotification),
      ishaNotification: toggle(ishaNotification),
    );
  }

  /// Copy with a global adhan sound applied to all prayers that support it.
  PrayerSettingsEntity copyWithGlobalAdhanSound(String sound) {
    PrayerNotificationSettings updateSound(PrayerNotificationSettings current) {
      return current.copyWith(adhanSound: sound);
    }

    return copyWith(
      fajrNotification: updateSound(fajrNotification),
      sunriseNotification: sunriseNotification,
      dhuhrNotification: updateSound(dhuhrNotification),
      asrNotification: updateSound(asrNotification),
      maghribNotification: updateSound(maghribNotification),
      ishaNotification: updateSound(ishaNotification),
    );
  }

  /// Copy with global minutes before for all notifications
  PrayerSettingsEntity copyWithGlobalMinutesBefore(int minutes) {
    return copyWith(
      fajrNotification: fajrNotification.copyWith(minutesBefore: minutes),
      sunriseNotification: sunriseNotification.copyWith(minutesBefore: minutes),
      dhuhrNotification: dhuhrNotification.copyWith(minutesBefore: minutes),
      asrNotification: asrNotification.copyWith(minutesBefore: minutes),
      maghribNotification: maghribNotification.copyWith(minutesBefore: minutes),
      ishaNotification: ishaNotification.copyWith(minutesBefore: minutes),
    );
  }

  /// Copy with global play adhan for all notifications
  PrayerSettingsEntity copyWithGlobalPlayAdhan(bool playAdhan) {
    return copyWithToggledAdhan(playAdhan);
  }

  /// Update a specific prayer alert settings with dependency logic.
  /// If notifications are disabled, Adhan is automatically disabled.
  /// Adhan can only be enabled if notifications are enabled.
  PrayerSettingsEntity updatePrayerAlert(
    String prayerId, {
    bool? notificationEnabled,
    bool? adhanEnabled,
    String? adhanSound,
  }) {
    PrayerNotificationSettings update(PrayerNotificationSettings current) {
      final newEnabled = notificationEnabled ?? current.enabled;
      final newAdhan = adhanEnabled ?? current.playAdhan;
      final newAdhanSound = adhanSound ?? current.adhanSound;

      final canPlayAdhan = prayerId != 'sunrise';
      return current.copyWith(
        adhanSound: newAdhanSound,
        mode: PrayerAlertMode.fromBools(
          enabled: newEnabled,
          playAdhan: canPlayAdhan && newAdhan,
        ),
      );
    }

    return switch (prayerId) {
      'fajr' => copyWith(fajrNotification: update(fajrNotification)),
      'sunrise' => copyWith(sunriseNotification: update(sunriseNotification)),
      'dhuhr' => copyWith(dhuhrNotification: update(dhuhrNotification)),
      'asr' => copyWith(asrNotification: update(asrNotification)),
      'maghrib' => copyWith(maghribNotification: update(maghribNotification)),
      'isha' => copyWith(ishaNotification: update(ishaNotification)),
      _ => this,
    };
  }

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

  String localize(AppLocalizations l10n) {
    return switch (this) {
      CalculationMethod.muslimWorldLeague =>
        l10n.calculationMethodMuslimWorldLeague,
      CalculationMethod.egyptian => l10n.calculationMethodEgyptian,
      CalculationMethod.karachi => l10n.calculationMethodKarachi,
      CalculationMethod.ummAlQura => l10n.calculationMethodUmmAlQura,
      CalculationMethod.isna => l10n.calculationMethodIsna,
      CalculationMethod.tehran => l10n.calculationMethodTehran,
      CalculationMethod.gulf => l10n.calculationMethodGulf,
      CalculationMethod.kuwait => l10n.calculationMethodKuwait,
      CalculationMethod.qatar => l10n.calculationMethodQatar,
      CalculationMethod.singapore => l10n.calculationMethodSingapore,
      CalculationMethod.turkey => l10n.calculationMethodTurkey,
    };
  }
}
