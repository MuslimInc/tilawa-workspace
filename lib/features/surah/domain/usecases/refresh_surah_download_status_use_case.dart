import 'package:injectable/injectable.dart';

import '../../../downloads/domain/repositories/downloads_repository.dart';
import '../entities/surah_entity.dart';
import '../repositories/surah_repository.dart';

@Singleton()
class RefreshSurahDownloadStatusUseCase {
  const RefreshSurahDownloadStatusUseCase(
    this._surahRepository,
    this._downloadsRepository,
  );

  final SurahRepository _surahRepository;
  final DownloadsRepository _downloadsRepository;

  Future<List<SurahEntity>> call({
    required List<SurahEntity> currentSurahs,
    required String surahId,
    required String reciterName,
  }) async {
    // Check download status
    final bool isDownloaded = await _surahRepository.isSurahDownloaded(
      surahId,
      reciterName,
    );

    // Check if currently downloading
    final bool isDownloading = await _downloadsRepository.isSurahDownloading(
      surahId,
      reciterName,
    );

    // Update the surah in the list
    final List<SurahEntity> updatedSurahList = currentSurahs.map((surah) {
      if (surah.id == surahId && surah.reciterName == reciterName) {
        return surah.copyWith(
          isDownloaded: isDownloaded,
          isDownloading: isDownloading,
        );
      }
      return surah;
    }).toList();

    // Update surah in repository cache
    final SurahEntity? surah = await _surahRepository.getSurah(
      surahId,
      reciterName,
    );
    if (surah != null) {
      await _surahRepository.updateSurah(
        surah.copyWith(
          isDownloaded: isDownloaded,
          isDownloading: isDownloading,
        ),
      );
    }

    return updatedSurahList;
  }
}
