import 'package:audio_service/audio_service.dart';
import 'package:injectable/injectable.dart';
import 'package:muzakri/features/surah/domain/entities/surah.dart';
import 'package:muzakri/features/surah/domain/mappers/surah_mapper.dart';
import 'package:muzakri/features/surah/domain/repositories/surah_repository.dart';

@Singleton()
class ConvertMediaItemsToSurahsUseCase {
  const ConvertMediaItemsToSurahsUseCase(this._surahRepository);

  final SurahRepository _surahRepository;

  Future<List<Surah>> call(List<MediaItem> mediaItems) async {
    final surahList = <Surah>[];

    for (final mediaItem in mediaItems) {
      // Convert MediaItem to Surah
      var surah = SurahMapper.fromMediaItem(mediaItem);

      // Check download status
      final isDownloaded = await _surahRepository.isSurahDownloaded(
        surah.id,
        surah.reciterName,
      );

      // Update surah with download status
      surah = surah.copyWith(isDownloaded: isDownloaded);

      // Add to surah repository cache
      await _surahRepository.updateSurah(surah);

      surahList.add(surah);
    }

    return surahList;
  }
}
