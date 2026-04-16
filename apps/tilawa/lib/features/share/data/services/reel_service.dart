import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/ffprobe_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:injectable/injectable.dart';
import 'package:path/path.dart' as p;
import 'package:tilawa_core/logger.dart';

import '../../domain/entities/share_progress_messages.dart';
import 'share_file_manager.dart';

@lazySingleton
class ReelService {
  ReelService(this._fileManager);

  final ShareFileManager _fileManager;
  // 720x1280 keeps the 9:16 aspect ratio social platforms expect while cutting
  // encoder pixel work by more than half versus 1080x1920 on mid-range phones.
  static const int _outputVideoWidth = 720;
  static const int _outputVideoHeight = 1280;
  static const String _audioBitrate = '128k';

  String get _scaleAndCropFilter =>
      'scale=$_outputVideoWidth:$_outputVideoHeight:force_original_aspect_ratio=increase,crop=$_outputVideoWidth:$_outputVideoHeight';

  /// Combines a screenshot and an audio clip into a vertical MP4 video.
  ///
  /// [screenshotPaths]: Paths to the captured 9:16 page images.
  /// [audioPath]: Path to the generated/trimmed MP3 clip.
  Future<String> generateReel({
    required List<String> screenshotPaths,
    required String audioPath,
    required String surahName,
    required String reciterName,
    required ReelProgressMessages progressMessages,
    void Function(double progress, String message)? onProgress,
  }) async {
    final List<String> effectiveScreenshotPaths = screenshotPaths
        .where((path) => path.trim().isNotEmpty)
        .toList();
    if (effectiveScreenshotPaths.isEmpty) {
      throw StateError('At least one reel screenshot is required.');
    }

    onProgress?.call(0.1, progressMessages.preparingVideoEncoding);

    final shareDir = await _fileManager.getShareDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final outputFileName = 'reel_$timestamp.mp4';
    final outputPath = p.join(shareDir.path, outputFileName);

    final int tProbe = DateTime.now().millisecondsSinceEpoch;
    final double? audioDurationSeconds = await _probeAudioDurationInSeconds(
      audioPath,
    );
    _reelLog(
      '[REEL_SVC] ffprobe done | duration=${audioDurationSeconds}s | took=${DateTime.now().millisecondsSinceEpoch - tProbe}ms',
    );

    final String command = effectiveScreenshotPaths.length == 1
        ? _buildSingleImageCommand(
            screenshotPath: effectiveScreenshotPaths.single,
            audioPath: audioPath,
            surahName: surahName,
            reciterName: reciterName,
            outputPath: outputPath,
          )
        : _buildSlideshowCommand(
            screenshotPaths: effectiveScreenshotPaths,
            audioPath: audioPath,
            surahName: surahName,
            reciterName: reciterName,
            outputPath: outputPath,
            audioDurationSeconds: audioDurationSeconds,
          );

    _reelLog('[REEL_SVC] ffmpeg command: $command');
    onProgress?.call(0.3, progressMessages.encodingVerticalVideo);

    final int tEncode = DateTime.now().millisecondsSinceEpoch;
    final session = await FFmpegKit.execute(command);
    final returnCode = await session.getReturnCode();
    _reelLog(
      '[REEL_SVC] ffmpeg finished | returnCode=$returnCode | took=${DateTime.now().millisecondsSinceEpoch - tEncode}ms',
    );

    if (!ReturnCode.isSuccess(returnCode)) {
      final logs = await session.getLogs();
      throw StateError(
        'FFmpeg reel generation failed with return code $returnCode. Logs: ${logs.map((l) => l.getMessage()).join('\n')}',
      );
    }

    onProgress?.call(1.0, progressMessages.reelGenerated);
    return outputPath;
  }

  String _buildSingleImageCommand({
    required String screenshotPath,
    required String audioPath,
    required String surahName,
    required String reciterName,
    required String outputPath,
  }) {
    return [
      '-loop',
      '1',
      '-i',
      '"$screenshotPath"',
      '-i',
      '"$audioPath"',
      '-c:v',
      'libx264',
      // ultrafast preset cuts encode time by ~60% vs default (medium) on
      // mobile CPUs with no perceptible quality difference for a social reel.
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
      // 1 fps is sufficient for a still-image reel; avoids encoding hundreds
      // of identical frames at 30 fps, which is the main encode time driver.
      '-r',
      '1',
      '-shortest',
      '-vf',
      // `-r 1` on the output alone does not stop FFmpeg from generating the
      // default 25 fps looped-image stream internally. Clamp frames in the
      // filter graph so single-page reels do not encode hundreds of duplicate
      // frames across the full audio duration.
      '"$_scaleAndCropFilter,setsar=1,fps=1"',
      '-movflags',
      '+faststart',
      '-metadata',
      'title="$surahName Reel"',
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
    required double? audioDurationSeconds,
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
        '-loop',
        '1',
        '-t',
        slideDurations[index].toStringAsFixed(3),
        '-i',
        '"${screenshotPaths[index]}"',
      ]);
      // 1 fps per slide — sufficient for still-image slides on social platforms
      // and avoids encoding hundreds of duplicate frames per slide.
      filterParts.add('[$index:v]$_scaleAndCropFilter,setsar=1,fps=1[v$index]');
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
      '-shortest',
      '-movflags',
      '+faststart',
      '-metadata',
      'title="$surahName Reel"',
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
        : 90.0 * slideCount;
    final double baseDurationSeconds = totalDurationSeconds / slideCount;

    return List<double>.generate(slideCount, (index) {
      if (index == slideCount - 1) {
        final double consumedDuration = baseDurationSeconds * (slideCount - 1);
        return ((totalDurationSeconds - consumedDuration).clamp(
                  0.001,
                  double.infinity,
                )
                as num)
            .toDouble();
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

void _reelLog(String message) {
  assert(() {
    // ignore: avoid_print
    logger.d(message);
    return true;
  }());
}
