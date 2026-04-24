import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:quran_image/core/constants/quran_image_asset_constants.dart';
import 'package:quran_image/data/repositories/cloudflare_quran_image_cache_repository.dart';
import 'package:quran_image/domain/domain.dart';

void main() {
  late Directory tempDirectory;

  setUp(() async {
    tempDirectory = await Directory.systemTemp.createTemp(
      'quran_image_cache_test_',
    );
  });

  tearDown(() async {
    if (tempDirectory.existsSync()) {
      await tempDirectory.delete(recursive: true);
    }
  });

  test('downloads, extracts, and resolves cached image paths', () async {
    final statuses = <QuranImageCacheStatus>[];
    final repository = CloudflareQuranImageCacheRepository(
      directoryProvider: () async => tempDirectory,
      fileDownloader: _fakeDownloader,
      archiveExtractor: _fakeExtractorWithWrappedRoot,
    );

    final status = await repository.prepareCache(onProgress: statuses.add);

    expect(status.isReady, isTrue);
    expect(
      statuses.map((status) => status.phase),
      containsAll([
        QuranImageCachePhase.downloadingImages,
        QuranImageCachePhase.extracting,
        QuranImageCachePhase.ready,
      ]),
    );

    final linePath = repository.lineImageFilePath(
      pageNumber: 1,
      oneBasedLineNumber: 1,
    );
    expect(linePath, isNotNull);
    expect(linePath, endsWith(_platformPath('extracted/quran_images/1/1.png')));
    expect(File(linePath!).existsSync(), isTrue);

    final headerPath = repository.surahHeaderBannerFilePath();
    expect(headerPath, isNotNull);
    expect(File(headerPath!).existsSync(), isTrue);
  });

  test('uses existing metadata without downloading again', () async {
    final repository = CloudflareQuranImageCacheRepository(
      directoryProvider: () async => tempDirectory,
      fileDownloader: _fakeDownloader,
      archiveExtractor: _fakeExtractorWithWrappedRoot,
    );
    await repository.prepareCache();

    final cachedRepository = CloudflareQuranImageCacheRepository(
      directoryProvider: () async => tempDirectory,
      fileDownloader: (_, _, _) {
        throw StateError('download should not be called');
      },
      archiveExtractor: (_, _, _) {
        throw StateError('extract should not be called');
      },
    );

    final status = await cachedRepository.prepareCache();

    expect(status.isReady, isTrue);
    expect(
      cachedRepository.lineImageFilePath(
        pageNumber: 604,
        oneBasedLineNumber: 15,
      ),
      isNotNull,
    );
  });

  test('returns failed status when archive shape is invalid', () async {
    final repository = CloudflareQuranImageCacheRepository(
      directoryProvider: () async => tempDirectory,
      fileDownloader: _fakeDownloader,
      archiveExtractor: (_, destination, onProgress) async {
        await File(
          _join([destination.path, 'unexpected', '1.png']),
        ).create(recursive: true);
        onProgress(1);
      },
    );

    final status = await repository.prepareCache();

    expect(status.phase, QuranImageCachePhase.failed);
    expect(status.errorMessage, contains('Could not find Quran PNG pages'));
  });
}

Future<void> _fakeDownloader(
  Uri url,
  File destination,
  void Function(int receivedBytes, int? totalBytes) onProgress,
) async {
  await destination.parent.create(recursive: true);
  final bytes =
      url.toString() == QuranImageAssetConstants.remoteSurahHeaderBannerUrl
      ? <int>[0x52, 0x49, 0x46, 0x46]
      : <int>[0x50, 0x4B, 0x03, 0x04];
  await destination.writeAsBytes(bytes, flush: true);
  onProgress(bytes.length, bytes.length);
}

Future<void> _fakeExtractorWithWrappedRoot(
  File archive,
  Directory destination,
  void Function(int extractedEntries) onProgress,
) async {
  await File(
    _join([destination.path, 'quran_images', '1', '1.png']),
  ).create(recursive: true);
  onProgress(1);
  await File(
    _join([destination.path, 'quran_images', '604', '15.png']),
  ).create(recursive: true);
  onProgress(2);
}

String _platformPath(String path) {
  return path.replaceAll('/', Platform.pathSeparator);
}

String _join(List<String> parts) {
  return parts.join(Platform.pathSeparator);
}
