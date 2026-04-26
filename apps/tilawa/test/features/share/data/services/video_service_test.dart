import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/share/data/services/share_file_manager.dart';
import 'package:tilawa/features/share/data/services/video_service.dart';
import 'package:tilawa/features/share/domain/entities/share_progress_messages.dart';
import 'package:tilawa_core/errors/failures.dart';

void main() {
  late VideoService service;

  setUp(() {
    service = VideoService(ShareFileManager());
  });

  group('VideoService.generateVideo', () {
    test(
      'throws missingScreenshot when all screenshot paths are blank',
      () async {
        final progressEvents = <double>[];

        await expectLater(
          service.generateVideo(
            screenshotPaths: const ['', '   '],
            audioPath: 'audio.mp3',
            surahName: 'Al-Baqarah',
            reciterName: 'Al-Afasy',
            progressMessages: _messages,
            onProgress: (progress, _) => progressEvents.add(progress),
          ),
          throwsA(
            isA<VideoGenerationFailure>().having(
              (failure) => failure.reason,
              'reason',
              VideoGenerationFailureReason.missingScreenshot,
            ),
          ),
        );

        expect(progressEvents, isEmpty);
      },
    );

    test(
      'throws missingScreenshot when a raw capture file is missing',
      () async {
        final missingRawPath = '${Directory.systemTemp.path}/missing_reel.raw';
        final progressEvents = <double>[];

        await expectLater(
          service.generateVideo(
            screenshotPaths: [missingRawPath],
            audioPath: 'audio.mp3',
            surahName: 'Al-Baqarah',
            reciterName: 'Al-Afasy',
            progressMessages: _messages,
            onProgress: (progress, _) => progressEvents.add(progress),
          ),
          throwsA(
            isA<VideoGenerationFailure>().having(
              (failure) => failure.reason,
              'reason',
              VideoGenerationFailureReason.missingScreenshot,
            ),
          ),
        );

        expect(progressEvents, isEmpty);
      },
    );

    test(
      'throws invalidFrameFormat when raw capture size is not one frame',
      () async {
        final tempDir = await Directory.systemTemp.createTemp(
          'tilawa_video_service_test_',
        );
        addTearDown(() async {
          if (tempDir.existsSync()) {
            await tempDir.delete(recursive: true);
          }
        });

        final rawFile = File('${tempDir.path}/truncated.raw');
        await rawFile.writeAsBytes(<int>[0, 1, 2, 3], flush: true);
        final progressEvents = <double>[];

        await expectLater(
          service.generateVideo(
            screenshotPaths: [rawFile.path],
            audioPath: 'audio.mp3',
            surahName: 'Al-Baqarah',
            reciterName: 'Al-Afasy',
            progressMessages: _messages,
            onProgress: (progress, _) => progressEvents.add(progress),
          ),
          throwsA(
            isA<VideoGenerationFailure>().having(
              (failure) => failure.reason,
              'reason',
              VideoGenerationFailureReason.invalidFrameFormat,
            ),
          ),
        );

        expect(progressEvents, isEmpty);
      },
    );
  });
}

const _messages = VideoProgressMessages(
  preparingVideoEncoding: 'Preparing video encoding...',
  encodingVerticalVideo: 'Encoding vertical video...',
  videoGenerated: 'Video generated.',
  videoGenerationFailed: 'Video generation failed.',
  videoGenerationFailedInvalidFrame: 'Invalid frame.',
  videoGenerationFailedMissingScreenshot: 'Missing screenshot.',
  videoGenerationFailedInvalidOutput: 'Invalid output.',
);
