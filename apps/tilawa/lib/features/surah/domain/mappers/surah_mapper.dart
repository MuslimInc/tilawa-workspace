import 'package:tilawa_core/entities/audio.dart';
import '../entities/surah_entity.dart';

class SurahMapper {
  /// Convert Surah to AudioEntity
  static AudioEntity toAudioEntity(SurahEntity surah) {
    // Return the original AudioEntity
    return surah.audio;
  }

  /// Convert AudioEntity to Surah
  static SurahEntity fromAudioEntity(AudioEntity audio) {
    return SurahEntity(audio: audio);
  }

  /// Create Surah from basic data
  static SurahEntity create({
    required String id,
    required String name,
    required String nameAr,
    required String reciterName,
    required String url,
    required Duration duration,
    String? artUri,
    bool isDownloaded = false,
    bool isDownloading = false,
    double downloadProgress = 0.0,
    String? downloadId,
  }) {
    final audio = AudioEntity(
      id: id,
      title: name,
      artist: reciterName,
      album: reciterName,
      url: url,
      duration: duration,
      artUri: artUri,
    );

    return SurahEntity(
      audio: audio,
      isDownloaded: isDownloaded,
      isDownloading: isDownloading,
      downloadProgress: downloadProgress,
      downloadId: downloadId,
    );
  }
}
