import 'package:flutter/widgets.dart';
import 'package:tilawa_core/entities/audio.dart';
import 'package:tilawa_core/entities/audio_extras_keys.dart';

import '../../features/audio_player/presentation/bloc/audio_player_bloc.dart';

/// Keeps the expanded player queue list aligned with [AudioPlayerBloc] state.
abstract final class QuranPlayerQueueUtils {
  /// Whether queue length, item order, or active index changed between snapshots.
  ///
  /// When [previousQueueGeneration] and [currentQueueGeneration] are provided,
  /// unchanged generation and [currentIndex] imply no queue UI update (O(1)).
  static bool queueSnapshotChanged({
    required List<AudioEntity>? previousQueue,
    required List<AudioEntity>? currentQueue,
    required int? previousIndex,
    required int? currentIndex,
    int? previousQueueGeneration,
    int? currentQueueGeneration,
  }) {
    if (previousQueueGeneration != null && currentQueueGeneration != null) {
      if (previousQueueGeneration != currentQueueGeneration) {
        return true;
      }
      return previousIndex != currentIndex;
    }

    final List<AudioEntity> previous = previousQueue ?? const <AudioEntity>[];
    final List<AudioEntity> current = currentQueue ?? const <AudioEntity>[];
    if (identical(previous, current)) {
      return previousIndex != currentIndex;
    }
    if (previous.length != current.length) {
      return true;
    }
    if (previousIndex != currentIndex) {
      return true;
    }
    for (var i = 0; i < previous.length; i++) {
      if (previous[i].id != current[i].id) {
        return true;
      }
    }
    return false;
  }

  /// Whether the expanded player tree must refresh its queue list UI.
  static bool playerTreeQueueChanged(
    AudioPlayerState previous,
    AudioPlayerState current,
  ) => queueSnapshotChanged(
    previousQueue: previous.playbackState?.queue,
    currentQueue: current.playbackState?.queue,
    previousIndex: previous.playbackState?.currentIndex,
    currentIndex: current.playbackState?.currentIndex,
    previousQueueGeneration: previous.playbackState?.queueGeneration,
    currentQueueGeneration: current.playbackState?.queueGeneration,
  );

  /// Builds a stable id → index map for [SliverReorderableList] (O(n) once).
  static Map<String, int> queueIndexById(List<AudioEntity> queue) {
    return <String, int>{
      for (var i = 0; i < queue.length; i++) queue[i].id: i,
    };
  }

  /// O(1) lookup when [indexById] comes from [queueIndexById].
  static int? findReorderableChildIndex({
    required Map<String, int> indexById,
    required Key key,
  }) {
    if (key is ValueKey<String>) {
      return indexById[key.value];
    }
    return null;
  }
}

/// O(1) reuse of [QuranPlayerQueueUtils.queueIndexById] across rebuilds.
final class QuranPlayerQueueIndexCache {
  int _cachedGeneration = -1;
  List<AudioEntity>? _cachedQueue;
  Map<String, int>? _cachedIndexById;

  /// Returns a cached map when [queueGeneration] and [queue] are unchanged.
  Map<String, int> indexByIdFor({
    required List<AudioEntity> queue,
    required int queueGeneration,
  }) {
    if (_cachedGeneration == queueGeneration &&
        identical(_cachedQueue, queue) &&
        _cachedIndexById != null) {
      return _cachedIndexById!;
    }
    _cachedGeneration = queueGeneration;
    _cachedQueue = queue;
    _cachedIndexById = QuranPlayerQueueUtils.queueIndexById(queue);
    return _cachedIndexById!;
  }

  int _cachedSurahGeneration = -1;
  List<AudioEntity>? _cachedSurahQueue;
  Map<String, int>? _cachedIndexBySurahId;

  /// O(1) surah id → queue index; rebuilt only when [queueGeneration] changes.
  Map<String, int> indexBySurahIdFor({
    required List<AudioEntity> queue,
    required int queueGeneration,
  }) {
    if (_cachedSurahGeneration == queueGeneration &&
        identical(_cachedSurahQueue, queue) &&
        _cachedIndexBySurahId != null) {
      return _cachedIndexBySurahId!;
    }
    final Map<String, int> map = <String, int>{};
    for (var i = 0; i < queue.length; i++) {
      final Object? surahId = queue[i].extras?[AudioExtrasKeys.surahId];
      if (surahId == null) {
        continue;
      }
      map.putIfAbsent(surahId.toString(), () => i);
    }
    _cachedSurahGeneration = queueGeneration;
    _cachedSurahQueue = queue;
    _cachedIndexBySurahId = map;
    return map;
  }

  void clear() {
    _cachedGeneration = -1;
    _cachedQueue = null;
    _cachedIndexById = null;
    _cachedSurahGeneration = -1;
    _cachedSurahQueue = null;
    _cachedIndexBySurahId = null;
  }
}
