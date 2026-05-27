import 'package:audio_service/audio_service.dart';
import 'package:injectable/injectable.dart';

/// In-memory cache of artist [MediaItem] playlists for playback.
@lazySingleton
class ArtistMediaPlaylistCache {
  final Map<String, List<MediaItem>> _playlists = <String, List<MediaItem>>{};

  /// Cached playlist for [artistId], or null when not warmed.
  List<MediaItem>? playlistFor(String artistId) => _playlists[artistId];

  void store(String artistId, List<MediaItem> playlist) {
    _playlists[artistId] = playlist;
  }

  void clear() => _playlists.clear();
}
