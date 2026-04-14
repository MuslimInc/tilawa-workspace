import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:path_provider/path_provider.dart';

import '../../core/constants/quran_image_asset_constants.dart';
import '../../core/constants/surah_header_constants.dart';
import '../../domain/domain.dart';
import 'quran_image_extract_isolate.dart';

// ---------------------------------------------------------------------------
// Injectable function types
// ---------------------------------------------------------------------------

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

// ---------------------------------------------------------------------------
// Repository
// ---------------------------------------------------------------------------

class CloudflareQuranImageCacheRepository implements QuranImageCacheRepository {
  CloudflareQuranImageCacheRepository({
    QuranImageCacheDirectoryProvider? directoryProvider,
    QuranImageFileDownloader? fileDownloader,
    QuranImageArchiveExtractor? archiveExtractor,
  }) : _directoryProvider = directoryProvider ?? _defaultCacheDirectoryProvider,
       _fileDownloader = fileDownloader ?? _defaultDownloadFile,
       _archiveExtractor = archiveExtractor ?? _defaultExtractArchive;

  // -- constants ------------------------------------------------------------

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

  // -- download tuning ------------------------------------------------------

  static const Duration _connectionTimeout = Duration(seconds: 30);
  static const Duration _idleTimeout = Duration(seconds: 30);
  static const int _maxRetries = 3;
  static const Duration _retryBaseDelay = Duration(seconds: 2);

  // -- state ----------------------------------------------------------------

  final QuranImageCacheDirectoryProvider _directoryProvider;
  final QuranImageFileDownloader _fileDownloader;
  final QuranImageArchiveExtractor _archiveExtractor;

  QuranImageCacheStatus _status = const QuranImageCacheStatus.checking();
  Directory? _cacheRoot;
  String _extractedRootRelativePath = '';
  Future<QuranImageCacheStatus>? _prepareFuture;

  // -- public API -----------------------------------------------------------

  @override
  QuranImageCacheStatus get status => _status;

  @override
  String? lineImageFilePath({
    required int pageNumber,
    required int oneBasedLineNumber,
  }) {
    final cacheRoot = _cacheRoot;
    if (!_status.isReady || cacheRoot == null) return null;
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
    if (!_status.isReady || cacheRoot == null) return null;
    return _headerBannerFile(cacheRoot).path;
  }

  @override
  Future<QuranImageCacheStatus> prepareCache({
    void Function(QuranImageCacheStatus status)? onProgress,
  }) {
    return _prepareFuture ??= _prepareCache(
      onProgress: onProgress,
    ).whenComplete(() => _prepareFuture = null);
  }

  // -- preparation pipeline -------------------------------------------------

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

      // Fast path — already fully cached.
      if (await _loadReadyCache(cacheRoot)) {
        _emit(const QuranImageCacheStatus.ready(), onProgress);
        return _status;
      }

      await cacheRoot.create(recursive: true);

      // _downloadAndExtract returns the resolved root so we can populate state
      // directly without re-reading metadata from disk.
      final extractedRootRelativePath = await _downloadAndExtract(
        cacheRoot: cacheRoot,
        onProgress: onProgress,
      );
      _extractedRootRelativePath = extractedRootRelativePath;

      // Spot-check boundary files to catch silent extraction failures.
      if (!await _validateExtractedFiles(
        cacheRoot,
        extractedRootRelativePath,
      )) {
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

  // -- download & extract ---------------------------------------------------

  /// Downloads the ZIP, extracts it, fetches the header banner, and writes
  /// metadata. Returns the resolved [extractedRootRelativePath].
  Future<String> _downloadAndExtract({
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

    // Clean up any previous failed staging, but preserve the .partial archive
    // so the download can be resumed via HTTP Range on retry.
    if (stagingDirectory.existsSync()) {
      await stagingDirectory.delete(recursive: true);
    }
    await stagingDirectory.create(recursive: true);
    await imagesDirectory.create(recursive: true);

    // -- 1. Download archive (with resume support) --------------------------
    await _downloadWithRetry(
      Uri.parse(QuranImageAssetConstants.remoteQuranImagesArchiveUrl),
      partialArchiveFile,
      (receivedBytes, totalBytes) {
        final progress = totalBytes == null || totalBytes <= 0
            ? 0.05
            : (receivedBytes / totalBytes).clamp(0.0, 1.0) * 0.7;
        _emit(
          QuranImageCacheStatus(
            phase: QuranImageCachePhase.downloadingImages,
            progress: progress,
          ),
          onProgress,
        );
      },
    );

    // Atomically promote the partial file to the final archive path.
    if (archiveFile.existsSync()) await archiveFile.delete();
    await partialArchiveFile.rename(archiveFile.path);

    // -- 2. Extract archive -------------------------------------------------
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
        ),
        onProgress,
      );
    });

    // Reclaim ~104 MB — the ZIP is no longer needed after extraction.
    await _deleteIfExists(archiveFile);

    final extractedRootRelativePath = await _resolveExtractedRootRelativePath(
      stagingDirectory,
    );
    if (extractedRootRelativePath == null) {
      throw FileSystemException(
        'Could not find Quran PNG pages in extracted archive.',
        stagingDirectory.path,
      );
    }

    // Atomically promote the staging directory.
    if (extractedDirectory.existsSync()) {
      await extractedDirectory.delete(recursive: true);
    }
    await stagingDirectory.rename(extractedDirectory.path);

    // -- 3. Download surah header banner ------------------------------------
    _emit(
      const QuranImageCacheStatus(
        phase: QuranImageCachePhase.downloadingHeader,
        progress: 0.97,
      ),
      onProgress,
    );

    final headerFile = _headerBannerFile(cacheRoot);
    final partialHeaderFile = File('${headerFile.path}.partial');
    if (partialHeaderFile.existsSync()) await partialHeaderFile.delete();

    await _downloadWithRetry(
      Uri.parse(QuranImageAssetConstants.remoteSurahHeaderBannerUrl),
      partialHeaderFile,
      (_, _) {},
    );

    if (headerFile.existsSync()) await headerFile.delete();
    await partialHeaderFile.rename(headerFile.path);

    // -- 4. Persist metadata ------------------------------------------------
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

    return extractedRootRelativePath;
  }

  // -- retry wrapper --------------------------------------------------------

  Future<void> _downloadWithRetry(
    Uri url,
    File destination,
    void Function(int receivedBytes, int? totalBytes) onProgress,
  ) async {
    for (var attempt = 1; attempt <= _maxRetries; attempt++) {
      try {
        await _fileDownloader(url, destination, onProgress);
        return;
      } on HttpException {
        rethrow; // HTTP 4xx/5xx — not transient.
      } on IOException {
        if (attempt >= _maxRetries) rethrow;
        await _deleteIfExists(destination);
        await Future.delayed(_retryBaseDelay * attempt);
      }
    }
  }

  // -- cache validation (cold-start fast-path only) -------------------------

  Future<bool> _loadReadyCache(Directory cacheRoot) async {
    final metadataFile = _metadataFile(cacheRoot);
    if (!metadataFile.existsSync()) return false;

    final Object? metadata;
    try {
      metadata = jsonDecode(await metadataFile.readAsString());
    } catch (_) {
      return false;
    }
    if (metadata is! Map<String, dynamic>) return false;

    if (metadata['archiveUrl'] !=
            QuranImageAssetConstants.remoteQuranImagesArchiveUrl ||
        metadata['surahHeaderBannerUrl'] !=
            QuranImageAssetConstants.remoteSurahHeaderBannerUrl) {
      return false;
    }

    final relativeRoot = metadata['extractedRootRelativePath'];
    if (relativeRoot is! String) return false;

    if (!await _validateExtractedFiles(cacheRoot, relativeRoot)) return false;

    _extractedRootRelativePath = relativeRoot;
    return true;
  }

  /// Spot-checks the first and last line images plus the header banner.
  Future<bool> _validateExtractedFiles(
    Directory cacheRoot,
    String extractedRootRelativePath,
  ) async {
    return _lineImageFile(
          cacheRoot: cacheRoot,
          extractedRootRelativePath: extractedRootRelativePath,
          pageNumber: 1,
          oneBasedLineNumber: 1,
        ).existsSync() &&
        _lineImageFile(
          cacheRoot: cacheRoot,
          extractedRootRelativePath: extractedRootRelativePath,
          pageNumber: PageState.quranPageCount,
          oneBasedLineNumber: SurahHeaderConstants.lineCount,
        ).existsSync() &&
        _headerBannerFile(cacheRoot).existsSync();
  }

  // -- archive root resolution ----------------------------------------------

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
    return File(
          _joinPath([
            extractionRoot.path,
            if (relativeRoot.isNotEmpty) relativeRoot,
            '1',
            '1.png',
          ]),
        ).existsSync() &&
        File(
          _joinPath([
            extractionRoot.path,
            if (relativeRoot.isNotEmpty) relativeRoot,
            PageState.quranPageCount.toString(),
            '${SurahHeaderConstants.lineCount}.png',
          ]),
        ).existsSync();
  }

  // -- shared HTTP client ---------------------------------------------------

  static HttpClient? _sharedClient;

  static HttpClient get _httpClient {
    return _sharedClient ??= HttpClient()
      ..connectionTimeout = _connectionTimeout
      ..idleTimeout = _idleTimeout;
  }

  // -- default downloader (with resume support) -----------------------------

  static Future<void> _defaultDownloadFile(
    Uri url,
    File destination,
    void Function(int receivedBytes, int? totalBytes) onProgress,
  ) async {
    final existingBytes = destination.existsSync()
        ? await destination.length()
        : 0;

    final request = await _httpClient.getUrl(url);
    if (existingBytes > 0) {
      request.headers.set(HttpHeaders.rangeHeader, 'bytes=$existingBytes-');
    }
    final response = await request.close();

    final isResume = response.statusCode == HttpStatus.partialContent;
    final isOk = response.statusCode == HttpStatus.ok;
    if (!isResume && !isOk) {
      await response.drain<void>();
      throw HttpException(
        'Download failed with HTTP ${response.statusCode}',
        uri: url,
      );
    }

    await destination.parent.create(recursive: true);
    final sink = destination.openWrite(
      mode: isResume ? FileMode.append : FileMode.write,
    );
    var receivedBytes = isResume ? existingBytes : 0;
    final totalBytes = response.contentLength > 0
        ? response.contentLength + (isResume ? existingBytes : 0)
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
  }

  // -- default extractor (with incremental progress via isolate) ------------

  static Future<void> _defaultExtractArchive(
    File archive,
    Directory destination,
    void Function(int extractedEntries) onProgress,
  ) async {
    await destination.create(recursive: true);
    onProgress(0);

    final receivePort = ReceivePort();
    await Isolate.spawn(
      extractIsolateEntryPoint,
      ExtractMessage(
        archivePath: archive.path,
        destinationPath: destination.path,
        sendPort: receivePort.sendPort,
      ),
    );

    await for (final message in receivePort) {
      if (message is int) {
        onProgress(message);
      } else if (message is ExtractDone) {
        receivePort.close();
        if (message.error != null) throw Exception(message.error);
        break;
      }
    }
  }

  // -- helpers --------------------------------------------------------------

  void _emit(
    QuranImageCacheStatus status,
    void Function(QuranImageCacheStatus status)? onProgress,
  ) {
    _status = status;
    onProgress?.call(status);
  }

  static Future<void> _deleteIfExists(File file) async {
    if (file.existsSync()) await file.delete();
  }

  static Future<Directory> _defaultCacheDirectoryProvider() async {
    return getApplicationSupportDirectory();
  }

  static File _metadataFile(Directory cacheRoot) =>
      File(_joinPath([cacheRoot.path, _metadataFileName]));

  static File _headerBannerFile(Directory cacheRoot) => File(
    _joinPath([
      cacheRoot.path,
      _imagesDirectoryName,
      QuranImageAssetConstants.surahHeaderBannerFileName,
    ]),
  );

  static File _lineImageFile({
    required Directory cacheRoot,
    required String extractedRootRelativePath,
    required int pageNumber,
    required int oneBasedLineNumber,
  }) => File(
    _joinPath([
      cacheRoot.path,
      _extractedDirectoryName,
      if (extractedRootRelativePath.isNotEmpty) extractedRootRelativePath,
      pageNumber.toString(),
      '$oneBasedLineNumber.png',
    ]),
  );

  static String _joinPath(List<String> parts) =>
      parts.where((p) => p.isNotEmpty).join(Platform.pathSeparator);
}
