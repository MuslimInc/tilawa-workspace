import 'package:audio_service/audio_service.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'surah_entity.freezed.dart';

@freezed
abstract class SurahEntity with _$SurahEntity {
  const factory SurahEntity({
    required MediaItem mediaItem,
    @Default(false) bool isDownloaded,
    @Default(false) bool isDownloading,
    @Default(0.0) double downloadProgress, // 0.0 to 1.0
    String? downloadId,
  }) = _SurahEntity;

  const SurahEntity._();

  // Convenience getters for easy access to MediaItem properties
  String get id => mediaItem.id;
  String get name => mediaItem.title;
  String get nameAr => mediaItem.extras?['nameAr'] as String? ?? '';
  String get reciterName => mediaItem.artist ?? '';
}
