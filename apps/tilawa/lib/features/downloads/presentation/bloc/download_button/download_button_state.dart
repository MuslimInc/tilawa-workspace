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
  const factory DownloadButtonState.pending({
    @Default(false) bool lowStorageWarning,
  }) = _PendingState;

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

/// Extension methods for [DownloadButtonState] to encapsulate state transition logic
/// following SOLID principles (Single Responsibility)
extension DownloadButtonStateX on DownloadButtonState {
  /// Determines if download started toast should be shown
  /// Returns true only when transitioning from user-actionable states
  /// (not from initial or already downloading states)
  bool shouldShowDownloadStarted(DownloadButtonState previous) {
    return maybeMap(
      downloading: (_) => previous.maybeMap(
        // Only show toast if transitioning from user-actionable states
        readyToDownload: (_) => true,
        pending: (_) => true, // User clicked download button
        failed: (_) => true,
        cancelled: (_) => true,
        networkError: (_) => true,
        paused: (_) => true,
        // Don't show toast if transitioning from initial/downloading
        orElse: () => false,
      ),
      orElse: () => false,
    );
  }

  /// Determines if network error toast should be shown
  bool shouldShowNetworkError(DownloadButtonState previous) {
    return maybeMap(networkError: (_) => true, orElse: () => false);
  }

  bool shouldShowLowStorageWarning(DownloadButtonState previous) {
    return maybeWhen(
      pending: (lowStorageWarning) =>
          lowStorageWarning &&
          !previous.maybeWhen(
            pending: (previousWarning) => previousWarning,
            orElse: () => false,
          ),
      orElse: () => false,
    );
  }

  /// Determines if any toast should be shown
  bool shouldShowToast(DownloadButtonState previous) {
    return shouldShowDownloadStarted(previous) ||
        shouldShowNetworkError(previous) ||
        shouldShowLowStorageWarning(previous);
  }

  /// Checks if progress update is significant enough to trigger rebuild
  /// Returns true if progress changed by more than 2%
  bool hasSignificantProgressChange(DownloadButtonState previous) {
    return maybeWhen(
      downloading: (currProgress, _, _) {
        return previous.maybeWhen(
          downloading: (prevProgress, _, _) =>
              (currProgress - prevProgress).abs() > 0.02, // 2% threshold
          orElse: () => true,
        );
      },
      orElse: () => true,
    );
  }
}
