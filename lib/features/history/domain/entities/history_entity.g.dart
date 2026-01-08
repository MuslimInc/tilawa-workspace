// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'history_entity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_HistoryEntity _$HistoryEntityFromJson(Map<String, dynamic> json) =>
    _HistoryEntity(
      id: json['id'] as String,
      surahId: (json['surahId'] as num).toInt(),
      surahName: json['surahName'] as String,
      surahNameEn: json['surahNameEn'] as String,
      reciterId: json['reciterId'] as String,
      reciterName: json['reciterName'] as String,
      moshafId: (json['moshafId'] as num).toInt(),
      moshafName: json['moshafName'] as String,
      lastPositionMs: (json['lastPositionMs'] as num).toInt(),
      durationMs: (json['durationMs'] as num).toInt(),
      audioUrl: json['audioUrl'] as String,
      artworkUrl: json['artworkUrl'] as String?,
      playedAt: DateTime.parse(json['playedAt'] as String),
      completed: json['completed'] as bool? ?? false,
      playCount: (json['playCount'] as num?)?.toInt() ?? 1,
    );

Map<String, dynamic> _$HistoryEntityToJson(_HistoryEntity instance) =>
    <String, dynamic>{
      'id': instance.id,
      'surahId': instance.surahId,
      'surahName': instance.surahName,
      'surahNameEn': instance.surahNameEn,
      'reciterId': instance.reciterId,
      'reciterName': instance.reciterName,
      'moshafId': instance.moshafId,
      'moshafName': instance.moshafName,
      'lastPositionMs': instance.lastPositionMs,
      'durationMs': instance.durationMs,
      'audioUrl': instance.audioUrl,
      'artworkUrl': instance.artworkUrl,
      'playedAt': instance.playedAt.toIso8601String(),
      'completed': instance.completed,
      'playCount': instance.playCount,
    };
