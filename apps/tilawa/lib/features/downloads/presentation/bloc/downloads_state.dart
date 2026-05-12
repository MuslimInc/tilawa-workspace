part of 'downloads_bloc.dart';

/// Status enum for DownloadsState
enum DownloadsStateStatus {
  /// Initial state before any data is loaded
  initial,

  /// Loading downloads from repository
  loading,

  /// Downloads loaded successfully
  loaded,

  /// An error occurred
  error,
}

/// Main state class for downloads
@freezed
abstract class DownloadsState with _$DownloadsState {
  const factory DownloadsState({
    @Default(DownloadsStateStatus.initial) DownloadsStateStatus status,
    @Default({}) Map<String, Map<String, List<DownloadItem>>> downloads,
    @Default(0) int totalDownloadsSize,
    String? errorMessage,

    /// Increments whenever [uiNotification] is set for one-shot UI (toasts).
    @Default(0) int uiNotificationSeq,
    DownloadsStatus? uiNotification,
  }) = _DownloadsState;

  const DownloadsState._();
}
