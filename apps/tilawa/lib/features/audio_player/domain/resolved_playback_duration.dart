import 'package:tilawa_core/entities/audio.dart';

/// Result of [resolvePlaybackDisplayDurationDetailed].
class ResolvedPlaybackDuration {
  const ResolvedPlaybackDuration({
    required this.duration,
    required this.source,
  });

  final Duration duration;

  /// One of: playbackState, queueItem, metadata, cache, zero.
  final String source;
}

/// Picks the duration shown on the player progress bar for [audio].
Duration resolvePlaybackDisplayDuration({
  required AudioEntity audio,
  required PlaybackStateEntity? playbackState,
  required bool isCurrentPlayback,
  required Map<String, Duration> cachedDurations,
}) {
  return resolvePlaybackDisplayDurationDetailed(
    audio: audio,
    playbackState: playbackState,
    isCurrentPlayback: isCurrentPlayback,
    cachedDurations: cachedDurations,
  ).duration;
}

/// Same as [resolvePlaybackDisplayDuration] but exposes which source won.
ResolvedPlaybackDuration resolvePlaybackDisplayDurationDetailed({
  required AudioEntity audio,
  required PlaybackStateEntity? playbackState,
  required bool isCurrentPlayback,
  required Map<String, Duration> cachedDurations,
}) {
  if (isCurrentPlayback && playbackState != null) {
    final Duration playbackDuration = playbackState.duration;
    if (playbackDuration > Duration.zero) {
      return ResolvedPlaybackDuration(
        duration: playbackDuration,
        source: 'playbackState',
      );
    }
  }

  if (playbackState != null) {
    for (final AudioEntity queuedAudio in playbackState.queue) {
      if (queuedAudio.id == audio.id &&
          queuedAudio.duration > Duration.zero) {
        return ResolvedPlaybackDuration(
          duration: queuedAudio.duration,
          source: 'queueItem',
        );
      }
    }
  }

  if (audio.duration > Duration.zero) {
    return ResolvedPlaybackDuration(
      duration: audio.duration,
      source: 'metadata',
    );
  }

  final Duration cachedDuration =
      cachedDurations[audio.id] ?? Duration.zero;
  if (cachedDuration > Duration.zero) {
    return ResolvedPlaybackDuration(
      duration: cachedDuration,
      source: 'cache',
    );
  }

  return const ResolvedPlaybackDuration(
    duration: Duration.zero,
    source: 'zero',
  );
}
