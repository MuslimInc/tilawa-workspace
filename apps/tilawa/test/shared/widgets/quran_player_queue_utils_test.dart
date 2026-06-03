import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/audio_player/presentation/bloc/audio_player_bloc.dart';
import 'package:tilawa/shared/models/position_data.dart';
import 'package:tilawa/shared/widgets/quran_player_queue_utils.dart';
import 'package:tilawa/shared/widgets/quran_player_transport_controls.dart';
import 'package:tilawa_core/entities/audio.dart';

const AudioEntity _trackA = AudioEntity(
  id: 'a',
  title: 'Al-Fatiha',
  url: 'https://example.com/a.mp3',
  duration: Duration(minutes: 3),
);

const AudioEntity _trackB = AudioEntity(
  id: 'b',
  title: 'Al-Baqarah',
  url: 'https://example.com/b.mp3',
  duration: Duration(minutes: 3),
);

const AudioEntity _trackC = AudioEntity(
  id: 'c',
  title: 'Ali Imran',
  url: 'https://example.com/c.mp3',
  duration: Duration(minutes: 3),
);

PlaybackStateEntity _playbackState({
  required List<AudioEntity> queue,
  int currentIndex = 0,
  Duration position = Duration.zero,
  int queueGeneration = 0,
}) {
  return PlaybackStateEntity(
    isPlaying: true,
    processingState: AudioProcessingStateStatus.ready,
    position: position,
    bufferedPosition: Duration.zero,
    duration: const Duration(minutes: 3),
    currentIndex: currentIndex,
    queue: queue,
    queueGeneration: queueGeneration,
  );
}

AudioPlayerState _playerState({
  PlaybackStateEntity? playbackState,
  PositionData? positionData,
}) {
  return AudioPlayerState(
    status: AudioPlayerStatus.success,
    currentAudio: _trackA,
    playbackState: playbackState,
    positionData: positionData,
  );
}

void main() {
  group('QuranPlayerQueueUtils.queueSnapshotChanged', () {
    test('returns false in O(1) when queueGeneration is unchanged', () {
      const List<AudioEntity> queue = <AudioEntity>[_trackA, _trackB];

      expect(
        QuranPlayerQueueUtils.queueSnapshotChanged(
          previousQueue: queue,
          currentQueue: List<AudioEntity>.from(queue),
          previousIndex: 0,
          currentIndex: 0,
          previousQueueGeneration: 3,
          currentQueueGeneration: 3,
        ),
        isFalse,
      );
    });

    test('returns true in O(1) when queueGeneration changes', () {
      expect(
        QuranPlayerQueueUtils.queueSnapshotChanged(
          previousQueue: const <AudioEntity>[_trackA, _trackB],
          currentQueue: const <AudioEntity>[_trackB, _trackA],
          previousIndex: 0,
          currentIndex: 0,
          previousQueueGeneration: 1,
          currentQueueGeneration: 2,
        ),
        isTrue,
      );
    });

    test('returns true in O(1) when generation matches but index changes', () {
      const List<AudioEntity> queue = <AudioEntity>[_trackA, _trackB];

      expect(
        QuranPlayerQueueUtils.queueSnapshotChanged(
          previousQueue: queue,
          currentQueue: queue,
          previousIndex: 0,
          currentIndex: 1,
          previousQueueGeneration: 5,
          currentQueueGeneration: 5,
        ),
        isTrue,
      );
    });

    test('returns false when queue order and index are unchanged', () {
      const List<AudioEntity> queue = <AudioEntity>[_trackA, _trackB];

      expect(
        QuranPlayerQueueUtils.queueSnapshotChanged(
          previousQueue: queue,
          currentQueue: queue,
          previousIndex: 0,
          currentIndex: 0,
        ),
        isFalse,
      );
    });

    test('returns false when only AudioEntity instances differ by identity', () {
      final List<AudioEntity> previous = <AudioEntity>[
        _trackA.copyWith(title: 'A prev'),
        _trackB,
      ];
      final List<AudioEntity> current = <AudioEntity>[
        _trackA.copyWith(title: 'A next'),
        _trackB,
      ];

      expect(
        QuranPlayerQueueUtils.queueSnapshotChanged(
          previousQueue: previous,
          currentQueue: current,
          previousIndex: 0,
          currentIndex: 0,
        ),
        isFalse,
      );
    });

    test('returns true when queue item order changes without generation', () {
      expect(
        QuranPlayerQueueUtils.queueSnapshotChanged(
          previousQueue: const <AudioEntity>[_trackA, _trackB, _trackC],
          currentQueue: const <AudioEntity>[_trackB, _trackA, _trackC],
          previousIndex: 0,
          currentIndex: 0,
        ),
        isTrue,
      );
    });

    test('returns true when queue length increases', () {
      expect(
        QuranPlayerQueueUtils.queueSnapshotChanged(
          previousQueue: const <AudioEntity>[_trackA],
          currentQueue: const <AudioEntity>[_trackA, _trackB],
          previousIndex: 0,
          currentIndex: 0,
        ),
        isTrue,
      );
    });

    test('returns true when queue length decreases', () {
      expect(
        QuranPlayerQueueUtils.queueSnapshotChanged(
          previousQueue: const <AudioEntity>[_trackA, _trackB],
          currentQueue: const <AudioEntity>[_trackA],
          previousIndex: 1,
          currentIndex: 0,
        ),
        isTrue,
      );
    });

    test('returns true when only currentIndex changes without generation', () {
      const List<AudioEntity> queue = <AudioEntity>[_trackA, _trackB];

      expect(
        QuranPlayerQueueUtils.queueSnapshotChanged(
          previousQueue: queue,
          currentQueue: queue,
          previousIndex: 0,
          currentIndex: 1,
        ),
        isTrue,
      );
    });

    test('returns false when both queues are null or empty', () {
      expect(
        QuranPlayerQueueUtils.queueSnapshotChanged(
          previousQueue: null,
          currentQueue: null,
          previousIndex: null,
          currentIndex: null,
        ),
        isFalse,
      );
      expect(
        QuranPlayerQueueUtils.queueSnapshotChanged(
          previousQueue: const <AudioEntity>[],
          currentQueue: const <AudioEntity>[],
          previousIndex: 0,
          currentIndex: 0,
        ),
        isFalse,
      );
    });

    test('returns true when queue appears from empty', () {
      expect(
        QuranPlayerQueueUtils.queueSnapshotChanged(
          previousQueue: const <AudioEntity>[],
          currentQueue: const <AudioEntity>[_trackA, _trackB],
          previousIndex: null,
          currentIndex: 0,
        ),
        isTrue,
      );
    });
  });

  group('QuranPlayerQueueUtils.queueIndexById', () {
    test('maps ids to indices after reorder', () {
      const List<AudioEntity> queue = <AudioEntity>[_trackB, _trackA, _trackC];

      expect(
        QuranPlayerQueueUtils.queueIndexById(queue),
        <String, int>{'b': 0, 'a': 1, 'c': 2},
      );
    });
  });

  group('QuranPlayerQueueIndexCache', () {
    test('reuses map in O(1) when generation and queue are stable', () {
      final QuranPlayerQueueIndexCache cache = QuranPlayerQueueIndexCache();
      const List<AudioEntity> queue = <AudioEntity>[_trackA, _trackB];

      final Map<String, int> first = cache.indexByIdFor(
        queue: queue,
        queueGeneration: 3,
      );
      final Map<String, int> second = cache.indexByIdFor(
        queue: queue,
        queueGeneration: 3,
      );

      expect(identical(first, second), isTrue);
      expect(first, <String, int>{'a': 0, 'b': 1});
    });

    test('rebuilds map when queueGeneration changes', () {
      final QuranPlayerQueueIndexCache cache = QuranPlayerQueueIndexCache();
      const List<AudioEntity> queue = <AudioEntity>[_trackA, _trackB];

      final Map<String, int> first = cache.indexByIdFor(
        queue: queue,
        queueGeneration: 1,
      );
      final Map<String, int> second = cache.indexByIdFor(
        queue: const <AudioEntity>[_trackB, _trackA],
        queueGeneration: 2,
      );

      expect(identical(first, second), isFalse);
      expect(second, <String, int>{'b': 0, 'a': 1});
    });

    test('clear drops cached map', () {
      final QuranPlayerQueueIndexCache cache = QuranPlayerQueueIndexCache();
      const List<AudioEntity> queue = <AudioEntity>[_trackA];

      final Map<String, int> first = cache.indexByIdFor(
        queue: queue,
        queueGeneration: 1,
      );
      cache.clear();
      final Map<String, int> second = cache.indexByIdFor(
        queue: queue,
        queueGeneration: 1,
      );

      expect(identical(first, second), isFalse);
    });

    test('indexBySurahIdFor provides O(1) surah lookup', () {
      final QuranPlayerQueueIndexCache cache = QuranPlayerQueueIndexCache();
      final List<AudioEntity> queue = <AudioEntity>[
        const AudioEntity(
          id: 'a',
          title: 'A',
          url: 'u',
          duration: Duration.zero,
          extras: <String, dynamic>{'surahId': 1},
        ),
        const AudioEntity(
          id: 'b',
          title: 'B',
          url: 'u',
          duration: Duration.zero,
          extras: <String, dynamic>{'surahId': 2},
        ),
      ];

      final Map<String, int> bySurah = cache.indexBySurahIdFor(
        queue: queue,
        queueGeneration: 3,
      );

      expect(bySurah['1'], 0);
      expect(bySurah['2'], 1);
    });
  });

  group('QuranPlayerQueueUtils.findReorderableChildIndex', () {
    late Map<String, int> indexById;

    setUp(() {
      indexById = QuranPlayerQueueUtils.queueIndexById(
        const <AudioEntity>[_trackB, _trackA, _trackC],
      );
    });

    test('returns index for ValueKey id', () {
      expect(
        QuranPlayerQueueUtils.findReorderableChildIndex(
          indexById: indexById,
          key: const ValueKey<String>('a'),
        ),
        1,
      );
    });

    test('returns null when id is not in queue', () {
      expect(
        QuranPlayerQueueUtils.findReorderableChildIndex(
          indexById: indexById,
          key: const ValueKey<String>('missing'),
        ),
        isNull,
      );
    });

    test('returns null for non-ValueKey keys', () {
      expect(
        QuranPlayerQueueUtils.findReorderableChildIndex(
          indexById: indexById,
          key: const ObjectKey('a'),
        ),
        isNull,
      );
    });
  });

  group('QuranPlayerQueueUtils.playerTreeQueueChanged', () {
    test('detects reorder via queueGeneration on playbackState', () {
      final AudioPlayerState previous = _playerState(
        playbackState: _playbackState(
          queue: const <AudioEntity>[_trackA, _trackB],
          queueGeneration: 1,
        ),
      );
      final AudioPlayerState current = previous.copyWith(
        playbackState: previous.playbackState!.copyWith(
          queue: const <AudioEntity>[_trackB, _trackA],
          queueGeneration: 2,
        ),
      );

      expect(
        QuranPlayerQueueUtils.playerTreeQueueChanged(previous, current),
        isTrue,
      );
    });

    test('ignores position-only playbackState when generation is stable', () {
      final AudioPlayerState previous = _playerState(
        playbackState: _playbackState(
          queue: const <AudioEntity>[_trackA, _trackB],
          queueGeneration: 4,
          position: Duration.zero,
        ),
      );
      final AudioPlayerState current = previous.copyWith(
        playbackState: previous.playbackState!.copyWith(
          position: const Duration(seconds: 42),
        ),
      );

      expect(
        QuranPlayerQueueUtils.playerTreeQueueChanged(previous, current),
        isFalse,
      );
    });
  });

  group('QuranPlayerTransportControls.playerTreeBuildWhen', () {
    test('rebuilds when queue order changes via generation', () {
      final AudioPlayerState previous = _playerState(
        playbackState: _playbackState(
          queue: const <AudioEntity>[_trackA, _trackB],
          queueGeneration: 1,
        ),
      );
      final AudioPlayerState current = previous.copyWith(
        playbackState: previous.playbackState!.copyWith(
          queueGeneration: 2,
        ),
      );

      expect(
        QuranPlayerTransportControls.playerTreeBuildWhen(previous, current),
        isTrue,
      );
    });

    test('does not rebuild when only position data changes', () {
      final AudioPlayerState previous = _playerState(
        playbackState: _playbackState(
          queue: const <AudioEntity>[_trackA, _trackB],
          queueGeneration: 1,
        ),
      );
      final AudioPlayerState current = previous.copyWith(
        positionData: const PositionData(
          position: Duration(seconds: 30),
          bufferedPosition: Duration(seconds: 45),
          duration: Duration(minutes: 3),
        ),
      );

      expect(
        QuranPlayerTransportControls.playerTreeBuildWhen(previous, current),
        isFalse,
      );
    });

    test(
      'does not rebuild when only playback position changes in playbackState',
      () {
        final AudioPlayerState previous = _playerState(
          playbackState: _playbackState(
            queue: const <AudioEntity>[_trackA, _trackB],
            queueGeneration: 2,
            position: Duration.zero,
          ),
        );
        final AudioPlayerState current = previous.copyWith(
          playbackState: previous.playbackState!.copyWith(
            position: const Duration(seconds: 42),
          ),
        );

        expect(
          QuranPlayerTransportControls.playerTreeBuildWhen(previous, current),
          isFalse,
        );
      },
    );

    test('rebuilds when currentIndex changes without generation bump', () {
      final AudioPlayerState previous = _playerState(
        playbackState: _playbackState(
          queue: const <AudioEntity>[_trackA, _trackB],
          currentIndex: 0,
        ),
      );
      final AudioPlayerState current = previous.copyWith(
        playbackState: previous.playbackState!.copyWith(currentIndex: 1),
      );

      expect(
        QuranPlayerTransportControls.playerTreeBuildWhen(previous, current),
        isTrue,
      );
    });
  });
}
