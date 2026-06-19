import 'package:injectable/injectable.dart';
import 'package:tilawa_core/entities/audio.dart';
import 'package:tilawa_core/entities/audio_extras_keys.dart';
import 'package:tilawa_core/entities/moshaf_entity.dart';
import 'package:tilawa_core/entities/reciter_entity.dart';
import 'package:tilawa_core/utils/surah_names.dart';
import 'package:tilawa_core/utils/url_validator.dart';

import '../entities/reciter_audio_catalog.dart';

/// Builds flat tracks and indexes in a single O(n) pass.
@lazySingleton
class ReciterAudioCatalogBuilder {
  const ReciterAudioCatalogBuilder();

  /// Returns playable surah entries with artist and reciter indexes.
  ReciterAudioCatalog build(List<ReciterEntity> reciters) {
    final List<AudioEntity> tracks = <AudioEntity>[];
    final Map<String, List<AudioEntity>> byArtist =
        <String, List<AudioEntity>>{};
    final Map<String, ReciterEntity> byReciterName = <String, ReciterEntity>{};

    for (final ReciterEntity reciter in reciters) {
      final String reciterKey = reciter.name.trim().toLowerCase();
      if (reciterKey.isNotEmpty) {
        byReciterName[reciterKey] = reciter;
      }

      for (final MoshafEntity moshaf in reciter.moshaf) {
        final List<String> surahList = moshaf.surahList.split(',');
        for (final String surahId in surahList) {
          final String formattedSurahId = surahId.padLeft(3, '0');
          final String audioId = '${moshaf.server}$formattedSurahId.mp3';

          if (!UrlValidator.isValid(audioId)) {
            continue;
          }

          final AudioEntity track = AudioEntity(
            id: audioId,
            title:
                '${SurahNames.getEnglishSurahName(int.parse(surahId))} '
                '$formattedSurahId',
            url: audioId,
            duration: Duration.zero,
            album: moshaf.name,
            artist: reciter.name,
            extras: <String, Object>{
              AudioExtrasKeys.reciterId: reciter.id,
              AudioExtrasKeys.moshafId: moshaf.id,
              AudioExtrasKeys.surahId: int.parse(surahId),
            },
          );

          tracks.add(track);
          byArtist.putIfAbsent(reciter.name, () => <AudioEntity>[]).add(track);
        }
      }
    }

    return ReciterAudioCatalog(
      reciters: List<ReciterEntity>.unmodifiable(reciters),
      tracks: tracks,
      byArtist: byArtist,
      byReciterName: byReciterName,
    );
  }
}
