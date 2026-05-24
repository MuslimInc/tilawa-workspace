import 'package:tilawa_core/entities/audio.dart';

/// Flat reciter audio list plus an artist-name index for O(1) playlist lookup.
class ReciterAudioCatalog {
  const ReciterAudioCatalog({
    required this.tracks,
    required this.byArtist,
  });

  /// All surah tracks across reciters (same order as legacy flat list).
  final List<AudioEntity> tracks;

  /// Tracks grouped by [AudioEntity.artist] (reciter display name).
  final Map<String, List<AudioEntity>> byArtist;

  /// O(1) playlist for [artistName] after the catalog is built.
  List<AudioEntity> tracksForArtist(String artistName) {
    final List<AudioEntity>? playlist = byArtist[artistName];
    if (playlist == null) {
      return const <AudioEntity>[];
    }
    return playlist;
  }
}
