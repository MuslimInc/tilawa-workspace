import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:injectable/injectable.dart';
import 'package:path/path.dart' as p;
import 'share_file_manager.dart';

@lazySingleton
class ReelService {
  ReelService(this._fileManager);

  final ShareFileManager _fileManager;

  /// Combines a screenshot and an audio clip into a vertical MP4 video.
  ///
  /// [screenshotPath]: Path to the high-res 9:16 padded image.
  /// [audioPath]: Path to the generated/trimmed MP3 clip.
  Future<String> generateReel({
    required String screenshotPath,
    required String audioPath,
    required String surahName,
    required String reciterName,
    void Function(double progress, String message)? onProgress,
  }) async {
    onProgress?.call(0.1, 'Preparing video encoding...');

    final shareDir = await _fileManager.getShareDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final outputFileName = 'reel_$timestamp.mp4';
    final outputPath = p.join(shareDir.path, outputFileName);

    // FFmpeg command for basic static-image reel:
    // -loop 1: Loop the image
    // -i screenshot.png: Image input
    // -i audio.mp3: Audio input
    // -c:v libx264: H.264 video codec
    // -tune stillimage: Optimize for static image
    // -c:a aac: AAC audio codec
    // -pix_fmt yuv420p: Ensure compatibility with most players
    // -vf "scale=..." : Scales and crops into 9:16 (1080x1920)
    // -shortest: End video when the shortest input (audio) ends
    final command = [
      '-loop', '1',
      '-i', '"$screenshotPath"',
      '-i', '"$audioPath"',
      '-c:v', 'libx264',
      '-tune', 'stillimage',
      '-c:a', 'aac',
      '-b:a', '192k',
      '-pix_fmt', 'yuv420p',
      '-shortest',
      '-vf', '"scale=1080:1920:force_original_aspect_ratio=increase,crop=1080:1920"',
      '-metadata', 'title="$surahName Reel"',
      '-metadata', 'artist="$reciterName"',
      '-metadata', 'album="Tilawa"',
      '-y', '"$outputPath"',
    ].join(' ');

    onProgress?.call(0.3, 'Encoding vertical video (this may take a moment)...');

    final session = await FFmpegKit.execute(command);
    final returnCode = await session.getReturnCode();

    if (!ReturnCode.isSuccess(returnCode)) {
      final logs = await session.getLogs();
      throw StateError(
        'FFmpeg reel generation failed with return code $returnCode. Logs: ${logs.map((l) => l.getMessage()).join('\n')}',
      );
    }

    onProgress?.call(1.0, 'Reel generated!');
    return outputPath;
  }
}
