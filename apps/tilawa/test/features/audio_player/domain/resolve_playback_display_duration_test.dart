import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/audio_player/domain/resolved_playback_duration.dart';
import 'package:tilawa_core/entities/audio.dart';

AudioEntity _audio({
  required String id,
  Duration duration = Duration.zero,
}) {
  return AudioEntity(
    id: id,
    title: 'Surah',
    url: 'https://example.com/$id.mp3',
    duration: duration,
    artist: 'Reciter',
  );
}

PlaybackStateEntity _playback({
  required Duration duration,
  List<AudioEntity> queue = const <AudioEntity>[],
}) {
  return PlaybackStateEntity(
    isPlaying: true,
    processingState: AudioProcessingStateStatus.ready,
    position: Duration.zero,
    bufferedPosition: Duration.zero,
    duration: duration,
    currentIndex: 0,
    queue: queue,
  );
}

void main() {
  group('resolvePlaybackDisplayDuration', () {
    test('prefers live playback duration for current track', () {
      final AudioEntity audio = _audio(
        id: 'a1',
        duration: const Duration(hours: 1, minutes: 17),
      );
      final PlaybackStateEntity playback = _playback(
        duration: const Duration(minutes: 33),
      );

      final Duration resolved = resolvePlaybackDisplayDuration(
        audio: audio,
        playbackState: playback,
        isCurrentPlayback: true,
        cachedDurations: const <String, Duration>{},
      );

      expect(resolved, const Duration(minutes: 33));
    });

    test('falls back to metadata when playback duration is zero', () {
      final AudioEntity audio = _audio(
        id: 'a1',
        duration: const Duration(minutes: 40),
      );

      final Duration resolved = resolvePlaybackDisplayDuration(
        audio: audio,
        playbackState: _playback(duration: Duration.zero),
        isCurrentPlayback: true,
        cachedDurations: const <String, Duration>{},
      );

      expect(resolved, const Duration(minutes: 40));
    });

    test('uses queue item duration when not current playback', () {
      final AudioEntity current = _audio(id: 'current');
      final AudioEntity queued = _audio(
        id: 'queued',
        duration: const Duration(minutes: 12),
      );
      final PlaybackStateEntity playback = _playback(
        duration: const Duration(minutes: 33),
        queue: <AudioEntity>[current, queued],
      );

      final Duration resolved = resolvePlaybackDisplayDuration(
        audio: queued,
        playbackState: playback,
        isCurrentPlayback: false,
        cachedDurations: const <String, Duration>{},
      );

      expect(resolved, const Duration(minutes: 12));
    });
  });
}
