import 'package:injectable/injectable.dart';

import '../../../../core/entities/audio.dart';
import '../entities/surah_entity.dart';
import '../repositories/surah_repository.dart';

@Singleton()
class RefreshSurahStatusUseCase {
  const RefreshSurahStatusUseCase(this._surahRepository);

  final SurahRepository _surahRepository;

  Future<SurahEntity?> call({
    required String surahId,
    required String reciterName,
  }) async {
    final bool isDownloaded = await _surahRepository.isSurahDownloaded(
      surahId,
      reciterName,
    );

    SurahEntity? surah = await _surahRepository.getSurah(surahId, reciterName);
    if (surah == null) {
      // Create a basic surah if it doesn't exist
      final audio = AudioEntity(
        id: surahId,
        title: '', // This should be provided from the data source
        artist: reciterName,
        url: '', // This should also be provided
        duration: Duration.zero,
      );
      surah = SurahEntity(audio: audio, isDownloaded: isDownloaded);
    } else {
      surah = surah.copyWith(isDownloaded: isDownloaded);
    }

    await _surahRepository.updateSurah(surah);
    return surah;
  }
}
