import 'package:audio_service/audio_service.dart' as audio_service;
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/audio_player/domain/resolve_media_session_update_position.dart';
import 'package:tilawa/features/audio_player/domain/resolve_playback_display_position.dart';
import 'package:tilawa_core/entities/audio.dart';

/// Documents Android notification vs in-app player scenarios from QA screenshots.
///
/// Automated tests cover the Dart contract (handler → audio_service → bloc).
/// Android shade scrubber pixels require manual or Maestro+screenshot diff.
void main() {
  group('scenario: paused at ~90% (notification matches app)', () {
    test('MediaSession updatePosition stays at paused engine progress', () {
      const Duration pausedAt = Duration(minutes: 43);
      final Duration published = resolveMediaSessionUpdatePosition(
        enginePosition: pausedAt,
        previousUpdatePosition: const Duration(minutes: 40),
        playing: false,
        engineReady: true,
      );
      expect(published, pausedAt);
    });

    test('in-app scrubber uses playback state when stream is idle', () {
      final Duration ui = resolvePlaybackDisplayPosition(
        playbackState: _readyState(position: const Duration(minutes: 43)),
        streamPosition: Duration.zero,
      );
      expect(ui, const Duration(minutes: 43));
    });
  });

  group('scenario: resume play scrubber at start (regression)', () {
    test('does not publish zero over long paused progress', () {
      final Duration published = resolveMediaSessionUpdatePosition(
        enginePosition: Duration.zero,
        previousUpdatePosition: const Duration(minutes: 43),
        playing: true,
        engineReady: true,
      );
      expect(published, const Duration(minutes: 43));
    });

    test('once engine reports progress both layers align', () {
      const Duration engine = Duration(minutes: 43, seconds: 2);
      final Duration media = resolveMediaSessionUpdatePosition(
        enginePosition: engine,
        previousUpdatePosition: const Duration(minutes: 43),
        playing: true,
        engineReady: true,
      );
      final Duration ui = resolvePlaybackDisplayPosition(
        playbackState: _readyState(position: engine),
        streamPosition: engine,
      );
      expect(media, engine);
      expect(ui, engine);
    });
  });

  group('parity contract: MediaSession position vs in-app display', () {
    test('same inputs produce equal resolved positions', () {
      const Duration engine = Duration(minutes: 12, seconds: 36);
      final audio_service.PlaybackState mediaState =
          audio_service.PlaybackState(
            playing: true,
            processingState: audio_service.AudioProcessingState.ready,
            updatePosition: resolveMediaSessionUpdatePosition(
              enginePosition: engine,
              previousUpdatePosition: Duration.zero,
              playing: true,
              engineReady: true,
            ),
          );

      final Duration inAppPosition = resolvePlaybackDisplayPosition(
        playbackState: _readyState(position: mediaState.updatePosition),
        streamPosition: mediaState.updatePosition,
      );

      expect(mediaState.updatePosition, engine);
      expect(inAppPosition, engine);
    });
  });
}

PlaybackStateEntity _readyState({required Duration position}) {
  return PlaybackStateEntity(
    isPlaying: true,
    processingState: AudioProcessingStateStatus.ready,
    position: position,
    bufferedPosition: Duration.zero,
    duration: const Duration(hours: 1),
    currentIndex: 0,
    queue: const <AudioEntity>[],
  );
}
