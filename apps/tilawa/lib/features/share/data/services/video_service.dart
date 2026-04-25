import 'dart:async';

import 'package:dio/dio.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_session.dart';
import 'package:ffmpeg_kit_flutter_new/ffprobe_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:injectable/injectable.dart';
import 'package:path/path.dart' as p;
import 'package:tilawa_core/logger.dart';

import '../../domain/entities/share_progress_messages.dart';
import '../../domain/entities/share_video_profile.dart';
import 'share_file_manager.dart';

@lazySingleton
class VideoService {
  VideoService(this._fileManager);

  final ShareFileManager _fileManager;
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
    CancelToken? cancelToken,
  }) async {
    logger.d(
      '[AppLaunch][VideoService.generateVideo]: Start in (${DateTime.now()})',
    );
    final List<String> effectiveScreenshotPaths = screenshotPaths
        .where((path) => path.trim().isNotEmpty)
        .toList();
    if (effectiveScreenshotPaths.isEmpty) {
      throw StateError('At least one video screenshot is required.');
    }

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
              effectiveScreenshotPaths.length;

    final String command = effectiveScreenshotPaths.length == 1
        ? _buildSingleImageCommand(
            screenshotPath: effectiveScreenshotPaths.single,
            audioPath: audioPath,
            surahName: surahName,
            reciterName: reciterName,
            outputPath: outputPath,
            audioDurationSeconds: effectiveDurationSeconds,
          )
        : _buildSlideshowCommand(
            screenshotPaths: effectiveScreenshotPaths,
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
    final FFmpegSession session = await _runWithProgress(
      command: command,
      audioDurationSeconds: effectiveDurationSeconds,
      onProgress: onProgress,
      progressMessages: progressMessages,
      cancelToken: cancelToken,
    );
    final returnCode = await session.getReturnCode();
    _videoLog(
      '[VIDEO_SVC] ffmpeg finished | returnCode=$returnCode | took=${DateTime.now().millisecondsSinceEpoch - tEncode}ms',
    );

    if (!ReturnCode.isSuccess(returnCode)) {
      if (ReturnCode.isCancel(returnCode)) {
        throw DioException.requestCancelled(
          requestOptions: RequestOptions(path: outputPath),
          reason: 'Video encoding was cancelled.',
        );
      }
      final logs = await session.getLogs();
      throw StateError(
        'FFmpeg video generation failed with return code $returnCode. Logs: ${logs.map((l) => l.getMessage()).join('\n')}',
      );
    }

    onProgress?.call(1.0, progressMessages.videoGenerated);
    return outputPath;
  }

  /// Runs the given FFmpeg command asynchronously so we can stream real
  /// progress via the statistics callback (stats.getTime() is wall-clock ms
  /// of encoded output), and wire cancellation through [cancelToken].
  Future<FFmpegSession> _runWithProgress({
    required String command,
    required double audioDurationSeconds,
    required VideoProgressMessages progressMessages,
    void Function(double progress, String message)? onProgress,
    CancelToken? cancelToken,
  }) async {
    final completer = Completer<FFmpegSession>();
    final double audioDurationMs = audioDurationSeconds * 1000.0;
    double lastReportedFraction = _encodingStartProgress;

    final FFmpegSession session = await FFmpegKit.executeAsync(
      command,
      (finishedSession) {
        if (!completer.isCompleted) completer.complete(finishedSession);
      },
      null,
      (stats) {
        if (audioDurationMs <= 0 || onProgress == null) return;
        final int timeMs = stats.getTime();
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
      cancelToken.whenCancel
          .then((_) {
            _videoLog(
              '[VIDEO_SVC] cancel requested — cancelling ffmpeg session.',
            );
            FFmpegKit.cancel(session.getSessionId());
          })
          .catchError((_) {});
    }

    return completer.future;
  }

  String _buildSingleImageCommand({
    required String screenshotPath,
    required String audioPath,
    required String surahName,
    required String reciterName,
    required String outputPath,
    required double audioDurationSeconds,
  }) {
    return [
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

  String _buildSlideshowCommand({
    required List<String> screenshotPaths,
    required String audioPath,
    required String surahName,
    required String reciterName,
    required String outputPath,
    required double audioDurationSeconds,
  }) {
    final List<double> slideDurations = _buildSlideDurations(
      slideCount: screenshotPaths.length,
      audioDurationSeconds: audioDurationSeconds,
    );
    final List<String> commandParts = <String>[];
    final List<String> filterParts = <String>[];
    final StringBuffer concatInputs = StringBuffer();

    for (int index = 0; index < screenshotPaths.length; index++) {
      commandParts.addAll(<String>[
        '-framerate',
        '$_stillImageInputFps',
        '-loop',
        '1',
        '-t',
        slideDurations[index].toStringAsFixed(3),
        '-i',
        '"${screenshotPaths[index]}"',
      ]);
      // Each slide is already at the target resolution thanks to the
      // offscreen capture pipeline, so we only normalise SAR and clamp the
      // internal frame rate. No scale/crop — that is the expensive step.
      filterParts.add('[$index:v]setsar=1,fps=$_stillImageInputFps[v$index]');
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

  List<double> _buildSlideDurations({
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
    try {
      final session = await FFprobeKit.getMediaInformation(audioPath);
      final String? durationText = session.getMediaInformation()?.getDuration();
      return durationText == null ? null : double.tryParse(durationText);
    } catch (_) {
      return null;
    }
  }
}

void _videoLog(String message) => logger.d(message);
