import 'dart:convert';

import 'package:injectable/injectable.dart';
import 'package:muzakri/features/playlists/domain/entities/playlist.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class PlaylistsLocalDataSource {
  Future<List<Playlist>> getAllPlaylists();
  Future<Playlist?> getPlaylistById(String id);
  Future<void> savePlaylist(Playlist playlist);
  Future<void> deletePlaylist(String id);
  Future<void> saveAllPlaylists(List<Playlist> playlists);
  Future<void> clearAllPlaylists();
  Future<bool> doesPlaylistNameExist(String name, {String? excludeId});
  Future<int> getPlaylistsCount();
  Future<int> getTotalItemsCount();
  Future<String> generatePlaylistId();
}

@LazySingleton(as: PlaylistsLocalDataSource)
class PlaylistsLocalDataSourceImpl implements PlaylistsLocalDataSource {
  static const String _playlistsKey = 'playlists';
  static const String _playlistCounterKey = 'playlist_counter';

  final SharedPreferencesAsync _prefs;

  PlaylistsLocalDataSourceImpl(this._prefs);

  @override
  Future<List<Playlist>> getAllPlaylists() async {
    final playlistsJson = await _prefs.getStringList(_playlistsKey) ?? [];

    return playlistsJson.map((json) {
      final map = jsonDecode(json) as Map<String, dynamic>;
      return Playlist.fromJson(map);
    }).toList();
  }

  @override
  Future<Playlist?> getPlaylistById(String id) async {
    final playlists = await getAllPlaylists();
    try {
      return playlists.firstWhere((playlist) => playlist.id == id);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> savePlaylist(Playlist playlist) async {
    final playlists = await getAllPlaylists();

    // Check if playlist exists
    final existingIndex = playlists.indexWhere((p) => p.id == playlist.id);

    if (existingIndex != -1) {
      // Update existing playlist
      playlists[existingIndex] = playlist;
    } else {
      // Add new playlist
      playlists.add(playlist);
    }

    await saveAllPlaylists(playlists);
  }

  @override
  Future<void> deletePlaylist(String id) async {
    final playlists = await getAllPlaylists();
    playlists.removeWhere((playlist) => playlist.id == id);
    await saveAllPlaylists(playlists);
  }

  @override
  Future<void> saveAllPlaylists(List<Playlist> playlists) async {
    final playlistsJson = playlists
        .map((playlist) => jsonEncode(playlist.toJson()))
        .toList();
    await _prefs.setStringList(_playlistsKey, playlistsJson);
  }

  @override
  Future<void> clearAllPlaylists() async {
    await _prefs.remove(_playlistsKey);
    await _prefs.remove(_playlistCounterKey);
  }

  @override
  Future<bool> doesPlaylistNameExist(String name, {String? excludeId}) async {
    final playlists = await getAllPlaylists();
    return playlists.any(
      (playlist) =>
          playlist.name.toLowerCase() == name.toLowerCase() &&
          playlist.id != excludeId,
    );
  }

  @override
  Future<int> getPlaylistsCount() async {
    final playlists = await getAllPlaylists();
    return playlists.length;
  }

  @override
  Future<int> getTotalItemsCount() async {
    final playlists = await getAllPlaylists();
    return playlists.fold<int>(
      0,
      (total, playlist) => total + playlist.itemCount,
    );
  }

  /// Generate a unique playlist ID
  @override
  Future<String> generatePlaylistId() async {
    final counter = await _prefs.getInt(_playlistCounterKey) ?? 0;
    final newCounter = counter + 1;
    await _prefs.setInt(_playlistCounterKey, newCounter);
    return 'playlist_$newCounter';
  }
}
