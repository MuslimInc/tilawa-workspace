import 'package:muzakri/features/playlists/domain/entities/playlist.dart';

abstract class PlaylistsRepository {
  /// Get all playlists
  Future<List<Playlist>> getAllPlaylists();

  /// Get a specific playlist by ID
  Future<Playlist?> getPlaylistById(String id);

  /// Create a new playlist
  Future<Playlist> createPlaylist({
    required String name,
    required String description,
    String? coverImageUrl,
    bool isPublic = false,
  });

  /// Update an existing playlist
  Future<Playlist> updatePlaylist(Playlist playlist);

  /// Delete a playlist
  Future<void> deletePlaylist(String id);

  /// Add item to playlist
  Future<Playlist> addItemToPlaylist(String playlistId, PlaylistItem item);

  /// Remove item from playlist
  Future<Playlist> removeItemFromPlaylist(String playlistId, String itemId);

  /// Reorder items in playlist
  Future<Playlist> reorderPlaylistItems(
    String playlistId,
    int oldIndex,
    int newIndex,
  );

  /// Update playlist item
  Future<Playlist> updatePlaylistItem(
    String playlistId,
    String itemId,
    PlaylistItem updatedItem,
  );

  /// Search playlists by name
  Future<List<Playlist>> searchPlaylists(String query);

  /// Get favorite playlists
  Future<List<Playlist>> getFavoritePlaylists();

  /// Toggle favorite status
  Future<Playlist> toggleFavorite(String playlistId);

  /// Get playlists by visibility
  Future<List<Playlist>> getPlaylistsByVisibility(bool isPublic);

  /// Get recent playlists (last 10)
  Future<List<Playlist>> getRecentPlaylists();

  /// Clear all playlists
  Future<void> clearAllPlaylists();

  /// Duplicate a playlist
  Future<Playlist> duplicatePlaylist(String playlistId, String newName);

  /// Export playlist to file
  Future<String> exportPlaylist(String playlistId);

  /// Import playlist from file
  Future<Playlist> importPlaylist(String filePath);

  /// Get playlist statistics
  Future<Map<String, dynamic>> getPlaylistStats(String playlistId);

  /// Check if playlist name exists
  Future<bool> doesPlaylistNameExist(String name, {String? excludeId});

  /// Get playlists count
  Future<int> getPlaylistsCount();

  /// Get total items count across all playlists
  Future<int> getTotalItemsCount();
}
