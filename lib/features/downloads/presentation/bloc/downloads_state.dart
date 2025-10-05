part of 'downloads_bloc.dart';

@freezed
sealed class DownloadsState with _$DownloadsState {
  const factory DownloadsState.initial() = DownloadsInitial;

  const factory DownloadsState.loading() = DownloadsLoading;

  const factory DownloadsState.loaded(
    Map<String, List<DownloadItem>> downloadsByReciter,
  ) = DownloadsLoaded;

  const factory DownloadsState.error(String message) = DownloadsError;

  const factory DownloadsState.surahDownloadStatus({
    required String surahId,
    required String reciterName,
    required bool isDownloaded,
  }) = SurahDownloadStatus;

  const factory DownloadsState.fileValidationResult({
    required String downloadId,
    required bool isValid,
  }) = FileValidationResult;

  const factory DownloadsState.validDownloadsLoaded({
    required String reciterName,
    required List<DownloadItem> validDownloads,
  }) = ValidDownloadsLoaded;

  const factory DownloadsState.playbackInitiated({required String message}) =
      PlaybackInitiated;
}
