import 'package:audio_service/audio_service.dart';
import 'package:injectable/injectable.dart';

import '../../../downloads/domain/repositories/downloads_repository.dart';
import '../entities/surah_entity.dart';
import '../mappers/surah_mapper.dart';
import '../repositories/surah_repository.dart';

@Singleton()
class ConvertMediaItemsToSurahsUseCase {
  const ConvertMediaItemsToSurahsUseCase(
    this._surahRepository,
    this._downloadsRepository,
  );

  final SurahRepository _surahRepository;
  final DownloadsRepository _downloadsRepository;

  Future<List<SurahEntity>> call(List<MediaItem> mediaItems) async {
    final surahList = <SurahEntity>[];

    for (final mediaItem in mediaItems) {
      // Convert MediaItem to Surah
      SurahEntity surah = SurahMapper.fromMediaItem(mediaItem);

      // Check download status
      final bool isDownloaded = await _surahRepository.isSurahDownloaded(
        surah.id,
        surah.reciterName,
      );

      // Check if currently downloading
      final bool isDownloading = await _downloadsRepository.isSurahDownloading(
        surah.id,
        surah.reciterName,
      );

      // Update surah with download status
      surah = surah.copyWith(
        isDownloaded: isDownloaded,
        isDownloading: isDownloading,
      );

      // Add to surah repository cache
      await _surahRepository.updateSurah(surah);

      surahList.add(surah);
    }

    return surahList;
  }
}
