part of 'downloads_bloc.dart';

@freezed
sealed class DownloadsEvent with _$DownloadsEvent {
  const factory DownloadsEvent.loadDownloads() = LoadDownloads;

  const factory DownloadsEvent.downloadSurah({
    required String surahId,
    required String surahTitle,
    required String reciterName,
  }) = DownloadSurahEvent;

  const factory DownloadsEvent.deleteDownload({required String downloadId}) =
      DeleteDownloadEvent;

  const factory DownloadsEvent.deleteReciterDownloads({
    required String reciterName,
  }) = DeleteReciterDownloads;

  const factory DownloadsEvent.clearAllDownloads() = ClearAllDownloads;

  const factory DownloadsEvent.checkSurahDownloaded({
    required String surahId,
    required String reciterName,
  }) = CheckSurahDownloadedEvent;

  const factory DownloadsEvent.validateDownloadedFile({
    required String downloadId,
  }) = ValidateDownloadedFileEvent;

  const factory DownloadsEvent.getValidCompletedDownloads({
    required String reciterName,
  }) = GetValidCompletedDownloadsEvent;

  const factory DownloadsEvent.playDownloadedSurah({
    required String downloadId,
  }) = PlayDownloadedSurahEvent;

  const factory DownloadsEvent.playAllDownloads({required String reciterName}) =
      PlayAllDownloadsEvent;

  const factory DownloadsEvent.checkPremiumAccess() = CheckPremiumAccessEvent;

  const factory DownloadsEvent.retryDownload({required String downloadId}) =
      RetryDownloadEvent;

  const factory DownloadsEvent.refreshDownloadsProgress() =
      RefreshDownloadsProgress;
}
