import 'dart:developer' show log;

import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tilawa_core/config/language_config.dart';
import 'package:tilawa_core/entities/audio.dart';
import 'package:tilawa_core/entities/audio_extras_keys.dart';
import 'package:tilawa_core/entities/moshaf_entity.dart';
import 'package:tilawa_core/utils/reciter_portrait_catalog.dart';
import 'package:tilawa_core/utils/surah_names.dart';
import 'package:tilawa_core/utils/url_validator.dart';

/// Builds localized [AudioEntity] lists for a single moshaf surah list.
@lazySingleton
class MoshafSurahAudioListBuilder {
  MoshafSurahAudioListBuilder(this._prefs);

  final SharedPreferencesAsync _prefs;

  Future<List<AudioEntity>?> build(
    MoshafEntity moshaf, {
    String? reciterName,
    String? reciterId,
  }) async {
    try {
      final List<String> surahList = moshaf.surahList.split(',');
      final List<AudioEntity> audioEntities = <AudioEntity>[];

      for (final String surahId in surahList) {
        final int surahNumber = int.parse(surahId);
        final String formattedSurahId = surahId.padLeft(3, '0');
        final String audioId = '${moshaf.server}$formattedSurahId.mp3';

        if (!UrlValidator.isValid(audioId)) {
          log('Skipping invalid audio URL: $audioId for surah $surahId');
          continue;
        }

        final String surahName = await _surahName(surahNumber);

        audioEntities.add(
          AudioEntity(
            id: audioId,
            title: surahName,
            url: audioId,
            duration: Duration.zero,
            artist: reciterName,
            album: moshaf.name,
            artUri: ReciterPortraitCatalog.photoUrlForIdString(reciterId),
            extras: <String, dynamic>{
              AudioExtrasKeys.reciterId: reciterId,
              AudioExtrasKeys.moshafId: moshaf.id,
              AudioExtrasKeys.surahId: surahNumber,
            },
          ),
        );
      }

      return audioEntities;
    } catch (e) {
      log('Exception getting surah list: $e');
      return null;
    }
  }

  Future<String> _surahName(int surahNumber) async {
    final String currentLanguage =
        await _prefs.getString(LanguageConfig.languageKey) ??
        LanguageConfig.defaultLanguageCode;

    if (currentLanguage == 'en') {
      return SurahNames.getEnglishSurahName(surahNumber);
    }
    return SurahNames.getArabicSurahName(surahNumber);
  }
}
