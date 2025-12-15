part of 'download_button_bloc.dart';

/// State for individual download button
///
/// Each download button manages its own state independently,
/// eliminating the need to listen to global download state changes.
@freezed
abstract class DownloadButtonState with _$DownloadButtonState {
  /// Initial state while checking download status
  const factory DownloadButtonState.initial() = _Initial;

  /// Button is ready to start download
  const factory DownloadButtonState.readyToDownload() = _ReadyToDownload;

  /// Download is pending (queued but not started)
  const factory DownloadButtonState.pending() = _PendingState;

  /// Download is actively in progress
  const factory DownloadButtonState.downloading({
    required double progress,
    @Default(0) int downloadedBytes,
    @Default(0) int totalBytes,
  }) = _Downloading;

  /// Download completed successfully
  const factory DownloadButtonState.completed() = _CompletedState;

  /// Download failed with optional error message
  const factory DownloadButtonState.failed({String? errorMessage}) =
      _FailedState;

  /// Download was cancelled
  const factory DownloadButtonState.cancelled() = _CancelledState;

  /// Network error (can retry)
  const factory DownloadButtonState.networkError({String? errorMessage}) =
      _NetworkError;

  /// Download is paused
  const factory DownloadButtonState.paused() = _PausedState;
}
