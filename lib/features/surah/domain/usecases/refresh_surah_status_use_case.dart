import 'package:audio_service/audio_service.dart';
import 'package:injectable/injectable.dart';
import 'package:muzakri/features/surah/domain/entities/surah_entity.dart';
import 'package:muzakri/features/surah/domain/repositories/surah_repository.dart';

@Singleton()
class RefreshSurahStatusUseCase {
  const RefreshSurahStatusUseCase(this._surahRepository);

  final SurahRepository _surahRepository;

  Future<SurahEntity?> call({
    required String surahId,
    required String reciterName,
  }) async {
    final isDownloaded = await _surahRepository.isSurahDownloaded(
      surahId,
      reciterName,
    );

    var surah = await _surahRepository.getSurah(surahId, reciterName);
    if (surah == null) {
      // Create a basic surah if it doesn't exist
      final mediaItem = MediaItem(
        id: surahId,
        title: '', // This should be provided from the data source
        artist: reciterName,
        extras: {'nameAr': '', 'url': ''},
      );
      surah = SurahEntity(mediaItem: mediaItem, isDownloaded: isDownloaded);
    } else {
      surah = surah.copyWith(isDownloaded: isDownloaded);
    }

    await _surahRepository.updateSurah(surah);
    return surah;
  }
}
