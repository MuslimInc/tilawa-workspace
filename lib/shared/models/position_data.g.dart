// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'position_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PositionData _$PositionDataFromJson(Map<String, dynamic> json) =>
    _PositionData(
      position: Duration(microseconds: (json['position'] as num).toInt()),
      bufferedPosition: Duration(
        microseconds: (json['bufferedPosition'] as num).toInt(),
      ),
      duration: Duration(microseconds: (json['duration'] as num).toInt()),
    );

Map<String, dynamic> _$PositionDataToJson(_PositionData instance) =>
    <String, dynamic>{
      'position': instance.position.inMicroseconds,
      'bufferedPosition': instance.bufferedPosition.inMicroseconds,
      'duration': instance.duration.inMicroseconds,
    };
