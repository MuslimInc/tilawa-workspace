import 'package:tilawa_core/network/network_info.dart';

import '../../../domain/usecases/usecases.dart';
import 'download_button_bloc.dart';

/// Composes [DownloadButtonBloc] instances with injected use cases.
class DownloadButtonBlocFactory {
  const DownloadButtonBlocFactory({
    required CheckSurahDownloadedUseCase checkSurahDownloaded,
    required DownloadSurahUseCase downloadSurah,
    required CancelDownloadUseCase cancelDownload,
    required PauseDownloadUseCase pauseDownload,
    required ResumeDownloadUseCase resumeDownload,
    required ObserveDownloadProgressUseCase observeDownloadProgress,
    required GetDownloadItemUseCase getDownloadItem,
    required NetworkInfo networkInfo,
  }) : _checkSurahDownloaded = checkSurahDownloaded,
       _downloadSurah = downloadSurah,
       _cancelDownload = cancelDownload,
       _pauseDownload = pauseDownload,
       _resumeDownload = resumeDownload,
       _observeDownloadProgress = observeDownloadProgress,
       _getDownloadItem = getDownloadItem,
       _networkInfo = networkInfo;

  final CheckSurahDownloadedUseCase _checkSurahDownloaded;
  final DownloadSurahUseCase _downloadSurah;
  final CancelDownloadUseCase _cancelDownload;
  final PauseDownloadUseCase _pauseDownload;
  final ResumeDownloadUseCase _resumeDownload;
  final ObserveDownloadProgressUseCase _observeDownloadProgress;
  final GetDownloadItemUseCase _getDownloadItem;
  final NetworkInfo _networkInfo;

  DownloadButtonBloc create({
    required String url,
    required String reciterName,
    required int reciterId,
    bool? initialIsDownloaded,
    bool? initialIsDownloading,
    double? initialProgress,
  }) {
    return DownloadButtonBloc(
      url: url,
      reciterName: reciterName,
      reciterId: reciterId,
      checkSurahDownloaded: _checkSurahDownloaded,
      downloadSurah: _downloadSurah,
      cancelDownload: _cancelDownload,
      pauseDownload: _pauseDownload,
      resumeDownload: _resumeDownload,
      observeDownloadProgress: _observeDownloadProgress,
      getDownloadItem: _getDownloadItem,
      networkInfo: _networkInfo,
      initialIsDownloaded: initialIsDownloaded,
      initialIsDownloading: initialIsDownloading,
      initialProgress: initialProgress,
    );
  }
}
