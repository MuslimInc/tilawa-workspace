import 'package:audio_service/audio_service.dart' as audio_service;
import 'package:tilawa_core/entities/audio.dart';

/// Reuses mapped [AudioEntity] lists while the handler queue is unchanged.
final class MappedPlaybackQueueCache {
  List<audio_service.MediaItem>? _mediaQueue;
  int _queueGeneration = -1;
  List<AudioEntity>? _entities;

  List<AudioEntity> entitiesFor({
    required List<audio_service.MediaItem> mediaQueue,
    required int queueGeneration,
    required AudioEntity Function(audio_service.MediaItem item) map,
  }) {
    if (_mediaQueue == mediaQueue &&
        _queueGeneration == queueGeneration &&
        _entities != null) {
      return _entities!;
    }
    _mediaQueue = mediaQueue;
    _queueGeneration = queueGeneration;
    _entities = mediaQueue.map(map).toList(growable: false);
    return _entities!;
  }
}
