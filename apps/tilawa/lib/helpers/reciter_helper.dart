import 'package:tilawa_core/di/injection.dart';
import 'package:tilawa_core/entities/audio.dart';
import 'package:tilawa_core/entities/moshaf_entity.dart';
import 'package:tilawa_core/entities/reciter_entity.dart';

import '../main.dart';
import '../shared/audio/audio_player_handler.dart';

class ReciterHelper {
  /// Extract reciter information from an AudioEntity
  static Future<ReciterEntity?> getReciterFromAudioEntity(
    AudioEntity audio, {
    String? languageCode,
  }) async {
    try {
      // Check if GetIt is available (e.g., in test environment)
      AudioPlayerHandler audioHandler;
      try {
        audioHandler = getIt<AudioPlayerHandler>();
      } catch (e) {
        logger.d('AudioPlayerHandler not available in GetIt: $e');
        return null;
      }

      // Call getRecitersData - it should always return a Future
      final List<ReciterEntity>? reciters = await audioHandler.getRecitersData(
        languageCode: languageCode,
      );

      if (reciters == null) {
        return null;
      }

      // First try to find by artist field
      final String? reciterName = audio.artist;
      if (reciterName != null && reciterName.isNotEmpty) {
        try {
          final String cleanReciterName = reciterName.trim().toLowerCase();
          return reciters.firstWhere(
            (reciter) => reciter.name.trim().toLowerCase() == cleanReciterName,
            orElse: () => throw StateError('Reciter not found'),
          );
        } catch (e) {
          logger.d('Reciter not found by name: "$reciterName"');
        }
      }

      // If artist field is empty, try to find by matching the server URL in the audio ID
      // This is a fallback approach for when artist field is not set
      for (final ReciterEntity reciter in reciters) {
        for (final MoshafEntity moshaf in reciter.moshaf) {
          if (audio.id.contains(moshaf.server)) {
            logger.d('Found reciter by server match: ${reciter.name}');
            return reciter;
          }
        }
      }

      logger.d('No reciter found for AudioEntity: ${audio.id}');
      return null;
    } catch (e) {
      logger.d('Error getting reciter from audio item: $e');
      return null;
    }
  }

  /// Check if an AudioEntity has valid reciter information
  static bool hasReciterInfo(AudioEntity audio) {
    final String? artist = audio.artist;

    // Check if artist field has reciter name
    if (artist != null && artist.isNotEmpty) {
      return true;
    }

    // Check if the AudioEntity looks like a Quran recitation
    // (has .mp3 extension and contains surah-like patterns)
    if (audio.id.contains('.mp3') &&
        (audio.title.contains('سورة') ||
            audio.title.contains('Surah') ||
            RegExp(r'\d{3}').hasMatch(audio.title))) {
      return true;
    }

    return false;
  }
}
