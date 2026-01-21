part of 'surah_bloc.dart';

@freezed
sealed class SurahEvent with _$SurahEvent {
  const factory SurahEvent.loadSurahsForReciter(String reciterName) =
      LoadSurahsForReciter;

  const factory SurahEvent.updateSurahDownloadStatus({
    required String surahId,
    required String reciterName,
    required bool isDownloaded,
  }) = UpdateSurahDownloadStatus;

  const factory SurahEvent.updateSurahDownloadProgress({
    required String surahId,
    required String reciterName,
    required bool isDownloading,
    required double progress,
    String? downloadId,
  }) = UpdateSurahDownloadProgress;

  const factory SurahEvent.checkSurahDownloadStatus({
    required String surahId,
    required String reciterName,
  }) = CheckSurahDownloadStatus;

  const factory SurahEvent.refreshSurahStatus({
    required String surahId,
    required String reciterName,
  }) = RefreshSurahStatus;
}
