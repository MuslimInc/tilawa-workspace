import '../entities/quran_image_cache_status.dart';
import '../repositories/quran_image_cache_repository.dart';

class PrepareQuranImageCacheUseCase {
  const PrepareQuranImageCacheUseCase(this._repository);

  final QuranImageCacheRepository _repository;

  Future<QuranImageCacheStatus> call({
    void Function(QuranImageCacheStatus status)? onProgress,
  }) {
    return _repository.prepareCache(onProgress: onProgress);
  }
}
