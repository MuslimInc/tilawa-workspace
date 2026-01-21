import 'package:injectable/injectable.dart';

import '../../../downloads/domain/repositories/downloads_repository.dart';
import '../entities/surah_entity.dart';
import '../repositories/surah_repository.dart';

@Singleton()
class CheckSurahDownloadStatusUseCase {
  const CheckSurahDownloadStatusUseCase(
    this._surahRepository,
    this._downloadsRepository,
  );

  final SurahRepository _surahRepository;
  final DownloadsRepository _downloadsRepository;

  Future<SurahEntity?> call({
    required String surahId,
    required String reciterName,
  }) async {
    final bool isDownloaded = await _downloadsRepository.isSurahDownloaded(
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
