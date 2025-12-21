// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'surah_entity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SurahEntity _$SurahEntityFromJson(Map<String, dynamic> json) => _SurahEntity(
  mediaItem: MediaItemJson.fromJson(json['mediaItem'] as Map<String, dynamic>),
  isDownloaded: json['isDownloaded'] as bool? ?? false,
  isDownloading: json['isDownloading'] as bool? ?? false,
  downloadProgress: (json['downloadProgress'] as num?)?.toDouble() ?? 0.0,
  downloadId: json['downloadId'] as String?,
);

Map<String, dynamic> _$SurahEntityToJson(_SurahEntity instance) =>
    <String, dynamic>{
      'mediaItem': MediaItemJson.toJson(instance.mediaItem),
      'isDownloaded': instance.isDownloaded,
      'isDownloading': instance.isDownloading,
      'downloadProgress': instance.downloadProgress,
      'downloadId': instance.downloadId,
    };
