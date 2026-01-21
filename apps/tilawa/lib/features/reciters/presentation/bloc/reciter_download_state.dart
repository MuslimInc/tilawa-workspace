part of 'reciter_download_bloc.dart';

class ReciterDownloadState extends Equatable {
  const ReciterDownloadState({
    this.progress = 0.0,
    this.isDownloadingAll = false,
    this.isPending = false,
    this.downloadedCount = 0,
    this.totalCount = 0,
    this.errorMessage,
  });

  final double progress;
  final bool isDownloadingAll;
  final bool isPending;
  final int downloadedCount;
  final int totalCount;
  final String? errorMessage;

  bool get isAllDownloaded => totalCount > 0 && downloadedCount == totalCount;

  /// Determines if error message should be shown
  /// Returns true when error message changes from null to a value
  bool shouldShowError(ReciterDownloadState previous) {
    return errorMessage != null && previous.errorMessage != errorMessage;
  }

  /// Determines if download started toast should be shown
  /// Returns true only for user-initiated downloads (after pending state)
  /// Returns false when discovering ongoing downloads on navigation
  bool shouldShowDownloadStarted(ReciterDownloadState previous) {
    return !previous.isDownloadingAll && isDownloadingAll && previous.isPending;
  }

  /// Checks if error is a network-related error
  bool get isNetworkError {
    return errorMessage != null &&
        (errorMessage!.contains('No internet') ||
            errorMessage!.contains('internet'));
  }

  @override
  List<Object?> get props => [
    progress,
    isDownloadingAll,
    isPending,
    downloadedCount,
    totalCount,
    errorMessage,
  ];

  ReciterDownloadState copyWith({
    double? progress,
    bool? isDownloadingAll,
    bool? isPending,
    int? downloadedCount,
    int? totalCount,
    String? errorMessage,
  }) {
    return ReciterDownloadState(
      progress: progress ?? this.progress,
      isDownloadingAll: isDownloadingAll ?? this.isDownloadingAll,
      isPending: isPending ?? this.isPending,
      downloadedCount: downloadedCount ?? this.downloadedCount,
      totalCount: totalCount ?? this.totalCount,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
