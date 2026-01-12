// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'prayer_time_entity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PrayerTimeEntity _$PrayerTimeEntityFromJson(Map<String, dynamic> json) =>
    _PrayerTimeEntity(
      date: DateTime.parse(json['date'] as String),
      fajr: DateTime.parse(json['fajr'] as String),
      sunrise: DateTime.parse(json['sunrise'] as String),
      dhuhr: DateTime.parse(json['dhuhr'] as String),
      asr: DateTime.parse(json['asr'] as String),
      maghrib: DateTime.parse(json['maghrib'] as String),
      isha: DateTime.parse(json['isha'] as String),
      timezone: json['timezone'] as String?,
      locationName: json['locationName'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$PrayerTimeEntityToJson(_PrayerTimeEntity instance) =>
    <String, dynamic>{
      'date': instance.date.toIso8601String(),
      'fajr': instance.fajr.toIso8601String(),
      'sunrise': instance.sunrise.toIso8601String(),
      'dhuhr': instance.dhuhr.toIso8601String(),
      'asr': instance.asr.toIso8601String(),
      'maghrib': instance.maghrib.toIso8601String(),
      'isha': instance.isha.toIso8601String(),
      'timezone': instance.timezone,
      'locationName': instance.locationName,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
    };
