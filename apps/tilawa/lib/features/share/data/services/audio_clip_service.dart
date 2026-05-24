import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:path/path.dart' as p;
import 'package:tilawa_core/logger.dart';

import '../../domain/entities/audio_clip_config.dart';
import '../../domain/entities/share_limits.dart';
import '../../domain/entities/share_progress_messages.dart';
import '../../domain/services/reciter_audio_catalog.dart';
import '../ffmpeg/ffmpeg_runner.dart';
import '../utils/share_cancel_token_bridge.dart';
import 'ayah_timing_service.dart';
import 'share_file_manager.dart';

/// Downloads verse-level audio files and concatenates them into a single MP3 clip.
@lazySingleton
class AudioClipService {
  AudioClipService(this._dio, this._fileManager, this._timingService, this._runner);

  final Dio _dio;
  final ShareFileManager _fileManager;
  final AyahTimingService _timingService;
  final FFmpegRunner _runner;

  /// Maximum number of verses allowed per clip.
  static const maxVerses = ShareLimits.maxVersesPerClip;

  /// Maximum concurrent downloads.
  static const _maxConcurrency = 5;

  /// Per-file download timeout.
  static const _downloadTimeout = Duration(seconds: 15);

  /// Max retries per verse.
  static const _maxRetries = 3;
  static const int _millisecondsPerSecond = Duration.millisecondsPerSecond;
  static const double _initialProgress = 0.0;
  static const double _timingLookupProgress = 0.1;
  static const double _trimProgress = 0.5;
  static const double _onlineDownloadProgressShare = 0.9;
  static const double _onlineAssemblyProgress = 0.95;
  static const double _completeProgress = 1.0;

  /// Resolves the effective verse range for a duration-constrained clip.
  Future<AudioClipConfig> resolveConfigForDuration({
    required AudioClipConfig config,
    int? maxDurationSeconds,
  }) async {
    if (maxDurationSeconds == null || maxDurationSeconds <= 0) {
      return config;
    }

    final recitationId = ReciterAudioCatalog.resolveRecitationId(
      config.serverUrl,
    );
    if (recitationId == null) return config;

    try {
      final timings = await _timingService.getSurahTimings(
        recitationId: recitationId,
        surahNumber: config.surahNumber,
      );
      if (timings.isEmpty) return config;

      final rangeTimings = timings
          .where(
            (timing) =>
                timing.ayahNumber >= config.fromAyah &&
                timing.ayahNumber <= config.toAyah,
          )
          .toList();
      if (rangeTimings.isEmpty) return config;

      final maxDurationMs = maxDurationSeconds * _millisecondsPerSecond;
      final startTimeMs = rangeTimings.first.startTimeMs;
      var resolvedToAyah = config.fromAyah;

      for (final timing in rangeTimings) {
        final elapsedMs = timing.endTimeMs - startTimeMs;
        if (elapsedMs <= maxDurationMs) {
          resolvedToAyah = timing.ayahNumber;
        } else {
          break;
        }
      }

      return config.copyWith(toAyah: resolvedToAyah);
    } catch (_) {
      return config;
    }
  }

  /// Generates an audio clip for a range of ayahs.
  ///
  /// If [localSurahPath] is provided, it uses FFmpeg to trim the local file.
  /// Otherwise, it downloads individual verses and concatenates them.
  Future<String> generateAudioClip(
    AudioClipConfig config, {
    String? localSurahPath,
    required AudioClipProgressMessages progressMessages,
    void Function(double progress, String message)? onProgress,
    ShareCancelTokenBridge? cancelToken,
  }) async {
    logger.d(
      '[AppLaunch] source=AudioClipService.generateAudioClip: Start in (${DateTime.now()})',
    );
    if (localSurahPath != null && File(localSurahPath).existsSync()) {
      return _generateFromLocalFile(
        config,
        localSurahPath,
        progressMessages,
        onProgress,
      );
    }
    return _generateFromOnlineVerses(
      config: config,
      progressMessages: progressMessages,
      onProgress: onProgress,
      cancelToken: cancelToken,
    );
  }

  Future<String> _generateFromLocalFile(
    AudioClipConfig config,
    String localPath,
    AudioClipProgressMessages progressMessages,
    void Function(double progress, String message)? onProgress,
  ) async {
    onProgress?.call(
      _initialProgress,
      progressMessages.preparingToTrimLocalAudio,
    );

    final recitationId = ReciterAudioCatalog.resolveRecitationId(
      config.serverUrl,
    );
    if (recitationId == null) {
      // Fallback to online verse download if we can't get timings
      onProgress?.call(
        _initialProgress,
        progressMessages.reciterNotSupportedForLocalTrim,
      );
      return _generateFromOnlineVerses(
        config: config,
        progressMessages: progressMessages,
        onProgress: onProgress,
      );
    }

    onProgress?.call(
      _timingLookupProgress,
      progressMessages.fetchingAyahTimings,
    );
    final timings = await _timingService.getSurahTimings(
      recitationId: recitationId,
      surahNumber: config.surahNumber,
    );

    if (timings.isEmpty) {
      onProgress?.call(_initialProgress, progressMessages.noTimingsFound);
      return _generateFromOnlineVerses(
        config: config,
        progressMessages: progressMessages,
        onProgress: onProgress,
      );
    }

    final rangeTimings = timings
        .where(
          (t) =>
              t.ayahNumber >= config.fromAyah && t.ayahNumber <= config.toAyah,
        )
        .toList();

    if (rangeTimings.isEmpty) {
      onProgress?.call(
        _initialProgress,
        progressMessages.noTimingsFoundForRange,
      );
      return _generateFromOnlineVerses(
        config: config,
        progressMessages: progressMessages,
        onProgress: onProgress,
      );
    }

    final startTime = rangeTimings.first.startSeconds;
    final endTime = rangeTimings.last.endSeconds;

    final shareDir = await _fileManager.getShareDirectory();
    final s = config.surahNumber.toString().padLeft(3, '0');
    final outputFileName =
        'trimmed_${config.reciterFolder}_${s}_${config.fromAyah}-${config.toAyah}.mp3';
    final outputPath = p.join(shareDir.path, outputFileName);

    onProgress?.call(_trimProgress, progressMessages.trimmingAudio);
    try {
      await _trimWithFFmpeg(localPath, startTime, endTime, outputPath, config);
    } catch (_) {
      return _generateFromOnlineVerses(
        config: config,
        progressMessages: progressMessages,
        onProgress: onProgress,
      );
    }
    onProgress?.call(_completeProgress, progressMessages.done);

    return outputPath;
  }

  Future<void> _trimWithFFmpeg(
    String inputPath,
    double start,
    double end,
    String outputPath,
    AudioClipConfig config,
  ) async {
    final s = config.surahNumber.toString().padLeft(3, '0');
    final title = 'Surah $s (${config.fromAyah}-${config.toAyah})';

    // FFmpeg command with metadata
    final result = await _runner.execute(
      '-i "$inputPath" -ss $start -to $end -acodec copy '
      '-metadata title="$title" '
      '-metadata artist="${config.reciterName}" '
      '-metadata album="Tilawa" '
      '-y "$outputPath"',
    );

    if (!result.isSuccess) {
      throw StateError(
        'FFmpeg trimming failed. Logs: ${result.logs}',
      );
    }
  }

  /// Downloads verse-level MP3 files from the Quran.com CDN, concatenates them,
  /// and returns the path to the final MP3 file.
  ///
  /// [onProgress] is called with a value from 0.0 to 1.0 and a human-readable
  /// message.
  ///
  /// Throws [ArgumentError] if the verse range exceeds [maxVerses].
  /// Supports cancellation via [cancelToken].
  Future<String> _generateFromOnlineVerses({
    required AudioClipConfig config,
    required AudioClipProgressMessages progressMessages,
    void Function(double progress, String message)? onProgress,
    ShareCancelTokenBridge? cancelToken,
  }) async {
    if (config.verseCount > maxVerses) {
      throw ArgumentError('Verse range exceeds maximum of $maxVerses verses.');
    }

    final versePaths = <String>[];
    final totalVerses = config.verseCount;

    // Download verse files with bounded concurrency.
    final semaphore = _Semaphore(_maxConcurrency);
    final futures = <Future<String>>[];

    var completedCount = 0;
    for (var ayah = config.fromAyah; ayah <= config.toAyah; ayah++) {
      futures.add(
        semaphore.run(() async {
          if (cancelToken?.isCancelled == true) {
            throw DioException.requestCancelled(
              requestOptions: RequestOptions(),
              reason: 'User cancelled',
            );
          }

          final path = await _downloadVerseWithRetry(
            reciterFolder: config.reciterFolder,
            surahNumber: config.surahNumber,
            ayahNumber: ayah,
            cancelToken: cancelToken,
          );

          completedCount++;
          onProgress?.call(
            completedCount / totalVerses * _onlineDownloadProgressShare,
            progressMessages.downloadingVerse(completedCount, totalVerses),
          );

          return path;
        }),
      );
    }

    versePaths.addAll(await Future.wait(futures));

    onProgress?.call(
      _onlineAssemblyProgress,
      progressMessages.assemblingAudioClip,
    );

    // Concatenate MP3 files.
    final outputPath = await _concatenateFiles(
      versePaths: versePaths,
      config: config,
    );

    onProgress?.call(_completeProgress, progressMessages.done);

    // Evict old cache entries in the background.
    unawaited(_fileManager.evictVerseCacheIfNeeded());

    return outputPath;
  }

  /// Downloads a single verse audio file, using cache when available.
  Future<String> _downloadVerseWithRetry({
    required String reciterFolder,
    required int surahNumber,
    required int ayahNumber,
    ShareCancelTokenBridge? cancelToken,
  }) async {
    // Check cache first.
    final cached = await _fileManager.getCachedVersePath(
      reciterFolder: reciterFolder,
      surahNumber: surahNumber,
      ayahNumber: ayahNumber,
    );
    if (cached != null) return cached;

    final url = ReciterAudioCatalog.buildVerseAudioUrl(
      reciterFolder: reciterFolder,
      surahNumber: surahNumber,
      ayahNumber: ayahNumber,
    );

    for (var attempt = 1; attempt <= _maxRetries; attempt++) {
      try {
        final response = await _dio.get<List<int>>(
          url,
          options: Options(
            responseType: ResponseType.bytes,
            receiveTimeout: _downloadTimeout,
          ),
          cancelToken: cancelToken?.dioToken,
        );

        if (response.data == null || response.data!.isEmpty) {
          throw DioException(
            requestOptions: response.requestOptions,
            message: 'Empty response for verse $surahNumber:$ayahNumber',
          );
        }

        return _fileManager.cacheVerseFile(
          bytes: response.data!,
          reciterFolder: reciterFolder,
          surahNumber: surahNumber,
          ayahNumber: ayahNumber,
        );
      } on DioException catch (e) {
        if (e.type == DioExceptionType.cancel) rethrow;
        if (attempt == _maxRetries) rethrow;
        // Brief delay before retry.
        await Future<void>.delayed(Duration(milliseconds: 300 * attempt));
      }
    }

    // Unreachable, but required by the compiler.
    throw StateError('Download failed after $_maxRetries attempts.');
  }

  /// Concatenates MP3 files by appending raw bytes.
  ///
  /// For verse ranges > 10, runs in an isolate to avoid UI jank.
  Future<String> _concatenateFiles({
    required List<String> versePaths,
    required AudioClipConfig config,
  }) async {
    final shareDir = await _fileManager.getShareDirectory();
    final s = config.surahNumber.toString().padLeft(3, '0');
    final outputFileName =
        '${config.reciterFolder}_${s}_${config.fromAyah}-${config.toAyah}.mp3';
    final outputPath = p.join(shareDir.path, outputFileName);

    if (versePaths.length > 1) {
      try {
        await _concatenateWithFFmpeg(versePaths, outputPath, config);
      } catch (_) {
        await _concatenateRawBytes(versePaths, outputPath);
      }
    } else if (versePaths.isNotEmpty) {
      await File(versePaths.first).copy(outputPath);
    }

    return outputPath;
  }

  /// Concatenates MP3 files using FFmpeg's concat protocol.
  Future<void> _concatenateWithFFmpeg(
    List<String> inputPaths,
    String outputPath,
    AudioClipConfig config,
  ) async {
    // FFmpeg's concat protocol: "concat:file1|file2|file3"
    // Note: Paths with special characters might need escaping, but these are
    // internal temp paths which should be safe.
    final concatString = 'concat:${inputPaths.join('|')}';

    final s = config.surahNumber.toString().padLeft(3, '0');
    final title = 'Surah $s (${config.fromAyah}-${config.toAyah})';

    final result = await _runner.execute(
      '-i "$concatString" -acodec copy '
      '-metadata title="$title" '
      '-metadata artist="${config.reciterName}" '
      '-metadata album="Tilawa" '
      '-y "$outputPath"',
    );

    if (!result.isSuccess) {
      throw StateError(
        'FFmpeg concatenation failed. Logs: ${result.logs}',
      );
    }
  }

  Future<void> _concatenateRawBytes(
    List<String> inputPaths,
    String outputPath,
  ) async {
    final sink = File(outputPath).openWrite();
    try {
      for (final path in inputPaths) {
        await sink.addStream(File(path).openRead());
      }
    } finally {
      await sink.close();
    }
  }
}

/// Simple bounded concurrency semaphore.
class _Semaphore {
  _Semaphore(this._maxConcurrency);
  final int _maxConcurrency;
  int _running = 0;
  final _queue = <Completer<void>>[];

  Future<T> run<T>(Future<T> Function() task) async {
    if (_running >= _maxConcurrency) {
      final completer = Completer<void>();
      _queue.add(completer);
      await completer.future;
    }
    _running++;
    try {
      return await task();
    } finally {
      _running--;
      if (_queue.isNotEmpty) {
        _queue.removeAt(0).complete();
      }
    }
  }
}
