import 'package:injectable/injectable.dart';
import '../entities/surah_entity.dart';
import '../repositories/surah_repository.dart';

@Singleton()
class RefreshSurahDownloadStatusUseCase {
  const RefreshSurahDownloadStatusUseCase(this._surahRepository);

  final SurahRepository _surahRepository;

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

    // Update the surah in the list
    final List<SurahEntity> updatedSurahList = currentSurahs.map((surah) {
      if (surah.id == surahId && surah.reciterName == reciterName) {
        return surah.copyWith(isDownloaded: isDownloaded);
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
        surah.copyWith(isDownloaded: isDownloaded),
      );
    }

    return updatedSurahList;
  }
}
