import 'package:audio_service/audio_service.dart' as audio_service;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/audio_player/data/repositories/mapped_playback_queue_cache.dart';
import 'package:tilawa/features/audio_player/presentation/bloc/audio_player_bloc.dart';
import 'package:tilawa/shared/widgets/quran_player_queue_utils.dart';
import 'package:tilawa/shared/widgets/quran_player_transport_controls.dart';
import 'package:tilawa_core/entities/audio.dart';

import 'support/counting_audio_entity_list.dart';

const int _largeQueueSize = 5000;

AudioEntity _trackAt(int index) => AudioEntity(
  id: 'surah-$index',
  title: 'Surah $index',
  url: 'https://example.com/$index.mp3',
  duration: const Duration(minutes: 3),
);

audio_service.MediaItem _mediaItemAt(int index) => audio_service.MediaItem(
  id: 'surah-$index',
  title: 'Surah $index',
  extras: <String, dynamic>{'url': 'https://example.com/$index.mp3'},
);

List<AudioEntity> _orderedLargeQueue() =>
    List<AudioEntity>.generate(_largeQueueSize, _trackAt);

List<AudioEntity> _reversedLargeQueue() => List<AudioEntity>.generate(
  _largeQueueSize,
  (int i) => _trackAt(_largeQueueSize - 1 - i),
);

List<audio_service.MediaItem> _orderedLargeMediaQueue() =>
    List<audio_service.MediaItem>.generate(_largeQueueSize, _mediaItemAt);

AudioEntity _mapMediaItem(audio_service.MediaItem item) => AudioEntity(
  id: item.id,
  title: item.title,
  url: item.extras?['url'] as String? ?? item.id,
  duration: item.duration ?? Duration.zero,
);

void main() {
  group('O(1) hot path: queueSnapshotChanged with queueGeneration', () {
    late CountingAudioEntityList previousQueue;
    late CountingAudioEntityList currentQueue;

    setUp(() {
      previousQueue = CountingAudioEntityList(_orderedLargeQueue());
      currentQueue = CountingAudioEntityList(_reversedLargeQueue());
    });

    test(
      'stable generation and index does not read queue (even if ids differ)',
      () {
        final bool changed = QuranPlayerQueueUtils.queueSnapshotChanged(
          previousQueue: previousQueue,
          currentQueue: currentQueue,
          previousIndex: 0,
          currentIndex: 0,
          previousQueueGeneration: 42,
          currentQueueGeneration: 42,
        );

        expect(changed, isFalse);
        expect(previousQueue.totalAccessCount, 0);
        expect(currentQueue.totalAccessCount, 0);
      },
    );

    test('generation bump does not read queue', () {
      final bool changed = QuranPlayerQueueUtils.queueSnapshotChanged(
        previousQueue: previousQueue,
        currentQueue: currentQueue,
        previousIndex: 0,
        currentIndex: 0,
        previousQueueGeneration: 1,
        currentQueueGeneration: 2,
      );

      expect(changed, isTrue);
      expect(previousQueue.totalAccessCount, 0);
      expect(currentQueue.totalAccessCount, 0);
    });

    test('index change with stable generation does not read queue', () {
      final bool changed = QuranPlayerQueueUtils.queueSnapshotChanged(
        previousQueue: previousQueue,
        currentQueue: currentQueue,
        previousIndex: 0,
        currentIndex: 3,
        previousQueueGeneration: 9,
        currentQueueGeneration: 9,
      );

      expect(changed, isTrue);
      expect(previousQueue.totalAccessCount, 0);
      expect(currentQueue.totalAccessCount, 0);
    });
  });

  group('O(1) hot path: identical queue reference without generation', () {
    test('does not index-scan when previous and current are identical()', () {
      final CountingAudioEntityList queue = CountingAudioEntityList(
        _orderedLargeQueue(),
      );

      final bool changed = QuranPlayerQueueUtils.queueSnapshotChanged(
        previousQueue: queue,
        currentQueue: queue,
        previousIndex: 0,
        currentIndex: 0,
      );

      expect(changed, isFalse);
      expect(queue.totalAccessCount, 0);
    });
  });

  group('O(n) fallback: queueSnapshotChanged without queueGeneration', () {
    test('scans large queues when generation is omitted', () {
      final CountingAudioEntityList previousQueue = CountingAudioEntityList(
        _orderedLargeQueue(),
      );
      final CountingAudioEntityList currentQueue = CountingAudioEntityList(
        _orderedLargeQueue(),
      );

      final bool changed = QuranPlayerQueueUtils.queueSnapshotChanged(
        previousQueue: previousQueue,
        currentQueue: currentQueue,
        previousIndex: 0,
        currentIndex: 0,
      );

      expect(changed, isFalse);
      expect(previousQueue.lengthAccessCount, greaterThan(0));
      expect(previousQueue.indexAccessCount, _largeQueueSize);
      expect(currentQueue.indexAccessCount, _largeQueueSize);
    });

    test('detects reorder in fallback path with full scan', () {
      final CountingAudioEntityList previousQueue = CountingAudioEntityList(
        _orderedLargeQueue(),
      );
      final CountingAudioEntityList currentQueue = CountingAudioEntityList(
        _reversedLargeQueue(),
      );

      final bool changed = QuranPlayerQueueUtils.queueSnapshotChanged(
        previousQueue: previousQueue,
        currentQueue: currentQueue,
        previousIndex: 0,
        currentIndex: 0,
      );

      expect(changed, isTrue);
      expect(previousQueue.indexAccessCount, greaterThan(0));
    });
  });

  group('O(1) hot path: playerTreeQueueChanged on position ticks', () {
    test('does not scan queue when generation and index are stable', () {
      final CountingAudioEntityList queue = CountingAudioEntityList(
        _orderedLargeQueue(),
      );
      final AudioPlayerState previous = AudioPlayerState(
        status: AudioPlayerStatus.success,
        playbackState: PlaybackStateEntity(
          isPlaying: true,
          processingState: AudioProcessingStateStatus.ready,
          position: Duration.zero,
          bufferedPosition: Duration.zero,
          duration: const Duration(minutes: 3),
          currentIndex: 0,
          queue: queue,
          queueGeneration: 7,
        ),
      );
      final AudioPlayerState current = previous.copyWith(
        playbackState: previous.playbackState!.copyWith(
          position: const Duration(seconds: 90),
        ),
      );
      queue.resetCounts();

      final bool queueChanged = QuranPlayerQueueUtils.playerTreeQueueChanged(
        previous,
        current,
      );

      expect(queueChanged, isFalse);
      expect(queue.totalAccessCount, 0);
    });

    test('rebuilds in O(1) when only queueGeneration changes', () {
      final CountingAudioEntityList queue = CountingAudioEntityList(
        _orderedLargeQueue(),
      );
      final AudioPlayerState previous = AudioPlayerState(
        status: AudioPlayerStatus.success,
        playbackState: PlaybackStateEntity(
          isPlaying: true,
          processingState: AudioProcessingStateStatus.ready,
          position: Duration.zero,
          bufferedPosition: Duration.zero,
          duration: const Duration(minutes: 3),
          currentIndex: 0,
          queue: queue,
          queueGeneration: 1,
        ),
      );
      final AudioPlayerState current = previous.copyWith(
        playbackState: previous.playbackState!.copyWith(queueGeneration: 2),
      );
      queue.resetCounts();

      final bool queueChanged = QuranPlayerQueueUtils.playerTreeQueueChanged(
        previous,
        current,
      );

      expect(queueChanged, isTrue);
      expect(queue.totalAccessCount, 0);
    });
  });

  group('playerTreeBuildWhen queue leg uses O(1) generation check', () {
    test('rebuilds on generation change without index scan', () {
      final CountingAudioEntityList queue = CountingAudioEntityList(
        _orderedLargeQueue(),
      );
      final AudioPlayerState previous = AudioPlayerState(
        status: AudioPlayerStatus.success,
        playbackState: PlaybackStateEntity(
          isPlaying: true,
          processingState: AudioProcessingStateStatus.ready,
          position: Duration.zero,
          bufferedPosition: Duration.zero,
          duration: const Duration(minutes: 3),
          currentIndex: 0,
          queue: queue,
          queueGeneration: 1,
        ),
      );
      final AudioPlayerState current = previous.copyWith(
        playbackState: previous.playbackState!.copyWith(queueGeneration: 2),
      );
      queue.resetCounts();

      expect(
        QuranPlayerTransportControls.playerTreeBuildWhen(previous, current),
        isTrue,
      );
      expect(queue.indexAccessCount, 0);
    });
  });

  group('O(1) hot path: QuranPlayerQueueIndexCache', () {
    test('repeated indexByIdFor does not rescan queue', () {
      final CountingAudioEntityList queue = CountingAudioEntityList(
        _orderedLargeQueue(),
      );
      final QuranPlayerQueueIndexCache cache = QuranPlayerQueueIndexCache();

      cache.indexByIdFor(queue: queue, queueGeneration: 5);
      expect(queue.indexAccessCount, _largeQueueSize);
      queue.resetCounts();

      for (var i = 0; i < 500; i++) {
        final Map<String, int> map = cache.indexByIdFor(
          queue: queue,
          queueGeneration: 5,
        );
        expect(
          QuranPlayerQueueUtils.findReorderableChildIndex(
            indexById: map,
            key: ValueKey<String>('surah-${i % _largeQueueSize}'),
          ),
          isNotNull,
        );
      }

      expect(queue.indexAccessCount, 0);
    });
  });

  group('O(1) hot path: findReorderableChildIndex uses prebuilt map', () {
    test('map build is O(n) once; lookups are O(1) with zero queue access', () {
      final CountingAudioEntityList queue = CountingAudioEntityList(
        _orderedLargeQueue(),
      );
      final Map<String, int> indexById = QuranPlayerQueueUtils.queueIndexById(
        queue,
      );
      expect(queue.indexAccessCount, _largeQueueSize);
      queue.resetCounts();

      for (var i = 0; i < 1000; i++) {
        expect(
          QuranPlayerQueueUtils.findReorderableChildIndex(
            indexById: indexById,
            key: ValueKey<String>('surah-${i % _largeQueueSize}'),
          ),
          isNotNull,
        );
      }

      expect(queue.totalAccessCount, 0);
    });
  });

  group('O(1) hot path: MappedPlaybackQueueCache', () {
    test('cache hit invokes map zero times for large queue', () {
      final MappedPlaybackQueueCache cache = MappedPlaybackQueueCache();
      final List<audio_service.MediaItem> mediaQueue =
          _orderedLargeMediaQueue();
      var mapInvocations = 0;

      final List<AudioEntity> first = cache.entitiesFor(
        mediaQueue: mediaQueue,
        queueGeneration: 1,
        map: (audio_service.MediaItem item) {
          mapInvocations++;
          return _mapMediaItem(item);
        },
      );
      expect(mapInvocations, _largeQueueSize);

      cache.entitiesFor(
        mediaQueue: mediaQueue,
        queueGeneration: 1,
        map: (audio_service.MediaItem item) {
          mapInvocations++;
          return _mapMediaItem(item);
        },
      );

      expect(mapInvocations, _largeQueueSize);
      expect(
        identical(
          first,
          cache.entitiesFor(
            mediaQueue: mediaQueue,
            queueGeneration: 1,
            map: _mapMediaItem,
          ),
        ),
        isTrue,
      );
    });

    test('generation bump remaps exactly one additional time', () {
      final MappedPlaybackQueueCache cache = MappedPlaybackQueueCache();
      final List<audio_service.MediaItem> mediaQueue =
          _orderedLargeMediaQueue();
      var mapInvocations = 0;

      cache.entitiesFor(
        mediaQueue: mediaQueue,
        queueGeneration: 1,
        map: (audio_service.MediaItem item) {
          mapInvocations++;
          return _mapMediaItem(item);
        },
      );
      cache.entitiesFor(
        mediaQueue: mediaQueue,
        queueGeneration: 2,
        map: (audio_service.MediaItem item) {
          mapInvocations++;
          return _mapMediaItem(item);
        },
      );

      expect(mapInvocations, _largeQueueSize * 2);
    });
  });
}
