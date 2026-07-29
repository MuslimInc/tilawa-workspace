import '../repositories/surah_repository.dart';

class UpdateSurahDownloadStatusUseCase {
  const UpdateSurahDownloadStatusUseCase(this._surahRepository);

  final SurahRepository _surahRepository;

  Future<void> call({
    required String surahId,
    required String reciterName,
    required bool isDownloaded,
  }) async {
    await _surahRepository.updateSurahDownloadStatus(
      surahId,
      reciterName,
      isDownloaded,
    );
  }
}
