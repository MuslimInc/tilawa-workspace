import '../entities/quran_image_cache_status.dart';

abstract class QuranImageCacheRepository {
  QuranImageCacheStatus get status;

  String? lineImageFilePath({
    required int pageNumber,
    required int oneBasedLineNumber,
  });

  String? surahHeaderBannerFilePath();

  Future<QuranImageCacheStatus> prepareCache({
    void Function(QuranImageCacheStatus status)? onProgress,
  });
}
