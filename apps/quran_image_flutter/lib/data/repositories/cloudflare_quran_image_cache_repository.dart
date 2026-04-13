import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:archive/archive_io.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/constants/quran_image_asset_constants.dart';
import '../../core/constants/surah_header_constants.dart';
import '../../domain/domain.dart';

typedef QuranImageCacheDirectoryProvider = Future<Directory> Function();
typedef QuranImageFileDownloader =
    Future<void> Function(
      Uri url,
      File destination,
      void Function(int receivedBytes, int? totalBytes) onProgress,
    );
typedef QuranImageArchiveExtractor =
    Future<void> Function(
      File archive,
      Directory destination,
      void Function(int extractedEntries) onProgress,
    );

class CloudflareQuranImageCacheRepository implements QuranImageCacheRepository {
  CloudflareQuranImageCacheRepository({
    QuranImageCacheDirectoryProvider? directoryProvider,
    QuranImageFileDownloader? fileDownloader,
    QuranImageArchiveExtractor? archiveExtractor,
  }) : _directoryProvider = directoryProvider ?? _defaultCacheDirectoryProvider,
       _fileDownloader = fileDownloader ?? _downloadFile,
       _archiveExtractor = archiveExtractor ?? _extractArchive;

  static const String _cacheVersion = 'v1';
  static const String _cacheDirectoryName = 'quran_image_cache';
  static const String _metadataFileName = 'cache_metadata.json';
  static const String _extractedDirectoryName = 'extracted';
  static const String _stagingDirectoryName = 'extracting';
  static const String _imagesDirectoryName = 'images';
  static const int _expectedLineImageCount =
      PageState.quranPageCount * SurahHeaderConstants.lineCount;
  static const List<String> _knownArchiveRootCandidates = [
    '',
    'quran_images',
    'assets/quran_images',
    'apps/quran_image_flutter/assets/quran_images',
  ];

  final QuranImageCacheDirectoryProvider _directoryProvider;
  final QuranImageFileDownloader _fileDownloader;
  final QuranImageArchiveExtractor _archiveExtractor;

  QuranImageCacheStatus _status = const QuranImageCacheStatus.checking();
  Directory? _cacheRoot;
  String _extractedRootRelativePath = '';
  Future<QuranImageCacheStatus>? _prepareFuture;

  @override
  QuranImageCacheStatus get status => _status;

  @override
  String? lineImageFilePath({
    required int pageNumber,
    required int oneBasedLineNumber,
  }) {
    final cacheRoot = _cacheRoot;
    if (!_status.isReady || cacheRoot == null) {
      return null;
    }

    return _lineImageFile(
      cacheRoot: cacheRoot,
      extractedRootRelativePath: _extractedRootRelativePath,
      pageNumber: pageNumber,
      oneBasedLineNumber: oneBasedLineNumber,
    ).path;
  }

  @override
  String? surahHeaderBannerFilePath() {
    final cacheRoot = _cacheRoot;
    if (!_status.isReady || cacheRoot == null) {
      return null;
    }
    return _headerBannerFile(cacheRoot).path;
  }

  @override
  Future<QuranImageCacheStatus> prepareCache({
    void Function(QuranImageCacheStatus status)? onProgress,
  }) {
    return _prepareFuture ??= _prepareCache(onProgress: onProgress)
        .whenComplete(() {
          _prepareFuture = null;
        });
  }

  Future<QuranImageCacheStatus> _prepareCache({
    required void Function(QuranImageCacheStatus status)? onProgress,
  }) async {
    try {
      _emit(const QuranImageCacheStatus.checking(), onProgress);

      final baseDirectory = await _directoryProvider();
      final cacheRoot = Directory(
        _joinPath([baseDirectory.path, _cacheDirectoryName, _cacheVersion]),
      );
      _cacheRoot = cacheRoot;

      if (await _loadReadyCache(cacheRoot)) {
        _emit(const QuranImageCacheStatus.ready(), onProgress);
        return _status;
      }

      await cacheRoot.create(recursive: true);
      await _downloadAndExtract(cacheRoot: cacheRoot, onProgress: onProgress);

      if (!await _loadReadyCache(cacheRoot)) {
        throw const FileSystemException(
          'Quran image cache was created but failed validation.',
        );
      }

      _emit(const QuranImageCacheStatus.ready(), onProgress);
      return _status;
    } catch (error) {
      _emit(QuranImageCacheStatus.failed(error.toString()), onProgress);
      return _status;
    }
  }

  Future<void> _downloadAndExtract({
    required Directory cacheRoot,
    required void Function(QuranImageCacheStatus status)? onProgress,
  }) async {
    final archiveFile = File(
      _joinPath([
        cacheRoot.path,
        QuranImageAssetConstants.quranImagesArchiveFileName,
      ]),
    );
    final partialArchiveFile = File('${archiveFile.path}.partial');
    final stagingDirectory = Directory(
      _joinPath([cacheRoot.path, _stagingDirectoryName]),
    );
    final extractedDirectory = Directory(
      _joinPath([cacheRoot.path, _extractedDirectoryName]),
    );
    final imagesDirectory = Directory(
      _joinPath([cacheRoot.path, _imagesDirectoryName]),
    );

    if (await partialArchiveFile.exists()) {
      await partialArchiveFile.delete();
    }
    if (await stagingDirectory.exists()) {
      await stagingDirectory.delete(recursive: true);
    }
    await stagingDirectory.create(recursive: true);
    await imagesDirectory.create(recursive: true);

    await _fileDownloader(
      Uri.parse(QuranImageAssetConstants.remoteQuranImagesArchiveUrl),
      partialArchiveFile,
      (receivedBytes, totalBytes) {
        final progress = totalBytes == null || totalBytes <= 0
            ? 0.05
            : (receivedBytes / totalBytes).clamp(0.0, 1.0) * 0.7;
        _emit(
          QuranImageCacheStatus(
            phase: QuranImageCachePhase.downloading,
            progress: progress,
            message: 'Downloading Quran images...',
          ),
          onProgress,
        );
      },
    );
    if (await archiveFile.exists()) {
      await archiveFile.delete();
    }
    await partialArchiveFile.rename(archiveFile.path);

    var extractedEntries = 0;
    await _archiveExtractor(archiveFile, stagingDirectory, (entries) {
      extractedEntries = entries;
      final extractionProgress = (entries / _expectedLineImageCount).clamp(
        0.0,
        1.0,
      );
      _emit(
        QuranImageCacheStatus(
          phase: QuranImageCachePhase.extracting,
          progress: 0.7 + extractionProgress * 0.25,
          message: 'Preparing Quran images...',
        ),
        onProgress,
      );
    });

    final extractedRootRelativePath = await _resolveExtractedRootRelativePath(
      stagingDirectory,
    );
    if (extractedRootRelativePath == null) {
      throw FileSystemException(
        'Could not find Quran PNG pages in extracted archive.',
        stagingDirectory.path,
      );
    }

    if (await extractedDirectory.exists()) {
      await extractedDirectory.delete(recursive: true);
    }
    await stagingDirectory.rename(extractedDirectory.path);
    _extractedRootRelativePath = extractedRootRelativePath;

    _emit(
      QuranImageCacheStatus(
        phase: QuranImageCachePhase.downloading,
        progress: 0.97,
        message: 'Downloading Surah header banner...',
      ),
      onProgress,
    );

    final partialHeaderFile = File(
      '${_headerBannerFile(cacheRoot).path}.partial',
    );
    if (await partialHeaderFile.exists()) {
      await partialHeaderFile.delete();
    }
    await _fileDownloader(
      Uri.parse(QuranImageAssetConstants.remoteSurahHeaderBannerUrl),
      partialHeaderFile,
      (_, _) {},
    );
    final headerFile = _headerBannerFile(cacheRoot);
    if (await headerFile.exists()) {
      await headerFile.delete();
    }
    await partialHeaderFile.rename(headerFile.path);

    await _metadataFile(cacheRoot).writeAsString(
      jsonEncode({
        'version': _cacheVersion,
        'archiveUrl': QuranImageAssetConstants.remoteQuranImagesArchiveUrl,
        'surahHeaderBannerUrl':
            QuranImageAssetConstants.remoteSurahHeaderBannerUrl,
        'extractedRootRelativePath': extractedRootRelativePath,
        'expectedLineImageCount': _expectedLineImageCount,
        'extractedEntries': extractedEntries,
      }),
      flush: true,
    );
  }

  Future<bool> _loadReadyCache(Directory cacheRoot) async {
    final metadataFile = _metadataFile(cacheRoot);
    if (!await metadataFile.exists()) {
      return false;
    }

    final Object? metadata;
    try {
      metadata = jsonDecode(await metadataFile.readAsString());
    } catch (_) {
      return false;
    }
    if (metadata is! Map<String, dynamic>) {
      return false;
    }

    if (metadata['archiveUrl'] !=
            QuranImageAssetConstants.remoteQuranImagesArchiveUrl ||
        metadata['surahHeaderBannerUrl'] !=
            QuranImageAssetConstants.remoteSurahHeaderBannerUrl) {
      return false;
    }

    final relativeRoot = metadata['extractedRootRelativePath'];
    if (relativeRoot is! String) {
      return false;
    }

    _extractedRootRelativePath = relativeRoot;

    return await _lineImageFile(
          cacheRoot: cacheRoot,
          extractedRootRelativePath: relativeRoot,
          pageNumber: 1,
          oneBasedLineNumber: 1,
        ).exists() &&
        await _lineImageFile(
          cacheRoot: cacheRoot,
          extractedRootRelativePath: relativeRoot,
          pageNumber: PageState.quranPageCount,
          oneBasedLineNumber: SurahHeaderConstants.lineCount,
        ).exists() &&
        await _headerBannerFile(cacheRoot).exists();
  }

  Future<String?> _resolveExtractedRootRelativePath(Directory root) async {
    for (final candidate in _knownArchiveRootCandidates) {
      if (await _containsExpectedLineImages(root, candidate)) {
        return candidate;
      }
    }
    return null;
  }

  Future<bool> _containsExpectedLineImages(
    Directory extractionRoot,
    String relativeRoot,
  ) async {
    return await File(
          _joinPath([
            extractionRoot.path,
            if (relativeRoot.isNotEmpty) relativeRoot,
            '1',
            '1.png',
          ]),
        ).exists() &&
        await File(
          _joinPath([
            extractionRoot.path,
            if (relativeRoot.isNotEmpty) relativeRoot,
            PageState.quranPageCount.toString(),
            '${SurahHeaderConstants.lineCount}.png',
          ]),
        ).exists();
  }

  void _emit(
    QuranImageCacheStatus status,
    void Function(QuranImageCacheStatus status)? onProgress,
  ) {
    _status = status;
    onProgress?.call(status);
  }

  static Future<Directory> _defaultCacheDirectoryProvider() async {
    return getApplicationSupportDirectory();
  }

  static Future<void> _downloadFile(
    Uri url,
    File destination,
    void Function(int receivedBytes, int? totalBytes) onProgress,
  ) async {
    final client = HttpClient();
    try {
      final request = await client.getUrl(url);
      final response = await request.close();
      if (response.statusCode < HttpStatus.ok ||
          response.statusCode >= HttpStatus.multipleChoices) {
        throw HttpException(
          'Download failed with HTTP ${response.statusCode}',
          uri: url,
        );
      }

      await destination.parent.create(recursive: true);
      final sink = destination.openWrite();
      var receivedBytes = 0;
      final totalBytes = response.contentLength > 0
          ? response.contentLength
          : null;

      try {
        await for (final chunk in response) {
          receivedBytes += chunk.length;
          sink.add(chunk);
          onProgress(receivedBytes, totalBytes);
        }
      } finally {
        await sink.close();
      }
    } finally {
      client.close(force: true);
    }
  }

  static Future<void> _extractArchive(
    File archive,
    Directory destination,
    void Function(int extractedEntries) onProgress,
  ) async {
    await destination.create(recursive: true);
    onProgress(0);
    await Isolate.run(() async {
      await extractFileToDisk(archive.path, destination.path);
    });
    onProgress(_expectedLineImageCount);
  }

  static File _metadataFile(Directory cacheRoot) {
    return File(_joinPath([cacheRoot.path, _metadataFileName]));
  }

  static File _headerBannerFile(Directory cacheRoot) {
    return File(
      _joinPath([
        cacheRoot.path,
        _imagesDirectoryName,
        QuranImageAssetConstants.surahHeaderBannerFileName,
      ]),
    );
  }

  static File _lineImageFile({
    required Directory cacheRoot,
    required String extractedRootRelativePath,
    required int pageNumber,
    required int oneBasedLineNumber,
  }) {
    return File(
      _joinPath([
        cacheRoot.path,
        _extractedDirectoryName,
        if (extractedRootRelativePath.isNotEmpty) extractedRootRelativePath,
        pageNumber.toString(),
        '$oneBasedLineNumber.png',
      ]),
    );
  }

  static String _joinPath(List<String> parts) {
    return parts.where((part) => part.isNotEmpty).join(Platform.pathSeparator);
  }
}
