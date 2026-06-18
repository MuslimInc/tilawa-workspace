import 'package:injectable/injectable.dart';
import 'package:tilawa/features/audio_player/domain/usecases/audio_player_usecases.dart';
import 'package:tilawa/features/share/domain/services/reciter_audio_catalog.dart';
import 'package:tilawa_core/entities/audio.dart';
import 'package:tilawa_core/utils/surah_names.dart';
import 'package:tilawa_core/utils/typedefs.dart';

import '../entities/entities.dart';

/// Plays a single ayah using everyayah.com verse audio for the active reciter.
@injectable
class PlayAyahAudioUseCase {
  const PlayAyahAudioUseCase(this._playFromQueue);

  final PlayFromQueueUseCase _playFromQueue;

  ResultVoid call({
    required AyahEntity ayah,
    AudioEntity? currentAudio,
  }) {
    final String serverUrl = currentAudio?.url ?? '';
    final String reciterFolder = ReciterAudioCatalog.resolveFolder(serverUrl);
    final String reciterName = currentAudio?.artist ?? 'Mishary Rashid Alafasy';
    final String? reciterId = currentAudio?.extras?['reciterId'] as String?;
    final String? moshafId = currentAudio?.extras?['moshafId'] as String?;

    final String url = ReciterAudioCatalog.buildVerseAudioUrl(
      reciterFolder: reciterFolder,
      surahNumber: ayah.surahNumber,
      ayahNumber: ayah.numberInSurah,
    );

    final String surahName = SurahNames.getArabicSurahName(ayah.surahNumber);

    final AudioEntity audio = AudioEntity(
      id: url,
      title: '$surahName — ${ayah.numberInSurah}',
      url: url,
      duration: Duration.zero,
      artist: reciterName,
      extras: <String, dynamic>{
        'surahId': ayah.surahNumber,
        'ayahNumber': ayah.numberInSurah,
        'reciterId': ?reciterId,
        'moshafId': ?moshafId,
      },
    );

    return _playFromQueue([audio], 0);
  }
}
