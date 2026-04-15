import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_image_flutter/data/services/quran_image_prewarm_service.dart';
import 'package:quran_image_flutter/domain/domain.dart';

void main() {
  test('preview prewarm keeps only the latest scrub target', () {
    fakeAsync((async) {
      final decodedCache = _FakeDecodedQuranImageCache();
      final service = QuranImagePrewarmService(
        imageCacheRepository: const _ReadyQuranImageCacheRepository(),
        decodedImageCache: decodedCache,
      );

      service.prewarmPreviewTarget(pageNumber: 101, cacheWidth: 1080);
      service.prewarmPreviewTarget(pageNumber: 202, cacheWidth: 1080);

      async.elapse(const Duration(milliseconds: 179));
      async.flushMicrotasks();
      expect(decodedCache.prewarmedLinePaths, isEmpty);

      async.elapse(const Duration(milliseconds: 1));
      async.flushMicrotasks();

      expect(
        decodedCache.prewarmedLinePaths
            .where((path) => path.startsWith('1080:page_202_line_'))
            .length,
        15,
      );
      expect(
        decodedCache.prewarmedLinePaths.where(
          (path) => path.startsWith('1080:page_101_line_'),
        ),
        isEmpty,
      );
    });
  });

  test(
    'memory pressure cancels pending preview work and clears cache state',
    () {
      fakeAsync((async) {
        final decodedCache = _FakeDecodedQuranImageCache();
        final service = QuranImagePrewarmService(
          imageCacheRepository: const _ReadyQuranImageCacheRepository(),
          decodedImageCache: decodedCache,
        );

        service.prewarmPreviewTarget(pageNumber: 303, cacheWidth: 1080);
        service.handleMemoryPressure();

        async.elapse(const Duration(seconds: 1));
        async.flushMicrotasks();

        expect(decodedCache.memoryPressureCount, 1);
        expect(decodedCache.prewarmedLinePaths, isEmpty);
      });
    },
  );
}

class _ReadyQuranImageCacheRepository implements QuranImageCacheRepository {
  const _ReadyQuranImageCacheRepository();

  @override
  QuranImageCacheStatus get status => const QuranImageCacheStatus.ready();

  @override
  String? lineImageFilePath({
    required int pageNumber,
    required int oneBasedLineNumber,
  }) => 'page_${pageNumber}_line_$oneBasedLineNumber';

  @override
  Future<QuranImageCacheStatus> prepareCache({
    void Function(QuranImageCacheStatus status)? onProgress,
  }) async {
    const status = QuranImageCacheStatus.ready();
    onProgress?.call(status);
    return status;
  }

  @override
  String? surahHeaderBannerFilePath() => 'banner';
}

class _FakeDecodedQuranImageCache implements DecodedQuranImageCache {
  final List<String> prewarmedLinePaths = <String>[];
  int memoryPressureCount = 0;

  @override
  void handleMemoryPressure() {
    memoryPressureCount++;
  }

  @override
  Future<void> prewarmFileImage(String imagePath) async {}

  @override
  Future<void> prewarmLineImage({
    required String imagePath,
    required int cacheWidth,
  }) async {
    prewarmedLinePaths.add('$cacheWidth:$imagePath');
  }
}
