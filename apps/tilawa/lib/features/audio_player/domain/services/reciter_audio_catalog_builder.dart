import 'package:injectable/injectable.dart';
import 'package:tilawa_core/entities/audio.dart';
import 'package:tilawa_core/entities/moshaf_entity.dart';
import 'package:tilawa_core/entities/reciter_entity.dart';
import 'package:tilawa_core/utils/surah_names.dart';
import 'package:tilawa_core/utils/url_validator.dart';

import '../entities/reciter_audio_catalog.dart';

/// Builds flat tracks and an artist index in a single O(n) pass.
@lazySingleton
class ReciterAudioCatalogBuilder {
  const ReciterAudioCatalogBuilder();

  /// Returns playable surah entries and a [ReciterAudioCatalog.byArtist] index.
  ReciterAudioCatalog build(List<ReciterEntity> reciters) {
    final List<AudioEntity> tracks = <AudioEntity>[];
    final Map<String, List<AudioEntity>> byArtist =
        <String, List<AudioEntity>>{};

    for (final ReciterEntity reciter in reciters) {
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
              'reciterId': reciter.id,
              'moshafId': moshaf.id,
              'surahId': int.parse(surahId),
            },
          );

          tracks.add(track);
          byArtist
              .putIfAbsent(reciter.name, () => <AudioEntity>[])
              .add(track);
        }
      }
    }

    return ReciterAudioCatalog(tracks: tracks, byArtist: byArtist);
  }
}
