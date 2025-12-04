import 'package:injectable/injectable.dart';
import '../entities/surah_entity.dart';
import '../repositories/surah_repository.dart';

@Singleton()
class CheckSurahDownloadStatusUseCase {
  const CheckSurahDownloadStatusUseCase(this._surahRepository);

  final SurahRepository _surahRepository;

  Future<SurahEntity?> call({
    required String surahId,
    required String reciterName,
  }) async {
    final bool isDownloaded = await _surahRepository.isSurahDownloaded(
      surahId,
      reciterName,
    );

    final SurahEntity? surah = await _surahRepository.getSurah(
      surahId,
      reciterName,
    );
    if (surah != null) {
      final SurahEntity updatedSurah = surah.copyWith(
        isDownloaded: isDownloaded,
      );
      await _surahRepository.updateSurah(updatedSurah);
      return updatedSurah;
    }
    return null;
  }
}
