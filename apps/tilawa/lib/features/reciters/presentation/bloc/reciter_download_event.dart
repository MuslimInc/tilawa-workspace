part of 'reciter_download_bloc.dart';

abstract class ReciterDownloadEvent extends Equatable {
  const ReciterDownloadEvent();

  @override
  List<Object?> get props => [];
}

class StartReciterDownloadAll extends ReciterDownloadEvent {
  const StartReciterDownloadAll({required this.reciter, required this.surahs});

  final ReciterEntity reciter;
  final List<SurahEntity> surahs;

  @override
  List<Object?> get props => [reciter, surahs];
}

class CancelReciterDownloadAll extends ReciterDownloadEvent {
  const CancelReciterDownloadAll({required this.reciterName});

  final String reciterName;

  @override
  List<Object?> get props => [reciterName];
}

class UpdateReciterDownloadProgress extends ReciterDownloadEvent {
  const UpdateReciterDownloadProgress({
    required this.progress,
    required this.isDownloading,
    required this.downloadedCount,
    required this.totalCount,
  });

  final double progress;
  final bool isDownloading;
  final int downloadedCount;
  final int totalCount;

  @override
  List<Object?> get props => [
    progress,
    isDownloading,
    downloadedCount,
    totalCount,
  ];
}

class InitializeReciterDownload extends ReciterDownloadEvent {
  const InitializeReciterDownload({
    required this.reciterName,
    required this.totalSurahs,
    required this.downloadedSurahIds,
  });

  final String reciterName;
  final int totalSurahs;
  final List<String> downloadedSurahIds;

  @override
  List<Object?> get props => [reciterName, totalSurahs, downloadedSurahIds];
}
