import 'package:tilawa_core/entities/audio.dart';
import 'package:tilawa_core/entities/reciter_entity.dart';

/// Flat reciter audio list plus indexes for O(1) lookups after one build pass.
class ReciterAudioCatalog {
  const ReciterAudioCatalog({
    required this.reciters,
    required this.tracks,
    required this.byArtist,
    required this.byReciterName,
  });

  /// Source reciter entities (same order as the repository response).
  final List<ReciterEntity> reciters;

  /// All surah tracks across reciters (same order as legacy flat list).
  final List<AudioEntity> tracks;

  /// Tracks grouped by [AudioEntity.artist] (reciter display name).
  final Map<String, List<AudioEntity>> byArtist;

  /// Reciters keyed by trimmed, lowercased [ReciterEntity.name].
  final Map<String, ReciterEntity> byReciterName;

  /// O(1) playlist for [artistName] after the catalog is built.
  List<AudioEntity> tracksForArtist(String artistName) {
    final List<AudioEntity>? playlist = byArtist[artistName];
    if (playlist == null) {
      return const <AudioEntity>[];
    }
    return playlist;
  }

  /// O(1) reciter lookup by display name (case-insensitive).
  ReciterEntity? reciterNamed(String name) {
    final String key = name.trim().toLowerCase();
    if (key.isEmpty) {
      return null;
    }
    return byReciterName[key];
  }
}
