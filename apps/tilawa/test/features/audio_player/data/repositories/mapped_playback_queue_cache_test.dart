import 'package:audio_service/audio_service.dart' as audio_service;
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/audio_player/data/repositories/mapped_playback_queue_cache.dart';
import 'package:tilawa_core/entities/audio.dart';

void main() {
  group('MappedPlaybackQueueCache', () {
    test(
      'reuses mapped list when media queue and generation are unchanged',
      () {
        final MappedPlaybackQueueCache cache = MappedPlaybackQueueCache();
        final List<audio_service.MediaItem> mediaQueue =
            <audio_service.MediaItem>[
              const audio_service.MediaItem(
                id: '1',
                title: 'Al-Fatiha',
                extras: <String, dynamic>{'url': 'https://example.com/1.mp3'},
              ),
            ];

        final List<AudioEntity> first = cache.entitiesFor(
          mediaQueue: mediaQueue,
          queueGeneration: 1,
          map: (audio_service.MediaItem item) => AudioEntity(
            id: item.id,
            title: item.title,
            url: item.extras?['url'] as String? ?? item.id,
            duration: item.duration ?? Duration.zero,
          ),
        );
        final List<AudioEntity> second = cache.entitiesFor(
          mediaQueue: mediaQueue,
          queueGeneration: 1,
          map: (audio_service.MediaItem item) => AudioEntity(
            id: item.id,
            title: item.title,
            url: 'should-not-remap',
            duration: item.duration ?? Duration.zero,
          ),
        );

        expect(identical(first, second), isTrue);
        expect(first.first.url, 'https://example.com/1.mp3');
      },
    );

    test('remaps when queue generation changes', () {
      final MappedPlaybackQueueCache cache = MappedPlaybackQueueCache();
      final List<audio_service.MediaItem> mediaQueue =
          <audio_service.MediaItem>[
            const audio_service.MediaItem(
              id: '1',
              title: 'Al-Fatiha',
              extras: <String, dynamic>{'url': 'https://example.com/1.mp3'},
            ),
          ];

      final List<AudioEntity> first = cache.entitiesFor(
        mediaQueue: mediaQueue,
        queueGeneration: 1,
        map: (audio_service.MediaItem item) => AudioEntity(
          id: item.id,
          title: item.title,
          url: item.extras?['url'] as String? ?? item.id,
          duration: Duration.zero,
        ),
      );
      final List<AudioEntity> second = cache.entitiesFor(
        mediaQueue: mediaQueue,
        queueGeneration: 2,
        map: (audio_service.MediaItem item) => AudioEntity(
          id: item.id,
          title: item.title,
          url: 'https://example.com/updated.mp3',
          duration: Duration.zero,
        ),
      );

      expect(identical(first, second), isFalse);
      expect(second.first.url, 'https://example.com/updated.mp3');
    });
  });
}
