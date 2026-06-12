/// Conservative byte estimates for download storage checks.
abstract final class DownloadStorageEstimates {
  /// Typical MP3 size for one surah.
  static const int averageSurahBytes = 8 * 1024 * 1024;

  /// Headroom for long surahs (e.g. Al-Baqarah).
  static const int maxSurahBytes = 60 * 1024 * 1024;

  /// Extra buffer when enqueueing many surahs at once.
  static const int batchSafetyMarginBytes = 50 * 1024 * 1024;

  /// Floor for low-storage warnings (aligned with typical OS "running out" UX).
  static const int minimumFreeBytes = 500 * 1024 * 1024;
}
