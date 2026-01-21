// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'audio.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AudioEntity _$AudioEntityFromJson(Map<String, dynamic> json) => _AudioEntity(
  id: json['id'] as String,
  title: json['title'] as String,
  url: json['url'] as String,
  duration: Duration(microseconds: (json['duration'] as num).toInt()),
  artist: json['artist'] as String?,
  album: json['album'] as String?,
  artUri: json['art_uri'] as String?,
  extras: json['extras'] as Map<String, dynamic>?,
);

Map<String, dynamic> _$AudioEntityToJson(_AudioEntity instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'url': instance.url,
      'duration': instance.duration.inMicroseconds,
      'artist': instance.artist,
      'album': instance.album,
      'art_uri': instance.artUri,
      'extras': instance.extras,
    };

_PlaybackStateEntity _$PlaybackStateEntityFromJson(Map<String, dynamic> json) =>
    _PlaybackStateEntity(
      isPlaying: json['is_playing'] as bool,
      processingState: $enumDecode(
        _$AudioProcessingStateStatusEnumMap,
        json['processing_state'],
      ),
      position: Duration(microseconds: (json['position'] as num).toInt()),
      bufferedPosition: Duration(
        microseconds: (json['buffered_position'] as num).toInt(),
      ),
      duration: Duration(microseconds: (json['duration'] as num).toInt()),
      currentIndex: (json['current_index'] as num).toInt(),
      queue: (json['queue'] as List<dynamic>)
          .map((e) => AudioEntity.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$PlaybackStateEntityToJson(
  _PlaybackStateEntity instance,
) => <String, dynamic>{
  'is_playing': instance.isPlaying,
  'processing_state':
      _$AudioProcessingStateStatusEnumMap[instance.processingState]!,
  'position': instance.position.inMicroseconds,
  'buffered_position': instance.bufferedPosition.inMicroseconds,
  'duration': instance.duration.inMicroseconds,
  'current_index': instance.currentIndex,
  'queue': instance.queue.map((e) => e.toJson()).toList(),
};

const _$AudioProcessingStateStatusEnumMap = {
  AudioProcessingStateStatus.idle: 'idle',
  AudioProcessingStateStatus.loading: 'loading',
  AudioProcessingStateStatus.buffering: 'buffering',
  AudioProcessingStateStatus.ready: 'ready',
  AudioProcessingStateStatus.completed: 'completed',
  AudioProcessingStateStatus.error: 'error',
};
