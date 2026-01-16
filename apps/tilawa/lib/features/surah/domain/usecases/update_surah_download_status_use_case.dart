import 'package:injectable/injectable.dart';
import '../repositories/surah_repository.dart';

@Singleton()
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
