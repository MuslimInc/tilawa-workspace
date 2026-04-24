import 'package:freezed_annotation/freezed_annotation.dart';

part 'audio_clip_config.freezed.dart';

/// Configuration for generating an audio clip from a verse range.
@freezed
abstract class AudioClipConfig with _$AudioClipConfig {
  const factory AudioClipConfig({
    required int surahNumber,
    required int fromAyah,
    required int toAyah,
    required String reciterName,
    required String reciterFolder,
    required String serverUrl,
  }) = _AudioClipConfig;

  const AudioClipConfig._();

  /// Total number of verses in this clip.
  int get verseCount => toAyah - fromAyah + 1;
}
