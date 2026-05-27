import 'package:tilawa/core/di/injection.dart';
import 'package:tilawa_core/entities/audio.dart';
import 'package:tilawa_core/entities/moshaf_entity.dart';
import 'package:tilawa_core/entities/reciter_entity.dart';

import 'package:tilawa/core/logging/app_logger.dart';
import '../shared/audio/audio_player_handler.dart';

class ReciterHelper {
  /// Extract reciter information from an AudioEntity
  static Future<ReciterEntity?> getReciterFromAudioEntity(
    AudioEntity audio, {
    String? languageCode,
  }) async {
    try {
      AudioPlayerHandler audioHandler;
      try {
        audioHandler = getIt<AudioPlayerHandler>();
      } catch (e) {
        logger.d('AudioPlayerHandler not available in GetIt: $e');
        return null;
      }

      final String? reciterName = audio.artist;
      if (reciterName != null && reciterName.isNotEmpty) {
        final ReciterEntity? byName = await audioHandler.findReciterByName(
          reciterName,
          languageCode: languageCode,
        );
        if (byName != null) {
          return byName;
        }
        logger.d('Reciter not found by name: "$reciterName"');
      }

      final List<ReciterEntity>? reciters = await audioHandler.getRecitersData(
        languageCode: languageCode,
      );
      if (reciters == null) {
        return null;
      }

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

    if (artist != null && artist.isNotEmpty) {
      return true;
    }

    if (audio.id.contains('.mp3') &&
        (audio.title.contains('سورة') ||
            audio.title.contains('Surah') ||
            RegExp(r'\d{3}').hasMatch(audio.title))) {
      return true;
    }

    return false;
  }
}
