// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'prayer_settings_entity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PrayerNotificationSettings _$PrayerNotificationSettingsFromJson(
  Map<String, dynamic> json,
) => _PrayerNotificationSettings(
  enabled: json['enabled'] as bool? ?? true,
  minutesBefore: (json['minutesBefore'] as num?)?.toInt() ?? 0,
  playAdhan: json['playAdhan'] as bool? ?? false,
  customAdhanUrl: json['customAdhanUrl'] as String?,
);

Map<String, dynamic> _$PrayerNotificationSettingsToJson(
  _PrayerNotificationSettings instance,
) => <String, dynamic>{
  'enabled': instance.enabled,
  'minutesBefore': instance.minutesBefore,
  'playAdhan': instance.playAdhan,
  'customAdhanUrl': instance.customAdhanUrl,
};

_PrayerSettingsEntity _$PrayerSettingsEntityFromJson(
  Map<String, dynamic> json,
) => _PrayerSettingsEntity(
  calculationMethod:
      $enumDecodeNullable(
        _$CalculationMethodEnumMap,
        json['calculationMethod'],
      ) ??
      CalculationMethod.ummAlQura,
  asrJuristicMethod:
      $enumDecodeNullable(
        _$AsrJuristicMethodEnumMap,
        json['asrJuristicMethod'],
      ) ??
      AsrJuristicMethod.shafii,
  highLatitudeMethod:
      $enumDecodeNullable(
        _$HighLatitudeMethodEnumMap,
        json['highLatitudeMethod'],
      ) ??
      HighLatitudeMethod.none,
  fajrAdjustment: (json['fajrAdjustment'] as num?)?.toInt() ?? 0,
  sunriseAdjustment: (json['sunriseAdjustment'] as num?)?.toInt() ?? 0,
  dhuhrAdjustment: (json['dhuhrAdjustment'] as num?)?.toInt() ?? 0,
  asrAdjustment: (json['asrAdjustment'] as num?)?.toInt() ?? 0,
  maghribAdjustment: (json['maghribAdjustment'] as num?)?.toInt() ?? 0,
  ishaAdjustment: (json['ishaAdjustment'] as num?)?.toInt() ?? 0,
  fajrNotification: json['fajrNotification'] == null
      ? const PrayerNotificationSettings()
      : PrayerNotificationSettings.fromJson(
          json['fajrNotification'] as Map<String, dynamic>,
        ),
  dhuhrNotification: json['dhuhrNotification'] == null
      ? const PrayerNotificationSettings()
      : PrayerNotificationSettings.fromJson(
          json['dhuhrNotification'] as Map<String, dynamic>,
        ),
  asrNotification: json['asrNotification'] == null
      ? const PrayerNotificationSettings()
      : PrayerNotificationSettings.fromJson(
          json['asrNotification'] as Map<String, dynamic>,
        ),
  maghribNotification: json['maghribNotification'] == null
      ? const PrayerNotificationSettings()
      : PrayerNotificationSettings.fromJson(
          json['maghribNotification'] as Map<String, dynamic>,
        ),
  ishaNotification: json['ishaNotification'] == null
      ? const PrayerNotificationSettings()
      : PrayerNotificationSettings.fromJson(
          json['ishaNotification'] as Map<String, dynamic>,
        ),
  use24HourFormat: json['use24HourFormat'] as bool? ?? true,
  showSunrise: json['showSunrise'] as bool? ?? false,
  savedLatitude: (json['savedLatitude'] as num?)?.toDouble(),
  savedLongitude: (json['savedLongitude'] as num?)?.toDouble(),
  savedLocationName: json['savedLocationName'] as String?,
);

Map<String, dynamic> _$PrayerSettingsEntityToJson(
  _PrayerSettingsEntity instance,
) => <String, dynamic>{
  'calculationMethod': _$CalculationMethodEnumMap[instance.calculationMethod]!,
  'asrJuristicMethod': _$AsrJuristicMethodEnumMap[instance.asrJuristicMethod]!,
  'highLatitudeMethod':
      _$HighLatitudeMethodEnumMap[instance.highLatitudeMethod]!,
  'fajrAdjustment': instance.fajrAdjustment,
  'sunriseAdjustment': instance.sunriseAdjustment,
  'dhuhrAdjustment': instance.dhuhrAdjustment,
  'asrAdjustment': instance.asrAdjustment,
  'maghribAdjustment': instance.maghribAdjustment,
  'ishaAdjustment': instance.ishaAdjustment,
  'fajrNotification': instance.fajrNotification.toJson(),
  'dhuhrNotification': instance.dhuhrNotification.toJson(),
  'asrNotification': instance.asrNotification.toJson(),
  'maghribNotification': instance.maghribNotification.toJson(),
  'ishaNotification': instance.ishaNotification.toJson(),
  'use24HourFormat': instance.use24HourFormat,
  'showSunrise': instance.showSunrise,
  'savedLatitude': instance.savedLatitude,
  'savedLongitude': instance.savedLongitude,
  'savedLocationName': instance.savedLocationName,
};

const _$CalculationMethodEnumMap = {
  CalculationMethod.muslimWorldLeague: 'muslimWorldLeague',
  CalculationMethod.egyptian: 'egyptian',
  CalculationMethod.karachi: 'karachi',
  CalculationMethod.ummAlQura: 'ummAlQura',
  CalculationMethod.isna: 'isna',
  CalculationMethod.tehran: 'tehran',
  CalculationMethod.gulf: 'gulf',
  CalculationMethod.kuwait: 'kuwait',
  CalculationMethod.qatar: 'qatar',
  CalculationMethod.singapore: 'singapore',
  CalculationMethod.turkey: 'turkey',
};

const _$AsrJuristicMethodEnumMap = {
  AsrJuristicMethod.shafii: 'shafii',
  AsrJuristicMethod.hanafi: 'hanafi',
};

const _$HighLatitudeMethodEnumMap = {
  HighLatitudeMethod.none: 'none',
  HighLatitudeMethod.middleOfTheNight: 'middleOfTheNight',
  HighLatitudeMethod.oneSeventhOfTheNight: 'oneSeventhOfTheNight',
  HighLatitudeMethod.angleBased: 'angleBased',
};
