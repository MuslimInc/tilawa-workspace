import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:path/path.dart' as p;
import 'package:tilawa_core/errors/failures.dart';
import 'package:tilawa_core/logger.dart';

import '../../domain/entities/share_progress_messages.dart';
import '../../domain/entities/share_video_profile.dart';
import '../ffmpeg/ffmpeg_runner.dart';
import '../utils/share_cancel_token_bridge.dart';
import 'share_file_manager.dart';

@lazySingleton
class VideoService {
  VideoService(this._fileManager, this._runner);

  final ShareFileManager _fileManager;
  final FFmpegRunner _runner;
  // 720x1280 keeps the 9:16 aspect ratio social platforms expect while cutting
  // encoder pixel work by more than half versus 1080x1920 on mid-range phones.
  // Screenshots are already captured at this exact resolution (see
  // screenshot_service.dart + video_reel_composer_screen.dart), which removes
  // the need for FFmpeg scale/crop filters on the hot path.
  /// Target output width (px) for generated reels. Kept public so the capture
  /// and offscreen-render layers can pin the same dimensions end-to-end.
  static const int outputVideoWidth = ShareVideoProfile.outputWidthPx;

  /// Target output height (px) for generated reels.
  static const int outputVideoHeight = ShareVideoProfile.outputHeightPx;
  static const int _outputFps = ShareVideoProfile.outputFps;
  static const int _stillImageInputFps = ShareVideoProfile.stillImageInputFps;
  // Keyframe cadence of 2 seconds keeps Reels/TikTok/Shorts happy without
  // paying real encoder cost on a still-image stream.
  static const int _keyframeIntervalFrames =
      ShareVideoProfile.keyframeIntervalFrames;
  static const String _audioBitrate = ShareVideoProfile.audioBitrate;
  static const double _preparingEncodingProgress = 0.1;
  static const double _encodingStartProgress = 0.3;
  static const double _encodingEndProgress = 0.9;
  static const double _minProgressDelta = 0.005;

  /// Combines a screenshot and an audio clip into a vertical MP4 video.
  ///
  /// [screenshotPaths]: Paths to the captured 9:16 page images.
  /// [audioPath]: Path to the generated/trimmed MP3 clip.
  Future<String> generateVideo({
    required List<String> screenshotPaths,
    required String audioPath,
    required String surahName,
    required String reciterName,
    required VideoProgressMessages progressMessages,
    void Function(double progress, String message)? onProgress,
    ShareCancelTokenBridge? cancelToken,
  }) async {
    logger.d(
      '[AppLaunch] source=VideoService.generateVideo: Start in (${DateTime.now()})',
    );
    final List<String> effectiveScreenshotPaths = screenshotPaths
        .where((path) => path.trim().isNotEmpty)
        .toList();
    if (effectiveScreenshotPaths.isEmpty) {
      throw const VideoGenerationFailure(
        'At least one screenshot is required to generate a reel.',
        VideoGenerationFailureReason.missingScreenshot,
      );
    }

    final _PreparedScreenshots preparedScreenshots =
        await _materializeScreenshotsForEncoding(effectiveScreenshotPaths);
    final List<String> encodeScreenshotPaths = preparedScreenshots.paths;

    try {
      onProgress?.call(
        _preparingEncodingProgress,
        progressMessages.preparingVideoEncoding,
      );

      final shareDir = await _fileManager.getShareDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final outputFileName = 'video_$timestamp.mp4';
      final outputPath = p.join(shareDir.path, outputFileName);

      final int tProbe = DateTime.now().millisecondsSinceEpoch;
      final double audioDurationSeconds =
          (await _probeAudioDurationInSeconds(audioPath)) ?? 0.0;
      _videoLog(
        '[VIDEO_SVC] ffprobe done | duration=${audioDurationSeconds}s | took=${DateTime.now().millisecondsSinceEpoch - tProbe}ms',
      );

      final bool hasUsableAudioDuration = audioDurationSeconds > 0;
      final double effectiveDurationSeconds = hasUsableAudioDuration
          ? audioDurationSeconds
          // Conservative fallback when ffprobe is unavailable; -shortest will
          // still clamp to audio at mux time, so this only bounds the image loop.
          : ShareVideoProfile.fallbackSecondsPerSlide *
                encodeScreenshotPaths.length;

      final String command = encodeScreenshotPaths.length == 1
          ? buildSingleImageCommand(
              screenshotPath: encodeScreenshotPaths.single,
              audioPath: audioPath,
              surahName: surahName,
              reciterName: reciterName,
              outputPath: outputPath,
              audioDurationSeconds: effectiveDurationSeconds,
            )
          : buildSlideshowCommand(
              screenshotPaths: encodeScreenshotPaths,
              audioPath: audioPath,
              surahName: surahName,
              reciterName: reciterName,
              outputPath: outputPath,
              audioDurationSeconds: effectiveDurationSeconds,
            );

      _videoLog('[VIDEO_SVC] ffmpeg command: $command');
      onProgress?.call(
        _encodingStartProgress,
        progressMessages.encodingVerticalVideo,
      );

      final int tEncode = DateTime.now().millisecondsSinceEpoch;
      final FFmpegRunResult result = await _runWithProgress(
        command: command,
        audioDurationSeconds: effectiveDurationSeconds,
        onProgress: onProgress,
        progressMessages: progressMessages,
        cancelToken: cancelToken,
      );
      _videoLog(
        '[VIDEO_SVC] ffmpeg finished | status=${result.status} | took=${DateTime.now().millisecondsSinceEpoch - tEncode}ms',
      );

      if (!result.isSuccess) {
        if (result.isCancelled) {
          throw DioException.requestCancelled(
            requestOptions: RequestOptions(path: outputPath),
            reason: 'Video encoding was cancelled.',
          );
        }
        final ffmpegLogs = result.logs;
        final bool hasFrameFormatIssue =
            ffmpegLogs.contains('Invalid pixel format') ||
            ffmpegLogs.contains('rawvideo') ||
            ffmpegLogs.contains('Could not find codec parameters for stream 0');

        throw VideoGenerationFailure(
          hasFrameFormatIssue
              ? 'Captured frame format is not supported for video encoding.'
              : 'Failed to encode reel video.',
          hasFrameFormatIssue
              ? VideoGenerationFailureReason.invalidFrameFormat
              : VideoGenerationFailureReason.encodingFailed,
        );
      }

      final bool outputIsValid = await _isGeneratedVideoOutputValid(outputPath);

      if (!outputIsValid) {
        throw const VideoGenerationFailure(
          'Encoded reel output is invalid and cannot be previewed.',
          VideoGenerationFailureReason.invalidOutput,
        );
      }

      onProgress?.call(1.0, progressMessages.videoGenerated);
      return outputPath;
    } finally {
      await preparedScreenshots.cleanup();
    }
  }

  /// Runs the given FFmpeg command asynchronously so we can stream real
  /// progress via the statistics callback (timeMs is wall-clock ms of encoded
  /// output), and wire cancellation through [cancelToken].
  Future<FFmpegRunResult> _runWithProgress({
    required String command,
    required double audioDurationSeconds,
    required VideoProgressMessages progressMessages,
    void Function(double progress, String message)? onProgress,
    ShareCancelTokenBridge? cancelToken,
  }) async {
    final double audioDurationMs = audioDurationSeconds * 1000.0;
    double lastReportedFraction = _encodingStartProgress;

    final FFmpegRunHandle handle = await _runner.executeAsync(
      command,
      onStats: (stats) {
        if (audioDurationMs <= 0 || onProgress == null) return;
        final int timeMs = stats.timeMs;
        if (timeMs <= 0) return;
        // Local encode progress is remapped by the repository to the global
        // share progress bar. Keep the top range for muxing/finalization.
        final double fraction =
            _encodingStartProgress +
            (timeMs / audioDurationMs) *
                (_encodingEndProgress - _encodingStartProgress);
        final double clamped = fraction.clamp(
          _encodingStartProgress,
          _encodingEndProgress,
        );
        if (clamped - lastReportedFraction < _minProgressDelta) return;
        lastReportedFraction = clamped;
        onProgress(clamped, progressMessages.encodingVerticalVideo);
      },
    );

    if (cancelToken != null) {
      cancelToken.dioToken.whenCancel
          .then((_) {
            _videoLog(
              '[VIDEO_SVC] cancel requested — cancelling ffmpeg session.',
            );
            handle.cancel();
          })
          .catchError((_) {});
    }

    return handle.done;
  }

  /// Builds the single-image FFmpeg command. Visible for testing so the
  /// command shape can be locked down without spinning up a real encoder.
  @visibleForTesting
  String buildSingleImageCommand({
    required String screenshotPath,
    required String audioPath,
    required String surahName,
    required String reciterName,
    required String outputPath,
    required double audioDurationSeconds,
  }) {
    final bool isRawFile = screenshotPath.endsWith('.raw');
    if (isRawFile) {
      final String duration = audioDurationSeconds.toStringAsFixed(3);
      return <String>[
        '-f',
        'rawvideo',
        '-pixel_format',
        'rgba',
        '-video_size',
        '${outputVideoWidth}x$outputVideoHeight',
        '-framerate',
        '$_stillImageInputFps',
        '-i',
        '"$screenshotPath"',
        '-i',
        '"$audioPath"',
        '-filter_complex',
        '"[0:v]loop=loop=-1:size=1:start=0,fps=$_stillImageInputFps,trim=duration=$duration,setsar=1[v]"',
        '-map',
        '"[v]"',
        '-map',
        '1:a',
        '-c:v',
        'libx264',
        '-preset',
        'ultrafast',
        '-crf',
        '28',
        '-tune',
        'stillimage',
        '-c:a',
        'aac',
        '-b:a',
        _audioBitrate,
        '-pix_fmt',
        'yuv420p',
        '-r',
        '$_outputFps',
        '-g',
        '$_keyframeIntervalFrames',
        '-keyint_min',
        '$_keyframeIntervalFrames',
        '-sc_threshold',
        '0',
        '-shortest',
        '-movflags',
        '+faststart',
        '-metadata',
        'title="$surahName Video"',
        '-metadata',
        'artist="$reciterName"',
        '-metadata',
        'album="Tilawa"',
        '-y',
        '"$outputPath"',
      ].join(' ');
    }

    return <String>[
      // -framerate BEFORE -i on a looped image forces a 1fps input stream,
      // preventing the default 25fps internal expansion. That single flag is
      // the primary fix — without it, FFmpeg decodes ~audioDuration*25 frames
      // and feeds every one of them through scale/crop before the output -r
      // drops them, which is the entire encode-time bottleneck.
      '-framerate',
      '$_stillImageInputFps',
      '-loop',
      '1',
      // Hard-cap the image loop to the audio duration so the looped input
      // can never outlast the audio. Belt-and-braces on top of -shortest.
      '-t',
      audioDurationSeconds.toStringAsFixed(3),
      '-i',
      '"$screenshotPath"',
      '-i',
      '"$audioPath"',
      '-c:v',
      'libx264',
      // ultrafast preset cuts encode time by ~60% vs default (medium) on
      // mobile CPUs with no perceptible quality difference for a social video.
      '-preset',
      'ultrafast',
      '-crf',
      '28',
      // still-image tuning tells x264 to favour tiny duplicate P-frames,
      // so 30 fps output costs almost nothing vs a 1 fps output but plays
      // correctly on Reels/TikTok/Shorts (which reject <24fps on many edges).
      '-tune',
      'stillimage',
      '-c:a',
      'aac',
      '-b:a',
      _audioBitrate,
      '-pix_fmt',
      'yuv420p',
      '-r',
      '$_outputFps',
      // Deterministic keyframes for smooth social-platform scrubbing.
      '-g',
      '$_keyframeIntervalFrames',
      '-keyint_min',
      '$_keyframeIntervalFrames',
      '-sc_threshold',
      '0',
      '-shortest',
      // No -vf: screenshots are already captured at _outputVideoWidth ×
      // _outputVideoHeight, so we avoid the per-frame scale/crop pass.
      '-movflags',
      '+faststart',
      '-metadata',
      'title="$surahName Video"',
      '-metadata',
      'artist="$reciterName"',
      '-metadata',
      'album="Tilawa"',
      '-y',
      '"$outputPath"',
    ].join(' ');
  }

  /// Builds the multi-image slideshow FFmpeg command. Linear in slide count
  /// (each slide must appear in the filter graph exactly once); no hidden
  /// quadratic from string concat — we accumulate via `StringBuffer`/`join`.
  @visibleForTesting
  String buildSlideshowCommand({
    required List<String> screenshotPaths,
    required String audioPath,
    required String surahName,
    required String reciterName,
    required String outputPath,
    required double audioDurationSeconds,
  }) {
    final List<double> slideDurations = buildSlideDurations(
      slideCount: screenshotPaths.length,
      audioDurationSeconds: audioDurationSeconds,
    );
    final List<String> commandParts = <String>[];
    final List<String> filterParts = <String>[];
    final StringBuffer concatInputs = StringBuffer();

    for (int index = 0; index < screenshotPaths.length; index++) {
      final String screenshotPath = screenshotPaths[index];
      final bool isRawFile = screenshotPath.endsWith('.raw');

      // For raw RGBA files, add explicit format parameters so FFmpeg knows how to read them
      if (isRawFile) {
        commandParts.addAll(<String>[
          '-f',
          'rawvideo',
          '-pixel_format',
          'rgba',
          '-video_size',
          '${outputVideoWidth}x$outputVideoHeight',
          '-framerate',
          '$_stillImageInputFps',
          '-i',
          '"$screenshotPath"',
        ]);
        final String slideDuration = slideDurations[index].toStringAsFixed(3);
        // Raw input is a single frame; loop that frame to fill slide duration.
        filterParts.add(
          '[$index:v]loop=loop=-1:size=1:start=0,fps=$_stillImageInputFps,trim=duration=$slideDuration,setsar=1[v$index]',
        );
      } else {
        commandParts.addAll(<String>[
          '-framerate',
          '$_stillImageInputFps',
          '-loop',
          '1',
          '-t',
          slideDurations[index].toStringAsFixed(3),
          '-i',
          '"$screenshotPath"',
        ]);
        // Each slide is already at the target resolution thanks to the
        // offscreen capture pipeline, so we only normalise SAR and clamp the
        // internal frame rate. No scale/crop — that is the expensive step.
        filterParts.add('[$index:v]setsar=1,fps=$_stillImageInputFps[v$index]');
      }
      concatInputs.write('[v$index]');
    }

    final int audioInputIndex = screenshotPaths.length;
    final String filterComplex =
        '${filterParts.join(';')};${concatInputs}concat=n=${screenshotPaths.length}:v=1:a=0[v]';

    commandParts.addAll(<String>[
      '-i',
      '"$audioPath"',
      '-filter_complex',
      '"$filterComplex"',
      '-map',
      '"[v]"',
      '-map',
      '$audioInputIndex:a',
      '-c:v',
      'libx264',
      '-preset',
      'ultrafast',
      '-crf',
      '28',
      '-tune',
      'stillimage',
      '-c:a',
      'aac',
      '-b:a',
      _audioBitrate,
      '-pix_fmt',
      'yuv420p',
      '-r',
      '$_outputFps',
      '-g',
      '$_keyframeIntervalFrames',
      '-keyint_min',
      '$_keyframeIntervalFrames',
      '-sc_threshold',
      '0',
      '-shortest',
      '-movflags',
      '+faststart',
      '-metadata',
      'title="$surahName Video"',
      '-metadata',
      'artist="$reciterName"',
      '-metadata',
      'album="Tilawa"',
      '-y',
      '"$outputPath"',
    ]);

    return commandParts.join(' ');
  }

  /// Distributes [audioDurationSeconds] across [slideCount] slides. The last
  /// slide absorbs any rounding remainder so the sum is exact.
  @visibleForTesting
  List<double> buildSlideDurations({
    required int slideCount,
    required double? audioDurationSeconds,
  }) {
    final double totalDurationSeconds =
        audioDurationSeconds != null && audioDurationSeconds > 0
        ? audioDurationSeconds
        : ShareVideoProfile.fallbackSecondsPerSlide * slideCount;
    final double baseDurationSeconds = totalDurationSeconds / slideCount;

    return List<double>.generate(slideCount, (index) {
      if (index == slideCount - 1) {
        final double consumed = baseDurationSeconds * (slideCount - 1);
        return (totalDurationSeconds - consumed).clamp(0.001, double.infinity);
      }
      return baseDurationSeconds;
    });
  }

  Future<double?> _probeAudioDurationInSeconds(String audioPath) async {
    final info = await _runner.getMediaInformation(audioPath);
    return info?.durationSeconds;
  }

  Future<_PreparedScreenshots> _materializeScreenshotsForEncoding(
    List<String> screenshotPaths,
  ) async {
    final List<String> resolvedPaths = <String>[];
    final List<String> tempPngPaths = <String>[];

    for (int i = 0; i < screenshotPaths.length; i++) {
      final String screenshotPath = screenshotPaths[i];
      if (!screenshotPath.endsWith('.raw')) {
        resolvedPaths.add(screenshotPath);
        continue;
      }

      final String pngPath = await _extractRawFrameToPng(
        rawPath: screenshotPath,
        index: i,
      );
      resolvedPaths.add(pngPath);
      tempPngPaths.add(pngPath);
    }

    return _PreparedScreenshots(
      paths: resolvedPaths,
      tempPngPaths: tempPngPaths,
    );
  }

  Future<String> _extractRawFrameToPng({
    required String rawPath,
    required int index,
  }) async {
    const int expectedRawBytes = outputVideoWidth * outputVideoHeight * 4;
    final rawFile = File(rawPath);
    if (!rawFile.existsSync()) {
      _videoLog('[VIDEO_SVC] raw frame validation failed: missing $rawPath');
      throw const VideoGenerationFailure(
        'Captured frame is missing and cannot be encoded.',
        VideoGenerationFailureReason.missingScreenshot,
      );
    }

    final int actualRawBytes = await rawFile.length();
    if (actualRawBytes != expectedRawBytes) {
      _videoLog(
        '[VIDEO_SVC] raw frame validation failed: expected=${expectedRawBytes}B actual=${actualRawBytes}B path=$rawPath',
      );
      throw const VideoGenerationFailure(
        'Captured frame size does not match the video encoder profile.',
        VideoGenerationFailureReason.invalidFrameFormat,
      );
    }

    final shareDir = await _fileManager.getShareDirectory();
    final String pngPath = p.join(
      shareDir.path,
      'raw_frame_${DateTime.now().millisecondsSinceEpoch}_$index.png',
    );

    final extractCommand = <String>[
      '-f',
      'rawvideo',
      '-pixel_format',
      'rgba',
      '-video_size',
      '${outputVideoWidth}x$outputVideoHeight',
      '-framerate',
      '1',
      '-i',
      '"$rawPath"',
      '-frames:v',
      '1',
      '-y',
      '"$pngPath"',
    ].join(' ');

    _videoLog('[VIDEO_SVC] raw->png command: $extractCommand');
    final result = await _runner.execute(extractCommand);
    _videoLog('[VIDEO_SVC] raw->png finished | status=${result.status}');

    if (!result.isSuccess) {
      _videoLog('[VIDEO_SVC] raw->png failed logs:\n${result.logs}');
      throw const VideoGenerationFailure(
        'Captured frame format is not supported for video encoding.',
        VideoGenerationFailureReason.invalidFrameFormat,
      );
    }

    return pngPath;
  }

  Future<bool> _isGeneratedVideoOutputValid(String outputPath) async {
    final file = File(outputPath);
    if (!file.existsSync()) {
      _videoLog(
        '[VIDEO_SVC] output validation failed: missing file $outputPath',
      );
      return false;
    }

    final int sizeBytes = file.lengthSync();
    // Guardrail: tiny MP4s (e.g. a few hundred bytes) are metadata-only and
    // will hang/never initialize in the video preview.
    if (sizeBytes < 8 * 1024) {
      _videoLog(
        '[VIDEO_SVC] output validation failed: file too small (${sizeBytes}B) path=$outputPath',
      );
      return false;
    }

    final info = await _runner.getMediaInformation(outputPath);
    final double durationSeconds = info?.durationSeconds ?? 0;
    if (durationSeconds <= 0) {
      _videoLog(
        '[VIDEO_SVC] output validation failed: invalid duration=$durationSeconds path=$outputPath',
      );
      return false;
    }
    return true;
  }
}

class _PreparedScreenshots {
  _PreparedScreenshots({required this.paths, required this.tempPngPaths});

  final List<String> paths;
  final List<String> tempPngPaths;

  Future<void> cleanup() async {
    for (final path in tempPngPaths) {
      try {
        final file = File(path);
        if (file.existsSync()) {
          file.deleteSync();
        }
      } catch (_) {
        // Best effort cleanup only.
      }
    }
  }
}

void _videoLog(String message) => logger.d(message);
