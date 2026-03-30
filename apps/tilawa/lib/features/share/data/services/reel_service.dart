import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/ffprobe_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:injectable/injectable.dart';
import 'package:path/path.dart' as p;

import '../../domain/entities/share_progress_messages.dart';
import 'share_file_manager.dart';

@lazySingleton
class ReelService {
  ReelService(this._fileManager);

  final ShareFileManager _fileManager;

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
    final double? audioDurationSeconds = await _probeAudioDurationInSeconds(
      audioPath,
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

    onProgress?.call(0.3, progressMessages.encodingVerticalVideo);

    final session = await FFmpegKit.execute(command);
    final returnCode = await session.getReturnCode();

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
      '-tune',
      'stillimage',
      '-c:a',
      'aac',
      '-b:a',
      '192k',
      '-pix_fmt',
      'yuv420p',
      '-r',
      '30',
      '-shortest',
      '-vf',
      '"scale=1080:1920:force_original_aspect_ratio=increase,crop=1080:1920"',
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
      filterParts.add(
        '[$index:v]scale=1080:1920:force_original_aspect_ratio=increase,crop=1080:1920,setsar=1,fps=30[v$index]',
      );
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
      '-tune',
      'stillimage',
      '-c:a',
      'aac',
      '-b:a',
      '192k',
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
