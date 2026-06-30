import 'dart:async';
import 'dart:typed_data';

import 'package:fake_async/fake_async.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_image/data/services/quran_image_prewarm_service.dart';
import 'package:quran_image/domain/domain.dart';

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

  test(
    'cancel ignores stale in-flight page readiness and forces a fresh warm',
    () async {
      final decodedCache = _ControllableDecodedQuranImageCache();
      final service = QuranImagePrewarmService(
        imageCacheRepository: const _ReadyQuranImageCacheRepository(),
        decodedImageCache: decodedCache,
      );

      final firstWarm = service.ensurePageReady(
        pageNumber: 77,
        cacheWidth: 1080,
      );
      // Each completion wave unlocks the next internal warm batch.
      // These counts intentionally track the current _warmBatchSize of 5.
      expect(decodedCache.prewarmRequests.length, 5);

      service.cancel();

      decodedCache.completePending();
      await Future<void>.delayed(Duration.zero);
      expect(decodedCache.prewarmRequests.length, 10);

      decodedCache.completePending();
      await Future<void>.delayed(Duration.zero);
      expect(decodedCache.prewarmRequests.length, 15);

      decodedCache.completePending();
      await firstWarm;

      final secondWarm = service.ensurePageReady(
        pageNumber: 77,
        cacheWidth: 1080,
      );
      expect(decodedCache.prewarmRequests.length, 20);

      decodedCache.completePending();
      await Future<void>.delayed(Duration.zero);
      decodedCache.completePending();
      await Future<void>.delayed(Duration.zero);
      decodedCache.completePending();
      await secondWarm;
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
  ImageProvider<Object> fileImageProvider({required String imagePath}) {
    return MemoryImage(Uint8List(0));
  }

  @override
  ImageProvider<Object> lineImageProvider({
    required String imagePath,
    required int cacheWidth,
  }) {
    return MemoryImage(Uint8List(0));
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

class _ControllableDecodedQuranImageCache implements DecodedQuranImageCache {
  final List<String> prewarmRequests = <String>[];
  final List<Completer<void>> _pending = <Completer<void>>[];

  @override
  void handleMemoryPressure() {}

  @override
  ImageProvider<Object> fileImageProvider({required String imagePath}) {
    return MemoryImage(Uint8List(0));
  }

  @override
  ImageProvider<Object> lineImageProvider({
    required String imagePath,
    required int cacheWidth,
  }) {
    return MemoryImage(Uint8List(0));
  }

  @override
  Future<void> prewarmFileImage(String imagePath) async {}

  @override
  Future<void> prewarmLineImage({
    required String imagePath,
    required int cacheWidth,
  }) {
    prewarmRequests.add('$cacheWidth:$imagePath');
    final completer = Completer<void>();
    _pending.add(completer);
    return completer.future;
  }

  void completePending() {
    final pending = List<Completer<void>>.from(_pending);
    _pending.clear();
    for (final completer in pending) {
      if (!completer.isCompleted) {
        completer.complete();
      }
    }
  }
}
