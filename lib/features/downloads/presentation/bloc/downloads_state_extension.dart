import '../../domain/entities/download_item.dart';
import 'downloads_bloc.dart';

/// Extension methods for DownloadsState to provide helper functions
extension DownloadsStateX on DownloadsState {
  /// Check if state is in initial status
  bool get isInitial => status == DownloadsStateStatus.initial;

  /// Check if state is loading
  bool get isLoading => status == DownloadsStateStatus.loading;

  /// Check if state has loaded data
  bool get isLoaded => status == DownloadsStateStatus.loaded;

  /// Check if state has an error
  bool get isError => status == DownloadsStateStatus.error;

  /// Get a specific download item by surahId and reciterName
  DownloadItem? getDownload(String surahId, String reciterName) {
    if (!isLoaded) {
      return null;
    }

    return _findDownloadInMap(downloads, surahId, reciterName);
  }

  /// Helper method to find a download in the nested map structure
  DownloadItem? _findDownloadInMap(
    Map<String, Map<String, List<DownloadItem>>> downloadsByReciter,
    String surahId,
    String reciterName,
  ) {
    final Map<String, List<DownloadItem>>? reciterNarratives =
        downloadsByReciter[reciterName];
    if (reciterNarratives == null) {
      return null;
    }

    try {
      // Flatten all narratives for this reciter
      final Iterable<DownloadItem> allDownloads = reciterNarratives.values
          .expand((x) => x);
      // Find the download using Simple ID (surahId == url)
      return allDownloads.firstWhere((download) => download.id == surahId);
    } catch (_) {
      return null;
    }
  }
}
