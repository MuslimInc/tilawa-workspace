import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:tilawa_core/entities/audio.dart';

part 'surah_entity.freezed.dart';
part 'surah_entity.g.dart';

@freezed
abstract class SurahEntity with _$SurahEntity {
  const factory SurahEntity({
    required AudioEntity audio,
    @Default(false) bool isDownloaded,
    @Default(false) bool isDownloading,
    @Default(0.0) double downloadProgress, // 0.0 to 1.0
    String? downloadId,
  }) = _SurahEntity;

  const SurahEntity._();

  factory SurahEntity.fromJson(Map<String, dynamic> json) =>
      _$SurahEntityFromJson(json);

  // Convenience getters for easy access to AudioEntity properties
  String get id => audio.id;
  String get name => audio.title;
  String get nameAr =>
      audio.artist ??
      ''; // Assuming artist field might contain Arabic name or handled elsewhere
  String get nameEn => audio.title;
  String get formattedId {
    // try to extract numeric part from ID if extras are missing (e.g. in tests)
    try {
      final String basename = id.split('/').last.split('.').first;
      final int? num = int.tryParse(basename);
      if (num != null) {
        return basename.padLeft(3, '0');
      }
    } catch (_) {}
    return '';
  }

  String get reciterName => audio.artist ?? '';
}
