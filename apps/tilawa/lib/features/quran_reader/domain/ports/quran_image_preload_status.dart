/// Whether the `quran_image` cache is ready for the image-based reader.
abstract class QuranImagePreloadStatus {
  /// `true` when verse markers and page images are initialized.
  bool get isReady;
}
