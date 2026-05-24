import 'package:freezed_annotation/freezed_annotation.dart';

part 'audio.freezed.dart';
part 'audio.g.dart';

@freezed
abstract class AudioEntity with _$AudioEntity {
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory AudioEntity({
    required String id,
    required String title,
    required String url,
    required Duration duration,
    String? artist,
    String? album,
    String? artUri,
    Map<String, dynamic>? extras,
  }) = _AudioEntity;

  const AudioEntity._();

  factory AudioEntity.fromJson(Map<String, dynamic> json) =>
      _$AudioEntityFromJson(json);
}

enum AudioProcessingStateStatus {
  idle,
  loading,
  buffering,
  ready,
  completed,
  error,
}

@freezed
abstract class PlaybackStateEntity with _$PlaybackStateEntity {
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory PlaybackStateEntity({
    required bool isPlaying,
    required AudioProcessingStateStatus processingState,
    required Duration position,
    required Duration bufferedPosition,
    required Duration duration,
    required int currentIndex,
    required List<AudioEntity> queue,
    @Default(0) int queueGeneration,
  }) = _PlaybackStateEntity;

  factory PlaybackStateEntity.fromJson(Map<String, dynamic> json) =>
      _$PlaybackStateEntityFromJson(json);
}
