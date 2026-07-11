/// Centralised asset paths for Quran page image rendering.
class QuranImageAssetConstants {
  QuranImageAssetConstants._();

  static const String defaultArchiveLineImageRoot = 'quran_images';
  static const String lineImageExtension = 'png';
  static const String quranImagesArchiveFileName = 'quran_images.zip';
  static const String surahHeaderBannerFileName = 'sura_header_banner.webp';
  static const String remoteBaseUrl =
      'https://pub-7f6f6686010343899ba5b2f0ac6cb7b3.r2.dev';
  static const String remoteQuranImagesArchiveUrl =
      '$remoteBaseUrl/$quranImagesArchiveFileName';
  static const String remoteSurahHeaderBannerUrl =
      '$remoteBaseUrl/$surahHeaderBannerFileName';

  static String archiveLineImagePath({
    required int pageNumber,
    required int oneBasedLineNumber,
  }) {
    return '$defaultArchiveLineImageRoot/$pageNumber/'
        '$oneBasedLineNumber.$lineImageExtension';
  }
}
