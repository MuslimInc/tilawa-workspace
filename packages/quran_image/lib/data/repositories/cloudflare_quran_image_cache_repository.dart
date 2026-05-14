import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:path_provider/path_provider.dart';

import '../../core/constants/quran_image_asset_constants.dart';
import '../../core/constants/surah_header_constants.dart';
import '../../core/perf_logger.dart';
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
  static const String _logSource = 'CloudflareQuranImageCacheRepository';
  static const int _expectedLineImageCount =
      PageState.quranPageCount * SurahHeaderConstants.lineCount;
  static const List<String> _knownArchiveRootCandidates = [
    '',
    'quran_images',
    'assets/quran_images',
    'apps/quran_image/assets/quran_images',
  ];

  // -- download tuning ------------------------------------------------------

  static const Duration _connectionTimeout = Duration(seconds: 30);
  static const Duration _idleTimeout = Duration(seconds: 30);
  static const int _maxRetries = 3;
  static const Duration _retryBaseDelay = Duration(seconds: 2);
  static const Duration _statusCallbackMinInterval = Duration(
    milliseconds: 250,
  );
  static const Duration _statusCallbackMaxInterval = Duration(seconds: 1);
  static const double _statusCallbackMinProgressStep = 0.02;

  // -- state ----------------------------------------------------------------

  final QuranImageCacheDirectoryProvider _directoryProvider;
  final QuranImageFileDownloader _fileDownloader;
  final QuranImageArchiveExtractor _archiveExtractor;

  QuranImageCacheStatus _status = const QuranImageCacheStatus.checking();
  Directory? _cacheRoot;
  String _extractedRootRelativePath = '';
  Future<QuranImageCacheStatus>? _prepareFuture;
  QuranImageCachePhase? _lastLoggedStatusPhase;
  final Stopwatch _statusCallbackTimer = Stopwatch()..start();
  QuranImageCachePhase? _lastDeliveredStatusPhase;
  double _lastDeliveredStatusProgress = -1;
  int _lastDeliveredStatusMs = -_statusCallbackMaxInterval.inMilliseconds;

  // Flat key: (pageNumber - 1) * lineCount + (oneBasedLineNumber - 1)
  // Populated once on the first call for each entry after status.isReady.
  final Map<int, String> _linePathCache = {};
  String? _bannerPathCache;

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
    final key =
        (pageNumber - 1) * SurahHeaderConstants.lineCount +
        (oneBasedLineNumber - 1);
    return _linePathCache.putIfAbsent(
      key,
      () => _lineImageFile(
        cacheRoot: cacheRoot,
        extractedRootRelativePath: _extractedRootRelativePath,
        pageNumber: pageNumber,
        oneBasedLineNumber: oneBasedLineNumber,
      ).path,
    );
  }

  @override
  String? surahHeaderBannerFilePath() {
    final cacheRoot = _cacheRoot;
    if (!_status.isReady || cacheRoot == null) return null;
    return _bannerPathCache ??= _headerBannerFile(cacheRoot).path;
  }

  @override
  Future<QuranImageCacheStatus> prepareCache({
    void Function(QuranImageCacheStatus status)? onProgress,
  }) {
    final inFlight = _prepareFuture;
    if (inFlight != null) {
      _log(
        'prepare joined inFlight=true phase=${_status.phase.name} '
        'progress=${_formatPercent(_status.progress)}',
      );
      return inFlight;
    }

    _log(
      'prepare requested phase=${_status.phase.name} '
      'progress=${_formatPercent(_status.progress)}',
    );
    _prepareFuture = _prepareCache(onProgress: onProgress).whenComplete(() {
      _log('prepare future cleared phase=${_status.phase.name}');
      _prepareFuture = null;
    });
    return _prepareFuture!;
  }

  // -- preparation pipeline -------------------------------------------------

  Future<QuranImageCacheStatus> _prepareCache({
    required void Function(QuranImageCacheStatus status)? onProgress,
  }) async {
    final timer = PerfLogger.startTimer();
    try {
      _resetStatusCallbackThrottle();
      _log('prepare pipeline started');
      _emit(const QuranImageCacheStatus.checking(), onProgress);

      final baseDirectory = await _directoryProvider();
      final cacheRoot = Directory(
        _joinPath([baseDirectory.path, _cacheDirectoryName, _cacheVersion]),
      );
      _cacheRoot = cacheRoot;
      _log('cache root resolved path=${cacheRoot.path}');

      // Fast path — already fully cached.
      final readyCacheTimer = PerfLogger.startTimer();
      if (await _loadReadyCache(cacheRoot)) {
        PerfLogger.logElapsed(
          readyCacheTimer,
          widgetName: _logSource,
          message: 'ready cache validation completed result=hit',
        );
        _log(
          'ready cache hit extractedRootRelativePath='
          '$_extractedRootRelativePath',
        );
        _emit(const QuranImageCacheStatus.ready(), onProgress);
        PerfLogger.logElapsed(
          timer,
          widgetName: _logSource,
          message: 'prepare completed source=ready-cache',
        );
        return _status;
      }
      PerfLogger.logElapsed(
        readyCacheTimer,
        widgetName: _logSource,
        message: 'ready cache validation completed result=miss',
      );

      _log('ready cache miss; starting download pipeline');
      await cacheRoot.create(recursive: true);

      // _downloadAndExtract returns the resolved root so we can populate state
      // directly without re-reading metadata from disk.
      final extractedRootRelativePath = await _downloadAndExtract(
        cacheRoot: cacheRoot,
        onProgress: onProgress,
      );
      _extractedRootRelativePath = extractedRootRelativePath;

      // Spot-check boundary files to catch silent extraction failures.
      final validationTimer = PerfLogger.startTimer();
      if (!await _validateExtractedFiles(
        cacheRoot,
        extractedRootRelativePath,
      )) {
        PerfLogger.logElapsed(
          validationTimer,
          widgetName: _logSource,
          message: 'post-download validation completed result=failed',
        );
        _log(
          'post-download validation failed '
          'extractedRootRelativePath=$extractedRootRelativePath',
        );
        throw const FileSystemException(
          'Quran image cache was created but failed validation.',
        );
      }
      PerfLogger.logElapsed(
        validationTimer,
        widgetName: _logSource,
        message: 'post-download validation completed result=passed',
      );

      _log(
        'post-download validation passed '
        'extractedRootRelativePath=$extractedRootRelativePath',
      );
      _emit(const QuranImageCacheStatus.ready(), onProgress);
      PerfLogger.logElapsed(
        timer,
        widgetName: _logSource,
        message: 'prepare completed source=download',
      );
      return _status;
    } catch (error) {
      PerfLogger.logElapsed(
        timer,
        widgetName: _logSource,
        message: 'prepare failed errorType=${error.runtimeType}',
      );
      _log('prepare failed error=$error');
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
    final pipelineTimer = PerfLogger.startTimer();
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

    _log(
      'download pipeline started cacheRoot=${cacheRoot.path} '
      'archive=${archiveFile.path}',
    );

    // Clean up any previous failed staging, but preserve the .partial archive
    // so the download can be resumed via HTTP Range on retry.
    if (stagingDirectory.existsSync()) {
      _log('delete stale staging path=${stagingDirectory.path}');
      await stagingDirectory.delete(recursive: true);
    }
    await stagingDirectory.create(recursive: true);
    await imagesDirectory.create(recursive: true);
    _log(
      'staging prepared staging=${stagingDirectory.path} '
      'images=${imagesDirectory.path}',
    );

    // -- 1. Download archive (with resume support) --------------------------
    final archivePartialBytes = partialArchiveFile.existsSync()
        ? await partialArchiveFile.length()
        : 0;
    final archiveProgressLogger = _TransferProgressLogger(
      sourceName: _logSource,
      label: 'quran-images-archive',
    );
    _log(
      'archive download start url='
      '${QuranImageAssetConstants.remoteQuranImagesArchiveUrl} '
      'partialBytes=${_formatBytes(archivePartialBytes)}',
    );
    await _downloadWithRetry(
      Uri.parse(QuranImageAssetConstants.remoteQuranImagesArchiveUrl),
      partialArchiveFile,
      (receivedBytes, totalBytes) {
        archiveProgressLogger.maybeLog(receivedBytes, totalBytes);
        final progress = totalBytes == null || totalBytes <= 0
            ? 0.05
            : (receivedBytes / totalBytes).clamp(0.0, 1.0) * 0.7;
        _emitThrottled(
          QuranImageCacheStatus(
            phase: QuranImageCachePhase.downloadingImages,
            progress: progress,
          ),
          onProgress,
        );
      },
    );
    archiveProgressLogger.logCompleted(
      finalBytes: await partialArchiveFile.length(),
    );

    // Atomically promote the partial file to the final archive path.
    if (archiveFile.existsSync()) await archiveFile.delete();
    await partialArchiveFile.rename(archiveFile.path);
    _log(
      'archive promoted path=${archiveFile.path} '
      'bytes=${_formatBytes(await archiveFile.length())}',
    );

    // -- 2. Extract archive -------------------------------------------------
    var extractedEntries = 0;
    final extractionProgressLogger = _ExtractionProgressLogger(
      sourceName: _logSource,
      label: 'quran-images-archive',
      expectedEntries: _expectedLineImageCount,
    );
    _log(
      'extract start archive=${archiveFile.path} '
      'destination=${stagingDirectory.path} '
      'expectedEntries=$_expectedLineImageCount',
    );
    await _archiveExtractor(archiveFile, stagingDirectory, (entries) {
      extractedEntries = entries;
      extractionProgressLogger.maybeLog(entries);
      final extractionProgress = (entries / _expectedLineImageCount).clamp(
        0.0,
        1.0,
      );
      _emitThrottled(
        QuranImageCacheStatus(
          phase: QuranImageCachePhase.extracting,
          progress: 0.7 + extractionProgress * 0.25,
        ),
        onProgress,
      );
    });
    extractionProgressLogger.logCompleted(extractedEntries);

    // Reclaim ~104 MB — the ZIP is no longer needed after extraction.
    await _deleteIfExists(archiveFile);
    _log('archive deleted path=${archiveFile.path}');

    final extractedRootRelativePath = await _resolveExtractedRootRelativePath(
      stagingDirectory,
    );
    if (extractedRootRelativePath == null) {
      _log('archive root resolution failed staging=${stagingDirectory.path}');
      throw FileSystemException(
        'Could not find Quran PNG pages in extracted archive.',
        stagingDirectory.path,
      );
    }
    _log(
      'archive root resolved extractedRootRelativePath='
      '$extractedRootRelativePath',
    );

    // Atomically promote the staging directory.
    if (extractedDirectory.existsSync()) {
      _log('delete previous extracted path=${extractedDirectory.path}');
      await extractedDirectory.delete(recursive: true);
    }
    await stagingDirectory.rename(extractedDirectory.path);
    _log('staging promoted path=${extractedDirectory.path}');

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
    if (partialHeaderFile.existsSync()) {
      _log('delete stale header partial path=${partialHeaderFile.path}');
      await partialHeaderFile.delete();
    }

    final headerProgressLogger = _TransferProgressLogger(
      sourceName: _logSource,
      label: 'surah-header-banner',
    );
    _log(
      'header download start url='
      '${QuranImageAssetConstants.remoteSurahHeaderBannerUrl}',
    );
    await _downloadWithRetry(
      Uri.parse(QuranImageAssetConstants.remoteSurahHeaderBannerUrl),
      partialHeaderFile,
      headerProgressLogger.maybeLog,
    );
    headerProgressLogger.logCompleted(
      finalBytes: await partialHeaderFile.length(),
    );

    if (headerFile.existsSync()) await headerFile.delete();
    await partialHeaderFile.rename(headerFile.path);
    _log(
      'header promoted path=${headerFile.path} '
      'bytes=${_formatBytes(await headerFile.length())}',
    );

    // -- 4. Persist metadata ------------------------------------------------
    final metadataTimer = PerfLogger.startTimer();
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
    PerfLogger.logElapsed(
      metadataTimer,
      widgetName: _logSource,
      message: 'metadata write completed',
    );
    PerfLogger.logElapsed(
      pipelineTimer,
      widgetName: _logSource,
      message:
          'download pipeline completed '
          'extractedRootRelativePath=$extractedRootRelativePath '
          'extractedEntries=$extractedEntries',
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
      final attemptTimer = PerfLogger.startTimer();
      final existingBytes = destination.existsSync()
          ? await destination.length()
          : 0;
      _log(
        'download attempt=$attempt/$_maxRetries '
        'file=${_fileName(url)} resumeBytes=${_formatBytes(existingBytes)} '
        'destination=${destination.path}',
      );
      try {
        await _fileDownloader(url, destination, onProgress);
        PerfLogger.logElapsed(
          attemptTimer,
          widgetName: _logSource,
          message:
              'download attempt=$attempt completed '
              'file=${_fileName(url)} bytes='
              '${_formatBytes(await destination.length())}',
        );
        return;
      } on HttpException catch (error) {
        PerfLogger.logElapsed(
          attemptTimer,
          widgetName: _logSource,
          message:
              'download attempt=$attempt failed nonRetryable=true '
              'file=${_fileName(url)} errorType=${error.runtimeType}',
        );
        _log(
          'download failed nonRetryable=true file=${_fileName(url)} '
          'error=$error',
        );
        rethrow; // HTTP 4xx/5xx — not transient.
      } on IOException catch (error) {
        PerfLogger.logElapsed(
          attemptTimer,
          widgetName: _logSource,
          message:
              'download attempt=$attempt failed retryable=true '
              'file=${_fileName(url)} errorType=${error.runtimeType}',
        );
        if (attempt >= _maxRetries) rethrow;
        final retryDelay = _retryBaseDelay * attempt;
        _log(
          'download retry scheduled file=${_fileName(url)} '
          'attempt=$attempt nextAttempt=${attempt + 1} '
          'retryInMs=${retryDelay.inMilliseconds} error=$error',
        );
        await _deleteIfExists(destination);
        await Future.delayed(retryDelay);
      }
    }
  }

  // -- cache validation (cold-start fast-path only) -------------------------

  Future<bool> _loadReadyCache(Directory cacheRoot) async {
    final metadataFile = _metadataFile(cacheRoot);
    if (!metadataFile.existsSync()) {
      _log('ready cache miss reason=metadata_missing');
      return false;
    }

    final Object? metadata;
    try {
      metadata = jsonDecode(await metadataFile.readAsString());
    } catch (_) {
      _log('ready cache miss reason=metadata_invalid_json');
      return false;
    }
    if (metadata is! Map<String, dynamic>) {
      _log('ready cache miss reason=metadata_invalid_shape');
      return false;
    }

    if (metadata['archiveUrl'] !=
            QuranImageAssetConstants.remoteQuranImagesArchiveUrl ||
        metadata['surahHeaderBannerUrl'] !=
            QuranImageAssetConstants.remoteSurahHeaderBannerUrl) {
      _log('ready cache miss reason=remote_url_changed');
      return false;
    }

    final relativeRoot = metadata['extractedRootRelativePath'];
    if (relativeRoot is! String) {
      _log('ready cache miss reason=relative_root_missing');
      return false;
    }

    if (!await _validateExtractedFiles(cacheRoot, relativeRoot)) {
      _log(
        'ready cache miss reason=validation_failed '
        'extractedRootRelativePath=$relativeRoot',
      );
      return false;
    }

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
      PerfLogger.log(
        widgetName: _logSource,
        message:
            'http range requested file=${_fileName(url)} '
            'resumeBytes=${_formatBytes(existingBytes)}',
      );
    }
    final response = await request.close();

    final isResume = response.statusCode == HttpStatus.partialContent;
    final isOk = response.statusCode == HttpStatus.ok;
    PerfLogger.log(
      widgetName: _logSource,
      message:
          'http response file=${_fileName(url)} status=${response.statusCode} '
          'contentLength=${_formatOptionalBytes(response.contentLength)} '
          'resume=$isResume',
    );
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
    _rememberDeliveredStatus(status);
    _logStatusTransition(status);
  }

  void _emitThrottled(
    QuranImageCacheStatus status,
    void Function(QuranImageCacheStatus status)? onProgress,
  ) {
    _status = status;
    _logStatusTransition(status);
    if (_shouldDeliverStatus(status)) {
      onProgress?.call(status);
      _rememberDeliveredStatus(status);
    }
  }

  bool _shouldDeliverStatus(QuranImageCacheStatus status) {
    final elapsedMs = _statusCallbackTimer.elapsedMilliseconds;
    final elapsedSinceLast = elapsedMs - _lastDeliveredStatusMs;
    final phaseChanged = status.phase != _lastDeliveredStatusPhase;
    final completed = status.progress >= 1.0;
    final waitedLongEnough =
        elapsedSinceLast >= _statusCallbackMaxInterval.inMilliseconds;
    final waitedMinInterval =
        elapsedSinceLast >= _statusCallbackMinInterval.inMilliseconds;
    final progressedEnough =
        (status.progress - _lastDeliveredStatusProgress).abs() >=
        _statusCallbackMinProgressStep;

    return phaseChanged ||
        completed ||
        waitedLongEnough ||
        (waitedMinInterval && progressedEnough);
  }

  void _rememberDeliveredStatus(QuranImageCacheStatus status) {
    _lastDeliveredStatusPhase = status.phase;
    _lastDeliveredStatusProgress = status.progress;
    _lastDeliveredStatusMs = _statusCallbackTimer.elapsedMilliseconds;
  }

  void _resetStatusCallbackThrottle() {
    _statusCallbackTimer
      ..reset()
      ..start();
    _lastDeliveredStatusPhase = null;
    _lastDeliveredStatusProgress = -1;
    _lastDeliveredStatusMs = -_statusCallbackMaxInterval.inMilliseconds;
  }

  void _logStatusTransition(QuranImageCacheStatus status) {
    if (!PerfLogger.isEnabled) return;
    if (_lastLoggedStatusPhase == status.phase) return;
    _lastLoggedStatusPhase = status.phase;

    final errorMessage = status.errorMessage;
    _log(
      'status phase=${status.phase.name} '
      'progress=${_formatPercent(status.progress)}'
      '${errorMessage == null ? '' : ' error=$errorMessage'}',
    );
  }

  void _log(String message) {
    PerfLogger.log(widgetName: _logSource, message: message);
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

// ---------------------------------------------------------------------------
// Download/extraction log throttles
// ---------------------------------------------------------------------------

final class _TransferProgressLogger {
  _TransferProgressLogger({required this.sourceName, required this.label});

  static const Duration _minInterval = Duration(seconds: 1);
  static const double _minProgressStep = 0.05;
  static const int _smallTransferThresholdBytes = 1024 * 1024;

  final String sourceName;
  final String label;
  final Stopwatch _timer = Stopwatch()..start();

  int _lastLoggedMs = -_minInterval.inMilliseconds;
  double _lastLoggedProgress = -_minProgressStep;
  int _lastLoggedBytes = -1;

  void maybeLog(int receivedBytes, int? totalBytes) {
    if (!PerfLogger.isEnabled) return;

    final elapsedMs = _timer.elapsedMilliseconds;
    final progress = totalBytes == null || totalBytes <= 0
        ? null
        : (receivedBytes / totalBytes).clamp(0.0, 1.0);
    final isFirst = _lastLoggedBytes < 0;
    final waitedEnough =
        elapsedMs - _lastLoggedMs >= _minInterval.inMilliseconds;
    final isSmallTransfer =
        totalBytes != null && totalBytes < _smallTransferThresholdBytes;
    final progressedEnough =
        !isSmallTransfer &&
        progress != null &&
        progress - _lastLoggedProgress >= _minProgressStep;
    final completed = totalBytes != null && receivedBytes >= totalBytes;

    if (!isFirst && !waitedEnough && !progressedEnough && !completed) {
      return;
    }

    _lastLoggedMs = elapsedMs;
    _lastLoggedBytes = receivedBytes;
    if (progress != null) _lastLoggedProgress = progress;

    PerfLogger.log(
      widgetName: sourceName,
      message:
          'download progress label=$label '
          'progress=${progress == null ? 'unknown' : _formatPercent(progress)} '
          'received=${_formatBytes(receivedBytes)} '
          'total=${_formatOptionalBytes(totalBytes)} '
          'elapsedMs=$elapsedMs '
          'rate=${_formatBytesPerSecond(receivedBytes, _timer.elapsed)}',
    );
  }

  void logCompleted({required int finalBytes}) {
    if (!PerfLogger.isEnabled) return;

    _timer.stop();
    PerfLogger.log(
      widgetName: sourceName,
      message:
          'download completed label=$label '
          'bytes=${_formatBytes(finalBytes)} '
          'elapsedMs=${_timer.elapsedMilliseconds} '
          'avgRate=${_formatBytesPerSecond(finalBytes, _timer.elapsed)}',
    );
  }
}

final class _ExtractionProgressLogger {
  _ExtractionProgressLogger({
    required this.sourceName,
    required this.label,
    required this.expectedEntries,
  });

  static const Duration _minInterval = Duration(seconds: 1);
  static const int _minEntryStep = 500;
  static const int _extraEntryStep = 2000;

  final String sourceName;
  final String label;
  final int expectedEntries;
  final Stopwatch _timer = Stopwatch()..start();

  int _lastLoggedMs = -_minInterval.inMilliseconds;
  int _lastLoggedEntries = -_minEntryStep;
  bool _loggedExpectedReached = false;

  void maybeLog(int extractedEntries) {
    if (!PerfLogger.isEnabled) return;

    final elapsedMs = _timer.elapsedMilliseconds;
    final waitedEnough =
        elapsedMs - _lastLoggedMs >= _minInterval.inMilliseconds;
    final reachedExpected = extractedEntries >= expectedEntries;
    final expectedReachedForFirstTime =
        reachedExpected && !_loggedExpectedReached;
    final entryStep = _loggedExpectedReached ? _extraEntryStep : _minEntryStep;
    final advancedEnough = extractedEntries - _lastLoggedEntries >= entryStep;

    if (!waitedEnough && !advancedEnough && !expectedReachedForFirstTime) {
      return;
    }

    _lastLoggedMs = elapsedMs;
    _lastLoggedEntries = extractedEntries;
    if (reachedExpected) _loggedExpectedReached = true;

    PerfLogger.log(
      widgetName: sourceName,
      message:
          'extract progress label=$label '
          'progress=${_formatPercent(_safeProgress(extractedEntries, expectedEntries))} '
          'entries=$extractedEntries '
          'expectedLineImages=$expectedEntries '
          '${_formatExtraEntries(extractedEntries, expectedEntries)}'
          'elapsedMs=$elapsedMs '
          'rate=${_formatEntriesPerSecond(extractedEntries, _timer.elapsed)}',
    );
  }

  void logCompleted(int extractedEntries) {
    if (!PerfLogger.isEnabled) return;

    _timer.stop();
    PerfLogger.log(
      widgetName: sourceName,
      message:
          'extract completed label=$label '
          'entries=$extractedEntries '
          'expectedLineImages=$expectedEntries '
          '${_formatExtraEntries(extractedEntries, expectedEntries)}'
          'elapsedMs=${_timer.elapsedMilliseconds} '
          'avgRate=${_formatEntriesPerSecond(extractedEntries, _timer.elapsed)}',
    );
  }
}

String _fileName(Uri url) {
  final segments = url.pathSegments;
  return segments.isEmpty || segments.last.isEmpty
      ? url.toString()
      : segments.last;
}

String _formatPercent(num progress) {
  return '${(progress.clamp(0, 1) * 100).toStringAsFixed(1)}%';
}

String _formatBytes(int bytes) {
  const units = ['B', 'KB', 'MB', 'GB'];
  var value = bytes.toDouble();
  var unitIndex = 0;
  while (value >= 1024 && unitIndex < units.length - 1) {
    value /= 1024;
    unitIndex++;
  }
  if (unitIndex == 0) return '${value.toStringAsFixed(0)} ${units[unitIndex]}';
  return '${value.toStringAsFixed(1)} ${units[unitIndex]}';
}

String _formatOptionalBytes(int? bytes) {
  if (bytes == null || bytes <= 0) return 'unknown';
  return _formatBytes(bytes);
}

String _formatBytesPerSecond(int bytes, Duration elapsed) {
  final elapsedSeconds =
      elapsed.inMicroseconds / Duration.microsecondsPerSecond;
  if (elapsedSeconds <= 0) return 'unknown';
  return '${_formatBytes((bytes / elapsedSeconds).round())}/s';
}

String _formatEntriesPerSecond(int entries, Duration elapsed) {
  final elapsedSeconds =
      elapsed.inMicroseconds / Duration.microsecondsPerSecond;
  if (elapsedSeconds <= 0) return 'unknown';
  return '${(entries / elapsedSeconds).toStringAsFixed(1)} entries/s';
}

double _safeProgress(int completed, int expected) {
  if (expected <= 0) return 1;
  return completed / expected;
}

String _formatExtraEntries(int entries, int expectedEntries) {
  final extraEntries = entries - expectedEntries;
  if (extraEntries <= 0) return '';
  return 'extraEntries=$extraEntries ';
}
