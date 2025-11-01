import 'package:audio_service/audio_service.dart';
import 'package:muzakri/core/di/injection.dart';
import 'package:muzakri/main.dart';
import 'package:muzakri/shared/audio/audio_player_handler.dart';
import 'package:muzakri/shared/models/reciter_model.dart';

class ReciterHelper {
  /// Extract reciter information from a MediaItem
  static Future<Reciter?> getReciterFromMediaItem(
    MediaItem mediaItem, {
    String? languageCode,
  }) async {
    try {
      final audioHandler = getIt<AudioPlayerHandler>();
      final reciters = await audioHandler.getRecitersData(
        languageCode: languageCode,
      );

      if (reciters == null) return null;

      // First try to find by artist field
      final reciterName = mediaItem.artist;
      if (reciterName != null && reciterName.isNotEmpty) {
        try {
          return reciters.firstWhere(
            (reciter) => reciter.name == reciterName,
            orElse: () => throw StateError('Reciter not found'),
          );
        } catch (e) {
          logger.d('Reciter not found by name: $reciterName');
        }
      }

      // If artist field is empty, try to find by matching the server URL in the MediaItem ID
      // This is a fallback approach for when artist field is not set
      for (final reciter in reciters) {
        for (final moshaf in reciter.moshaf) {
          if (mediaItem.id.contains(moshaf.server)) {
            logger.d('Found reciter by server match: ${reciter.name}');
            return reciter;
          }
        }
      }

      logger.d('No reciter found for MediaItem: ${mediaItem.id}');
      return null;
    } catch (e) {
      logger.d('Error getting reciter from media item: $e');
      return null;
    }
  }

  /// Check if a MediaItem has valid reciter information
  static bool hasReciterInfo(MediaItem mediaItem) {
    final artist = mediaItem.artist;
    if (artist == null || artist.isEmpty) {
      return false;
    }
    // Check if artist field has reciter name
    if (artist.isNotEmpty) {
      return true;
    }

    // Check if the MediaItem looks like a Quran recitation
    // (has .mp3 extension and contains surah-like patterns)
    if (mediaItem.id.contains('.mp3') &&
        (mediaItem.title.contains('سورة') ||
            mediaItem.title.contains('Surah') ||
            RegExp(r'\d{3}').hasMatch(mediaItem.title))) {
      return true;
    }

    return false;
  }
}
