// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bookmark_entity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BookmarkEntity _$BookmarkEntityFromJson(Map<String, dynamic> json) =>
    _BookmarkEntity(
      id: json['id'] as String,
      surahId: (json['surahId'] as num).toInt(),
      surahName: json['surahName'] as String,
      surahNameEn: json['surahNameEn'] as String,
      reciterId: json['reciterId'] as String,
      reciterName: json['reciterName'] as String,
      moshafId: (json['moshafId'] as num).toInt(),
      moshafName: json['moshafName'] as String,
      positionMs: (json['positionMs'] as num).toInt(),
      durationMs: (json['durationMs'] as num).toInt(),
      audioUrl: json['audioUrl'] as String,
      label: json['label'] as String?,
      artworkUrl: json['artworkUrl'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$BookmarkEntityToJson(_BookmarkEntity instance) =>
    <String, dynamic>{
      'id': instance.id,
      'surahId': instance.surahId,
      'surahName': instance.surahName,
      'surahNameEn': instance.surahNameEn,
      'reciterId': instance.reciterId,
      'reciterName': instance.reciterName,
      'moshafId': instance.moshafId,
      'moshafName': instance.moshafName,
      'positionMs': instance.positionMs,
      'durationMs': instance.durationMs,
      'audioUrl': instance.audioUrl,
      'label': instance.label,
      'artworkUrl': instance.artworkUrl,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };
