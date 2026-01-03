// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'audio_player_bloc.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AudioPlayerState _$AudioPlayerStateFromJson(Map<String, dynamic> json) =>
    _AudioPlayerState(
      status: $enumDecode(_$AudioPlayerStatusEnumMap, json['status']),
      currentAudio: json['currentAudio'] == null
          ? null
          : AudioEntity.fromJson(json['currentAudio'] as Map<String, dynamic>),
      playbackState: json['playbackState'] == null
          ? null
          : PlaybackStateEntity.fromJson(
              json['playbackState'] as Map<String, dynamic>,
            ),
      positionData: json['positionData'] == null
          ? null
          : PositionData.fromJson(json['positionData'] as Map<String, dynamic>),
      volume: (json['volume'] as num?)?.toDouble() ?? 1.0,
      speed: (json['speed'] as num?)?.toDouble() ?? 1.0,
      repeatMode:
          $enumDecodeNullable(_$AudioRepeatModeEnumMap, json['repeatMode']) ??
          AudioRepeatMode.none,
      shuffleMode:
          $enumDecodeNullable(_$AudioShuffleModeEnumMap, json['shuffleMode']) ??
          AudioShuffleMode.none,
      sleepTimerTargetTime: json['sleepTimerTargetTime'] == null
          ? null
          : DateTime.parse(json['sleepTimerTargetTime'] as String),
      lastSleepTimerDuration: json['lastSleepTimerDuration'] == null
          ? null
          : Duration(
              microseconds: (json['lastSleepTimerDuration'] as num).toInt(),
            ),
      dismissedAudioId: json['dismissedAudioId'] as String?,
    );

Map<String, dynamic> _$AudioPlayerStateToJson(_AudioPlayerState instance) =>
    <String, dynamic>{
      'status': _$AudioPlayerStatusEnumMap[instance.status]!,
      'currentAudio': instance.currentAudio?.toJson(),
      'playbackState': instance.playbackState?.toJson(),
      'positionData': instance.positionData?.toJson(),
      'volume': instance.volume,
      'speed': instance.speed,
      'repeatMode': _$AudioRepeatModeEnumMap[instance.repeatMode]!,
      'shuffleMode': _$AudioShuffleModeEnumMap[instance.shuffleMode]!,
      'sleepTimerTargetTime': instance.sleepTimerTargetTime?.toIso8601String(),
      'lastSleepTimerDuration': instance.lastSleepTimerDuration?.inMicroseconds,
      'dismissedAudioId': instance.dismissedAudioId,
    };

const _$AudioPlayerStatusEnumMap = {
  AudioPlayerStatus.initial: 'initial',
  AudioPlayerStatus.loading: 'loading',
  AudioPlayerStatus.success: 'success',
};

const _$AudioRepeatModeEnumMap = {
  AudioRepeatMode.none: 'none',
  AudioRepeatMode.one: 'one',
  AudioRepeatMode.all: 'all',
};

const _$AudioShuffleModeEnumMap = {
  AudioShuffleMode.none: 'none',
  AudioShuffleMode.all: 'all',
};
