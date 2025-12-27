// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'download_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_DownloadItem _$DownloadItemFromJson(Map<String, dynamic> json) =>
    _DownloadItem(
      id: json['id'] as String,
      title: json['title'] as String,
      url: json['url'] as String,
      filePath: json['filePath'] as String,
      reciterName: json['reciterName'] as String,
      reciterId: (json['reciterId'] as num?)?.toInt(),
      status: $enumDecode(_$DownloadStatusEnumMap, json['status']),
      progress: (json['progress'] as num).toDouble(),
      fileSize: (json['fileSize'] as num).toInt(),
      downloadedSize: (json['downloadedSize'] as num).toInt(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      completedAt: json['completedAt'] == null
          ? null
          : DateTime.parse(json['completedAt'] as String),
    );

Map<String, dynamic> _$DownloadItemToJson(_DownloadItem instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'url': instance.url,
      'filePath': instance.filePath,
      'reciterName': instance.reciterName,
      'reciterId': instance.reciterId,
      'status': _$DownloadStatusEnumMap[instance.status]!,
      'progress': instance.progress,
      'fileSize': instance.fileSize,
      'downloadedSize': instance.downloadedSize,
      'createdAt': instance.createdAt.toIso8601String(),
      'completedAt': instance.completedAt?.toIso8601String(),
    };

const _$DownloadStatusEnumMap = {
  DownloadStatus.pending: 'pending',
  DownloadStatus.downloading: 'downloading',
  DownloadStatus.completed: 'completed',
  DownloadStatus.failed: 'failed',
  DownloadStatus.paused: 'paused',
  DownloadStatus.cancelled: 'cancelled',
};
