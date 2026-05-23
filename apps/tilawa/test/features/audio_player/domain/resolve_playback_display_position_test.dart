import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/audio_player/domain/resolve_playback_display_position.dart';
import 'package:tilawa_core/entities/audio.dart';

PlaybackStateEntity _playback({Duration position = Duration.zero}) {
  return PlaybackStateEntity(
    isPlaying: true,
    processingState: AudioProcessingStateStatus.ready,
    position: position,
    bufferedPosition: Duration.zero,
    duration: const Duration(minutes: 1),
    currentIndex: 0,
    queue: const <AudioEntity>[],
  );
}

void main() {
  group('resolvePlaybackDisplayPosition', () {
    test('prefers stream position when both are available', () {
      final Duration resolved = resolvePlaybackDisplayPosition(
        playbackState: _playback(position: const Duration(seconds: 20)),
        streamPosition: const Duration(seconds: 25),
      );

      expect(resolved, const Duration(seconds: 25));
    });

    test('falls back to playback state when stream is zero', () {
      final Duration resolved = resolvePlaybackDisplayPosition(
        playbackState: _playback(position: const Duration(seconds: 15)),
        streamPosition: Duration.zero,
      );

      expect(resolved, const Duration(seconds: 15));
    });

    test('returns zero when both sources are zero', () {
      final Duration resolved = resolvePlaybackDisplayPosition(
        playbackState: null,
        streamPosition: Duration.zero,
      );

      expect(resolved, Duration.zero);
    });
  });
}
