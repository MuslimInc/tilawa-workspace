part of 'reciter_download_bloc.dart';

class ReciterDownloadState extends Equatable {
  const ReciterDownloadState({
    this.progress = 0.0,
    this.isDownloadingAll = false,
    this.downloadedCount = 0,
    this.totalCount = 0,
  });

  final double progress;
  final bool isDownloadingAll;
  final int downloadedCount;
  final int totalCount;

  bool get isAllDownloaded => totalCount > 0 && downloadedCount == totalCount;

  @override
  List<Object?> get props => [
    progress,
    isDownloadingAll,
    downloadedCount,
    totalCount,
  ];

  ReciterDownloadState copyWith({
    double? progress,
    bool? isDownloadingAll,
    int? downloadedCount,
    int? totalCount,
  }) {
    return ReciterDownloadState(
      progress: progress ?? this.progress,
      isDownloadingAll: isDownloadingAll ?? this.isDownloadingAll,
      downloadedCount: downloadedCount ?? this.downloadedCount,
      totalCount: totalCount ?? this.totalCount,
    );
  }
}
