import 'package:injectable/injectable.dart';
import '../repositories/surah_repository.dart';

@Singleton()
class UpdateSurahDownloadProgressUseCase {
  const UpdateSurahDownloadProgressUseCase(this._surahRepository);

  final SurahRepository _surahRepository;

  Future<void> call({
    required String surahId,
    required String reciterName,
    required bool isDownloading,
    required double progress,
    String? downloadId,
  }) async {
    await _surahRepository.updateSurahDownloadProgress(
      surahId,
      reciterName,
      isDownloading,
      progress,
      downloadId,
    );
  }
}
