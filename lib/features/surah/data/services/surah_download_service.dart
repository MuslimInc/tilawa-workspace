import 'dart:async';

import '../../../downloads/data/services/download_service.dart';
import '../../../downloads/domain/entities/download_item.dart';
import '../../domain/repositories/surah_repository.dart';

class SurahDownloadService {
  SurahDownloadService({required this.downloadService});

  final DownloadService downloadService;

  static final Map<String, StreamSubscription> _progressSubscriptions = {};

  /// Start listening to download progress for a surah
  void startListeningToProgress(
    String surahId,
    String reciterName,
    SurahRepository surahRepository,
  ) {
    final downloadId = '${surahId}_${reciterName.replaceAll(' ', '_')}';

    // Cancel existing subscription if any
    _progressSubscriptions[downloadId]?.cancel();

    _progressSubscriptions[downloadId] = downloadService.globalProgressStream
        .where((progress) => progress.id == downloadId)
        .listen((progress) async {
          await surahRepository.updateSurahDownloadProgress(
            surahId,
            reciterName,
            progress.status == DownloadStatus.downloading,
            progress.progress,
            progress.id,
          );

          // If download completed, update the final status
          if (progress.status == DownloadStatus.completed) {
            await surahRepository.updateSurahDownloadStatus(
              surahId,
              reciterName,
              true,
            );
            // Cancel subscription after completion
            await _progressSubscriptions[downloadId]?.cancel();
            _progressSubscriptions.remove(downloadId);
          } else if (progress.status == DownloadStatus.failed ||
              progress.status == DownloadStatus.cancelled) {
            await surahRepository.updateSurahDownloadProgress(
              surahId,
              reciterName,
              false,
              0.0,
              null,
            );
            // Cancel subscription after failure/cancellation
            await _progressSubscriptions[downloadId]?.cancel();
            _progressSubscriptions.remove(downloadId);
          }
        });
  }

  /// Stop listening to download progress for a surah
  static void stopListeningToProgress(String surahId, String reciterName) {
    final downloadId = '${surahId}_${reciterName.replaceAll(' ', '_')}';
    _progressSubscriptions[downloadId]?.cancel();
    _progressSubscriptions.remove(downloadId);
  }

  /// Stop all progress subscriptions
  static void stopAllProgressSubscriptions() {
    for (final StreamSubscription<dynamic> subscription
        in _progressSubscriptions.values) {
      subscription.cancel();
    }
    _progressSubscriptions.clear();
  }
}
