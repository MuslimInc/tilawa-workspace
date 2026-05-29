import 'package:tilawa_core/network/network_info.dart';

import '../../../domain/usecases/usecases.dart';
import 'download_button_bloc.dart';

/// Composes [DownloadButtonBloc] instances with injected use cases.
class DownloadButtonBlocFactory {
  const DownloadButtonBlocFactory({
    required this._checkSurahDownloaded,
    required this._downloadSurah,
    required this._cancelDownload,
    required this._pauseDownload,
    required this._resumeDownload,
    required this._observeDownloadProgress,
    required this._getDownloadItem,
    required this._networkInfo,
  });

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
