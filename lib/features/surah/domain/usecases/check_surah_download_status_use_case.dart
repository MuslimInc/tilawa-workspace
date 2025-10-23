import 'package:injectable/injectable.dart';
import 'package:muzakri/features/surah/domain/entities/surah_entity.dart';
import 'package:muzakri/features/surah/domain/repositories/surah_repository.dart';

@Singleton()
class CheckSurahDownloadStatusUseCase {
  const CheckSurahDownloadStatusUseCase(this._surahRepository);

  final SurahRepository _surahRepository;

  Future<SurahEntity?> call({
    required String surahId,
    required String reciterName,
  }) async {
    final isDownloaded = await _surahRepository.isSurahDownloaded(
      surahId,
      reciterName,
    );

    final surah = await _surahRepository.getSurah(surahId, reciterName);
    if (surah != null) {
      final updatedSurah = surah.copyWith(isDownloaded: isDownloaded);
      await _surahRepository.updateSurah(updatedSurah);
      return updatedSurah;
    }
    return null;
  }
}
