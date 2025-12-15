part of 'download_button_bloc.dart';

/// Events for DownloadButton BLoC
@freezed
class DownloadButtonEvent with _$DownloadButtonEvent {
  /// Initialize button state by checking download status
  const factory DownloadButtonEvent.initialize() = _Initialize;

  /// Start downloading
  const factory DownloadButtonEvent.startDownload({
    required String surahTitle,
  }) = _StartDownload;

  /// Retry a failed download
  const factory DownloadButtonEvent.retry({required String surahTitle}) =
      _Retry;

  /// Cancel an active download
  const factory DownloadButtonEvent.cancel() = _Cancel;

  /// Progress update received
  const factory DownloadButtonEvent.progressUpdated({
    required double progress,
    required int downloadedBytes,
    required int totalBytes,
  }) = _ProgressUpdated;

  /// Download completed
  const factory DownloadButtonEvent.completed() = _Completed;

  /// Download failed
  const factory DownloadButtonEvent.failed({String? errorMessage}) = _Failed;

  /// Download cancelled
  const factory DownloadButtonEvent.cancelled() = _Cancelled;

  /// Download paused
  const factory DownloadButtonEvent.paused() = _Paused;
}
