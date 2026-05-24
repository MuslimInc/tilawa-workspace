import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:tilawa/features/share/data/ffmpeg/ffmpeg_runner.dart';
import 'package:tilawa/features/share/data/services/share_file_manager.dart';
import 'package:tilawa/features/share/data/services/video_service.dart';
import 'package:tilawa/features/share/domain/entities/share_progress_messages.dart';
import 'package:tilawa/features/share/domain/entities/share_video_profile.dart';
import 'package:tilawa_core/errors/failures.dart';

import 'fakes/fake_ffmpeg_runner.dart';

/// Bytes per raw RGBA frame at the encoder's pinned resolution. Used to write
/// fixture `.raw` files that pass the size guard inside `_extractRawFrameToPng`.
const int _expectedRawBytes =
    ShareVideoProfile.outputWidthPx * ShareVideoProfile.outputHeightPx * 4;

/// Path the mocked `path_provider` channel returns for both temp and app
/// support dirs. Set in [setUp] to a real, fresh temp directory per test.
late Directory _platformTempDir;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // path_provider routes every method through this channel. Returning a real
  // directory off `Directory.systemTemp.createTemp(...)` lets `ShareFileManager`
  // create files for real, which the encode + cleanup paths depend on.
  const channel = MethodChannel('plugins.flutter.io/path_provider');
  setUp(() async {
    _platformTempDir = await Directory.systemTemp.createTemp(
      'tilawa_video_service_test_',
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          switch (call.method) {
            case 'getTemporaryDirectory':
            case 'getApplicationSupportDirectory':
              return _platformTempDir.path;
          }
          return null;
        });
  });

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    if (_platformTempDir.existsSync()) {
      await _platformTempDir.delete(recursive: true);
    }
  });

  group('generateVideo — input validation (FFmpeg never invoked)', () {
    test('rejects an empty path list with missingScreenshot', () async {
      final runner = FakeFFmpegRunner();
      final service = VideoService(ShareFileManager(), runner);

      await expectLater(
        service.generateVideo(
          screenshotPaths: const <String>[],
          audioPath: 'audio.mp3',
          surahName: 'Al-Baqarah',
          reciterName: 'Al-Afasy',
          progressMessages: _messages,
        ),
        throwsA(
          _failureWithReason(VideoGenerationFailureReason.missingScreenshot),
        ),
      );

      expect(runner.executeCommands, isEmpty);
      expect(runner.asyncCommands, isEmpty);
      expect(runner.mediaInfoPaths, isEmpty);
    });

    test('rejects all-blank paths with missingScreenshot', () async {
      final runner = FakeFFmpegRunner();
      final service = VideoService(ShareFileManager(), runner);
      final progress = <double>[];

      await expectLater(
        service.generateVideo(
          screenshotPaths: const ['', '   ', '\t'],
          audioPath: 'audio.mp3',
          surahName: 'Al-Baqarah',
          reciterName: 'Al-Afasy',
          progressMessages: _messages,
          onProgress: (p, _) => progress.add(p),
        ),
        throwsA(
          _failureWithReason(VideoGenerationFailureReason.missingScreenshot),
        ),
      );
      expect(progress, isEmpty);
    });

    test('rejects a missing .raw file with missingScreenshot', () async {
      final runner = FakeFFmpegRunner();
      final service = VideoService(ShareFileManager(), runner);

      await expectLater(
        service.generateVideo(
          screenshotPaths: ['${_platformTempDir.path}/nope.raw'],
          audioPath: 'audio.mp3',
          surahName: 'Al-Baqarah',
          reciterName: 'Al-Afasy',
          progressMessages: _messages,
        ),
        throwsA(
          _failureWithReason(VideoGenerationFailureReason.missingScreenshot),
        ),
      );
    });

    test('rejects a wrong-size .raw file with invalidFrameFormat', () async {
      final runner = FakeFFmpegRunner();
      final service = VideoService(ShareFileManager(), runner);
      final raw = await _writeFile(_platformTempDir, 'truncated.raw', size: 16);

      await expectLater(
        service.generateVideo(
          screenshotPaths: [raw.path],
          audioPath: 'audio.mp3',
          surahName: 'Al-Baqarah',
          reciterName: 'Al-Afasy',
          progressMessages: _messages,
        ),
        throwsA(
          _failureWithReason(VideoGenerationFailureReason.invalidFrameFormat),
        ),
      );
    });
  });

  group('generateVideo — raw->png materialization', () {
    test(
      'extracts each .raw to a PNG via runner.execute and feeds PNG paths to the encoder',
      () async {
        final runner = FakeFFmpegRunner()
          ..onAsyncCommand = _seedOutputFromCommand;
        runner.executeResults.addAll([
          const FFmpegRunResult(status: FFmpegRunStatus.success),
          const FFmpegRunResult(status: FFmpegRunStatus.success),
        ]);
        runner.asyncPlans.add(FakeAsyncPlan.success());
        runner.mediaInfoResults.addAll([
          const FFmpegMediaInfo(durationSeconds: 12.0), // probe
          const FFmpegMediaInfo(durationSeconds: 12.0), // output validate
        ]);

        final service = VideoService(ShareFileManager(), runner);
        final raw1 = await _writeFile(
          _platformTempDir,
          'frame1.raw',
          size: _expectedRawBytes,
        );
        final raw2 = await _writeFile(
          _platformTempDir,
          'frame2.raw',
          size: _expectedRawBytes,
        );

        await service.generateVideo(
          screenshotPaths: [raw1.path, raw2.path],
          audioPath: 'audio.mp3',
          surahName: 'Al-Baqarah',
          reciterName: 'Al-Afasy',
          progressMessages: _messages,
        );

        expect(runner.executeCommands.length, 2);
        for (final cmd in runner.executeCommands) {
          expect(cmd, contains('-f rawvideo'));
          expect(cmd, contains('-pixel_format rgba'));
          expect(
            cmd,
            contains(
              '-video_size '
              '${ShareVideoProfile.outputWidthPx}x${ShareVideoProfile.outputHeightPx}',
            ),
          );
          expect(cmd, contains('-frames:v 1'));
        }

        expect(runner.asyncCommands, hasLength(1));
        final encodeCmd = runner.asyncCommands.single;
        expect(encodeCmd, isNot(contains('.raw')));
        expect(encodeCmd, contains('raw_frame_'));
      },
    );

    test(
      'cleans up extracted PNG temp files even when the encode succeeds',
      () async {
        final runner = FakeFFmpegRunner()
          ..onAsyncCommand = _seedOutputFromCommand;
        runner.executeResults.add(
          const FFmpegRunResult(status: FFmpegRunStatus.success),
        );
        runner.asyncPlans.add(FakeAsyncPlan.success());
        runner.mediaInfoResults.addAll([
          const FFmpegMediaInfo(durationSeconds: 8.0),
          const FFmpegMediaInfo(durationSeconds: 8.0),
        ]);
        final service = VideoService(ShareFileManager(), runner);
        final raw = await _writeFile(
          _platformTempDir,
          'one.raw',
          size: _expectedRawBytes,
        );

        await service.generateVideo(
          screenshotPaths: [raw.path],
          audioPath: 'audio.mp3',
          surahName: 'X',
          reciterName: 'Y',
          progressMessages: _messages,
        );

        final remaining = _shareDir()
            .listSync()
            .where((e) => p.basename(e.path).startsWith('raw_frame_'))
            .toList();
        expect(remaining, isEmpty, reason: 'temp PNGs leaked');
      },
    );

    test(
      'fails with invalidFrameFormat when raw->png extraction fails',
      () async {
        final runner = FakeFFmpegRunner();
        runner.executeResults.add(
          const FFmpegRunResult(
            status: FFmpegRunStatus.failure,
            logs: 'rawvideo decode error',
          ),
        );
        final service = VideoService(ShareFileManager(), runner);
        final raw = await _writeFile(
          _platformTempDir,
          'bad.raw',
          size: _expectedRawBytes,
        );

        await expectLater(
          service.generateVideo(
            screenshotPaths: [raw.path],
            audioPath: 'audio.mp3',
            surahName: 'X',
            reciterName: 'Y',
            progressMessages: _messages,
          ),
          throwsA(
            _failureWithReason(VideoGenerationFailureReason.invalidFrameFormat),
          ),
        );

        // Encoder was never reached.
        expect(runner.asyncCommands, isEmpty);
      },
    );
  });

  group('generateVideo — encode happy path & progress', () {
    test('returns the output path and emits the full progress arc', () async {
      final runner = FakeFFmpegRunner()
        ..onAsyncCommand = _seedOutputFromCommand;
      runner.asyncPlans.add(
        FakeAsyncPlan.success(
          stats: const [
            FFmpegStatsSnapshot(timeMs: 0), // ignored: timeMs <= 0
            FFmpegStatsSnapshot(timeMs: 1000), // ~3.3% of 30s → ~0.32 fraction
            FFmpegStatsSnapshot(timeMs: 1001), // throttled (< 0.005 delta)
            FFmpegStatsSnapshot(timeMs: 15000), // 50% of 30s → ~0.6 fraction
            FFmpegStatsSnapshot(timeMs: 100000), // > duration → clamped to 0.9
          ],
        ),
      );
      runner.mediaInfoResults.addAll([
        const FFmpegMediaInfo(durationSeconds: 30.0), // probe
        const FFmpegMediaInfo(durationSeconds: 30.0), // output validate
      ]);
      final service = VideoService(ShareFileManager(), runner);
      final png = await _writeFile(_platformTempDir, 'slide.png', size: 32);

      final progress = <double>[];
      final messages = <String>[];

      final outputPath = await service.generateVideo(
        screenshotPaths: [png.path],
        audioPath: 'audio.mp3',
        surahName: 'Al-Baqarah',
        reciterName: 'Al-Afasy',
        progressMessages: _messages,
        onProgress: (p, m) {
          progress.add(p);
          messages.add(m);
        },
      );

      expect(outputPath, endsWith('.mp4'));
      expect(File(outputPath).path, startsWith(_shareDir().path));

      // First progress: prepare-encoding @ 0.10
      expect(progress.first, closeTo(0.10, 1e-9));
      expect(messages.first, _messages.preparingVideoEncoding);

      // Second progress: encode-start @ 0.30
      expect(progress[1], closeTo(0.30, 1e-9));
      expect(messages[1], _messages.encodingVerticalVideo);

      // Stat-driven progress events stay strictly within (0.30, 0.90].
      final statDriven = progress.sublist(2, progress.length - 1);
      for (final value in statDriven) {
        expect(value, greaterThan(0.30));
        expect(value, lessThanOrEqualTo(0.90));
      }
      // Last stat-driven progress is clamped to the upper bound.
      expect(statDriven.last, closeTo(0.90, 1e-9));

      // Final progress: 1.0 with the success message.
      expect(progress.last, 1.0);
      expect(messages.last, _messages.videoGenerated);

      // Strictly non-decreasing.
      for (var i = 1; i < progress.length; i++) {
        expect(
          progress[i],
          greaterThanOrEqualTo(progress[i - 1]),
          reason: 'progress regressed at index $i',
        );
      }
    });

    test('falls back to fallback duration when ffprobe returns null', () async {
      // When the audio probe fails, the service falls back to
      // `fallbackSecondsPerSlide × slideCount` seconds for both the encode
      // duration AND the stats-driven progress denominator. So stats DO
      // still drive progress; this test pins that contract.
      final runner = FakeFFmpegRunner()
        ..onAsyncCommand = _seedOutputFromCommand;
      runner.asyncPlans.add(
        FakeAsyncPlan.success(stats: const [FFmpegStatsSnapshot(timeMs: 5000)]),
      );
      runner.mediaInfoResults.addAll([
        null, // probe failed
        const FFmpegMediaInfo(durationSeconds: 10.0), // output validate ok
      ]);
      final service = VideoService(ShareFileManager(), runner);
      final png = await _writeFile(_platformTempDir, 'slide.png', size: 16);

      final progress = <double>[];
      await service.generateVideo(
        screenshotPaths: [png.path],
        audioPath: 'audio.mp3',
        surahName: 'X',
        reciterName: 'Y',
        progressMessages: _messages,
        onProgress: (p, _) => progress.add(p),
      );

      // prepare(0.10) → encode-start(0.30) → 1 stat-driven → final(1.0).
      // The stat is 5000ms / 90000ms (90s fallback × 1 slide) ≈ 5.6%
      // mapped into (0.30, 0.90] → ≈ 0.333.
      expect(progress.first, closeTo(0.10, 1e-9));
      expect(progress[1], closeTo(0.30, 1e-9));
      expect(progress.last, 1.0);
      // Stat-driven slot exists, falls strictly between encode-start and
      // the upper clamp.
      expect(progress, hasLength(4));
      expect(progress[2], greaterThan(0.30));
      expect(progress[2], lessThan(0.90));
    });

    test(
      'works when the caller passes no onProgress (stats are silently dropped)',
      () async {
        final runner = FakeFFmpegRunner()
          ..onAsyncCommand = _seedOutputFromCommand;
        runner.asyncPlans.add(
          FakeAsyncPlan.success(
            stats: const [FFmpegStatsSnapshot(timeMs: 1000)],
          ),
        );
        runner.mediaInfoResults.addAll([
          const FFmpegMediaInfo(durationSeconds: 10.0),
          const FFmpegMediaInfo(durationSeconds: 10.0),
        ]);
        final service = VideoService(ShareFileManager(), runner);
        final png = await _writeFile(_platformTempDir, 'slide.png', size: 16);

        await service.generateVideo(
          screenshotPaths: [png.path],
          audioPath: 'audio.mp3',
          surahName: 'X',
          reciterName: 'Y',
          progressMessages: _messages,
        );
      },
    );
  });

  group('generateVideo — encode failure classification', () {
    Future<void> expectFailure({
      required String logs,
      required VideoGenerationFailureReason expectedReason,
    }) async {
      final runner = FakeFFmpegRunner();
      runner.asyncPlans.add(FakeAsyncPlan.failure(logs: logs));
      runner.mediaInfoResults.add(const FFmpegMediaInfo(durationSeconds: 10.0));
      final service = VideoService(ShareFileManager(), runner);
      final png = await _writeFile(_platformTempDir, 'slide.png', size: 16);

      await expectLater(
        service.generateVideo(
          screenshotPaths: [png.path],
          audioPath: 'audio.mp3',
          surahName: 'X',
          reciterName: 'Y',
          progressMessages: _messages,
        ),
        throwsA(_failureWithReason(expectedReason)),
      );
    }

    test('"Invalid pixel format" log → invalidFrameFormat', () async {
      await expectFailure(
        logs: 'x264 [error]: Invalid pixel format',
        expectedReason: VideoGenerationFailureReason.invalidFrameFormat,
      );
    });

    test('"rawvideo" log → invalidFrameFormat', () async {
      await expectFailure(
        logs: 'cannot decode rawvideo stream',
        expectedReason: VideoGenerationFailureReason.invalidFrameFormat,
      );
    });

    test(
      '"Could not find codec parameters..." log → invalidFrameFormat',
      () async {
        await expectFailure(
          logs: 'Could not find codec parameters for stream 0',
          expectedReason: VideoGenerationFailureReason.invalidFrameFormat,
        );
      },
    );

    test('generic failure log → encodingFailed', () async {
      await expectFailure(
        logs: 'something else exploded',
        expectedReason: VideoGenerationFailureReason.encodingFailed,
      );
    });
  });

  group('generateVideo — cancellation', () {
    test(
      'maps a cancelled session to a DioException.requestCancelled',
      () async {
        final runner = FakeFFmpegRunner();
        runner.asyncPlans.add(FakeAsyncPlan.cancelled());
        runner.mediaInfoResults.add(
          const FFmpegMediaInfo(durationSeconds: 10.0),
        );
        final service = VideoService(ShareFileManager(), runner);
        final png = await _writeFile(_platformTempDir, 'slide.png', size: 16);

        await expectLater(
          service.generateVideo(
            screenshotPaths: [png.path],
            audioPath: 'audio.mp3',
            surahName: 'X',
            reciterName: 'Y',
            progressMessages: _messages,
          ),
          throwsA(
            isA<DioException>().having(
              (e) => e.type,
              'type',
              DioExceptionType.cancel,
            ),
          ),
        );
      },
    );

    test('cancelToken.cancel() forwards to FFmpegRunHandle.cancel()', () async {
      final runner = FakeFFmpegRunner();
      runner.asyncPlans.add(
        FakeAsyncPlan(
          // result is moot — cancel short-circuits via respectCancel=true.
          result: const FFmpegRunResult(status: FFmpegRunStatus.success),
          manualCompletion: true,
        ),
      );
      runner.mediaInfoResults.add(const FFmpegMediaInfo(durationSeconds: 10.0));
      final service = VideoService(ShareFileManager(), runner);
      final png = await _writeFile(_platformTempDir, 'slide.png', size: 16);
      final cancelToken = CancelToken();

      final future = service.generateVideo(
        screenshotPaths: [png.path],
        audioPath: 'audio.mp3',
        surahName: 'X',
        reciterName: 'Y',
        progressMessages: _messages,
        cancelToken: cancelToken,
      );

      // Let the encode start so the handle is in flight.
      await Future<void>.delayed(Duration.zero);
      cancelToken.cancel();

      await expectLater(
        future,
        throwsA(
          isA<DioException>().having(
            (e) => e.type,
            'type',
            DioExceptionType.cancel,
          ),
        ),
      );
      expect(runner.handles.single.cancelCalled, isTrue);
    });
  });

  group('generateVideo — output validation', () {
    test('missing output file → invalidOutput', () async {
      // No onAsyncCommand → no output file is seeded.
      final runner = FakeFFmpegRunner();
      runner.asyncPlans.add(FakeAsyncPlan.success());
      runner.mediaInfoResults.add(const FFmpegMediaInfo(durationSeconds: 10.0));
      final service = VideoService(ShareFileManager(), runner);
      final png = await _writeFile(_platformTempDir, 'slide.png', size: 16);

      await expectLater(
        service.generateVideo(
          screenshotPaths: [png.path],
          audioPath: 'audio.mp3',
          surahName: 'X',
          reciterName: 'Y',
          progressMessages: _messages,
        ),
        throwsA(_failureWithReason(VideoGenerationFailureReason.invalidOutput)),
      );
    });

    test('output too small (<8KB) → invalidOutput', () async {
      // Seed a 1KB file at the chosen output path.
      final runner = FakeFFmpegRunner()
        ..onAsyncCommand = (cmd) =>
            _seedOutputFromCommand(cmd, sizeBytes: 1024);
      runner.asyncPlans.add(FakeAsyncPlan.success());
      runner.mediaInfoResults.add(const FFmpegMediaInfo(durationSeconds: 10.0));
      final service = VideoService(ShareFileManager(), runner);
      final png = await _writeFile(_platformTempDir, 'slide.png', size: 16);

      await expectLater(
        service.generateVideo(
          screenshotPaths: [png.path],
          audioPath: 'audio.mp3',
          surahName: 'X',
          reciterName: 'Y',
          progressMessages: _messages,
        ),
        throwsA(_failureWithReason(VideoGenerationFailureReason.invalidOutput)),
      );
    });

    test('output ffprobe returns null → invalidOutput', () async {
      final runner = FakeFFmpegRunner()
        ..onAsyncCommand = _seedOutputFromCommand;
      runner.asyncPlans.add(FakeAsyncPlan.success());
      runner.mediaInfoResults.addAll([
        const FFmpegMediaInfo(durationSeconds: 10.0), // probe
        null, // output validation
      ]);
      final service = VideoService(ShareFileManager(), runner);
      final png = await _writeFile(_platformTempDir, 'slide.png', size: 16);

      await expectLater(
        service.generateVideo(
          screenshotPaths: [png.path],
          audioPath: 'audio.mp3',
          surahName: 'X',
          reciterName: 'Y',
          progressMessages: _messages,
        ),
        throwsA(_failureWithReason(VideoGenerationFailureReason.invalidOutput)),
      );
    });

    test('output duration <= 0 → invalidOutput', () async {
      final runner = FakeFFmpegRunner()
        ..onAsyncCommand = _seedOutputFromCommand;
      runner.asyncPlans.add(FakeAsyncPlan.success());
      runner.mediaInfoResults.addAll([
        const FFmpegMediaInfo(durationSeconds: 10.0),
        const FFmpegMediaInfo(durationSeconds: 0.0),
      ]);
      final service = VideoService(ShareFileManager(), runner);
      final png = await _writeFile(_platformTempDir, 'slide.png', size: 16);

      await expectLater(
        service.generateVideo(
          screenshotPaths: [png.path],
          audioPath: 'audio.mp3',
          surahName: 'X',
          reciterName: 'Y',
          progressMessages: _messages,
        ),
        throwsA(_failureWithReason(VideoGenerationFailureReason.invalidOutput)),
      );
    });
  });

  group('buildSlideDurations', () {
    final service = VideoService(ShareFileManager(), FakeFFmpegRunner());

    test('falls back to fallbackSecondsPerSlide × N when audio is null', () {
      final durations = service.buildSlideDurations(
        slideCount: 4,
        audioDurationSeconds: null,
      );
      expect(durations, hasLength(4));
      expect(durations.fold<double>(0, (a, b) => a + b), closeTo(360.0, 1e-9));
      for (final d in durations) {
        expect(d, closeTo(90.0, 1e-9));
      }
    });

    test('falls back when audio duration is non-positive', () {
      final durations = service.buildSlideDurations(
        slideCount: 2,
        audioDurationSeconds: 0,
      );
      expect(durations, hasLength(2));
      expect(durations.fold<double>(0, (a, b) => a + b), closeTo(180.0, 1e-9));
    });

    test(
      'distributes total exactly — last slide absorbs the rounding remainder',
      () {
        final durations = service.buildSlideDurations(
          slideCount: 3,
          audioDurationSeconds: 10.0,
        );
        expect(durations.fold<double>(0, (a, b) => a + b), closeTo(10.0, 1e-9));
        expect(durations[0], closeTo(10 / 3, 1e-9));
        expect(durations[1], closeTo(10 / 3, 1e-9));
      },
    );

    test('clamps the last slide to a minimum of 0.001s', () {
      final durations = service.buildSlideDurations(
        slideCount: 100,
        audioDurationSeconds: 1.0,
      );
      expect(durations.last, greaterThanOrEqualTo(0.001));
    });
  });

  group('buildSingleImageCommand', () {
    final service = VideoService(ShareFileManager(), FakeFFmpegRunner());

    test('PNG path: no rawvideo decoder flags, has loop+t, has metadata', () {
      final cmd = service.buildSingleImageCommand(
        screenshotPath: '/tmp/slide.png',
        audioPath: '/tmp/a.mp3',
        surahName: 'Al-Fatiha',
        reciterName: 'Sudais',
        outputPath: '/tmp/out.mp4',
        audioDurationSeconds: 12.345,
      );
      expect(cmd, isNot(contains('-f rawvideo')));
      expect(cmd, contains('-loop 1'));
      expect(cmd, contains('-t 12.345'));
      expect(cmd, contains('-i "/tmp/slide.png"'));
      expect(cmd, contains('-i "/tmp/a.mp3"'));
      expect(cmd, contains('"/tmp/out.mp4"'));
      expect(cmd, contains('title="Al-Fatiha Video"'));
      expect(cmd, contains('artist="Sudais"'));
      expect(cmd, contains('-pix_fmt yuv420p'));
      expect(cmd, contains('-shortest'));
      expect(cmd, contains('+faststart'));
    });

    test('RAW path: includes rawvideo decoder flags + filter_complex', () {
      final cmd = service.buildSingleImageCommand(
        screenshotPath: '/tmp/slide.raw',
        audioPath: '/tmp/a.mp3',
        surahName: 'X',
        reciterName: 'Y',
        outputPath: '/tmp/out.mp4',
        audioDurationSeconds: 7.5,
      );
      expect(cmd, contains('-f rawvideo'));
      expect(cmd, contains('-pixel_format rgba'));
      expect(
        cmd,
        contains(
          '-video_size '
          '${ShareVideoProfile.outputWidthPx}x${ShareVideoProfile.outputHeightPx}',
        ),
      );
      expect(cmd, contains('trim=duration=7.500'));
      expect(cmd, contains('filter_complex'));
      expect(cmd, contains('[0:v]loop=loop=-1:size=1:start=0'));
      expect(cmd, contains('-map "[v]"'));
      expect(cmd, contains('-map 1:a'));
    });
  });

  group('buildSlideshowCommand', () {
    final service = VideoService(ShareFileManager(), FakeFFmpegRunner());

    test(
      'mixed PNG + RAW slides: per-input flags chosen correctly + linear filter graph',
      () {
        final cmd = service.buildSlideshowCommand(
          screenshotPaths: ['/tmp/a.png', '/tmp/b.raw', '/tmp/c.png'],
          audioPath: '/tmp/a.mp3',
          surahName: 'S',
          reciterName: 'R',
          outputPath: '/tmp/out.mp4',
          audioDurationSeconds: 30.0,
        );

        expect('-loop 1'.allMatches(cmd).length, 2);
        expect('-f rawvideo'.allMatches(cmd).length, 1);

        // The audio is the *last* `-i`; its index is `screenshotPaths.length`.
        expect(cmd, contains('-i "/tmp/a.mp3"'));
        expect(cmd, contains('-map 3:a'));

        for (var i = 0; i < 3; i++) {
          expect(
            '[v$i]'.allMatches(cmd).length,
            greaterThanOrEqualTo(2),
            reason:
                'slide $i must appear at least twice (definition + concat input)',
          );
        }
        expect(cmd, contains('concat=n=3:v=1:a=0[v]'));
      },
    );

    test('all PNG slides: no rawvideo flags emitted', () {
      final cmd = service.buildSlideshowCommand(
        screenshotPaths: ['/tmp/a.png', '/tmp/b.png'],
        audioPath: '/tmp/a.mp3',
        surahName: 'S',
        reciterName: 'R',
        outputPath: '/tmp/out.mp4',
        audioDurationSeconds: 10.0,
      );
      expect(cmd, isNot(contains('-f rawvideo')));
      expect(cmd, contains('concat=n=2:v=1:a=0[v]'));
    });

    test('all RAW slides: rawvideo flags emitted per slide; no -loop 1', () {
      final cmd = service.buildSlideshowCommand(
        screenshotPaths: ['/tmp/a.raw', '/tmp/b.raw'],
        audioPath: '/tmp/a.mp3',
        surahName: 'S',
        reciterName: 'R',
        outputPath: '/tmp/out.mp4',
        audioDurationSeconds: 10.0,
      );
      expect('-f rawvideo'.allMatches(cmd).length, 2);
      expect(cmd, isNot(contains('-loop 1')));
    });
  });
}

// ---------- helpers ----------

Matcher _failureWithReason(VideoGenerationFailureReason reason) =>
    isA<VideoGenerationFailure>().having((f) => f.reason, 'reason', reason);

Future<File> _writeFile(Directory dir, String name, {required int size}) async {
  final f = File(p.join(dir.path, name));
  await f.writeAsBytes(List<int>.filled(size, 0), flush: true);
  return f;
}

/// The share temp directory the [ShareFileManager] uses, given our
/// [_platformTempDir] mock.
Directory _shareDir() =>
    Directory(p.join(_platformTempDir.path, 'tilawa_share'));

/// Extracts the output path from a recorded FFmpeg command and writes a
/// stand-in file at that path so the post-encode validation can succeed.
/// The service's command builders quote the output path with double quotes
/// and place it last (`-y "<path>"`), so we grab the final quoted token.
void _seedOutputFromCommand(String command, {int sizeBytes = 16 * 1024}) {
  final match = RegExp(r'"([^"]+)"\s*$').firstMatch(command.trimRight());
  if (match == null) return;
  final outPath = match.group(1)!;
  final file = File(outPath);
  if (!file.parent.existsSync()) file.parent.createSync(recursive: true);
  file.writeAsBytesSync(List<int>.filled(sizeBytes, 0), flush: true);
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
