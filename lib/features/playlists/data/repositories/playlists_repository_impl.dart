import 'dart:convert';

import 'package:injectable/injectable.dart';
import 'package:muzakri/features/playlists/data/datasources/playlists_local_datasource.dart';
import 'package:muzakri/features/playlists/domain/entities/playlist.dart';
import 'package:muzakri/features/playlists/domain/repositories/playlists_repository.dart';

@LazySingleton(as: PlaylistsRepository)
class PlaylistsRepositoryImpl implements PlaylistsRepository {
  final PlaylistsLocalDataSource _localDataSource;

  PlaylistsRepositoryImpl(this._localDataSource);

  @override
  Future<List<Playlist>> getAllPlaylists() async {
    return await _localDataSource.getAllPlaylists();
  }

  @override
  Future<Playlist?> getPlaylistById(String id) async {
    return await _localDataSource.getPlaylistById(id);
  }

  @override
  Future<Playlist> createPlaylist({
    required String name,
    required String description,
    String? coverImageUrl,
    bool isPublic = false,
  }) async {
    // Check if name already exists
    final nameExists = await _localDataSource.doesPlaylistNameExist(name);
    if (nameExists) {
      throw Exception('Playlist name already exists');
    }

    // Generate unique ID
    final id = await _localDataSource.generatePlaylistId();

    final playlist = Playlist(
      id: id,
      name: name,
      description: description,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      items: [],
      coverImageUrl: coverImageUrl,
      isPublic: isPublic,
    );

    await _localDataSource.savePlaylist(playlist);
    return playlist;
  }

  @override
  Future<Playlist> updatePlaylist(Playlist playlist) async {
    // Check if playlist exists
    final existingPlaylist = await _localDataSource.getPlaylistById(
      playlist.id,
    );
    if (existingPlaylist == null) {
      throw Exception('Playlist not found');
    }

    // Check if name already exists (excluding current playlist)
    final nameExists = await _localDataSource.doesPlaylistNameExist(
      playlist.name,
      excludeId: playlist.id,
    );
    if (nameExists) {
      throw Exception('Playlist name already exists');
    }

    final updatedPlaylist = playlist.copyWith(updatedAt: DateTime.now());
    await _localDataSource.savePlaylist(updatedPlaylist);
    return updatedPlaylist;
  }

  @override
  Future<void> deletePlaylist(String id) async {
    final playlist = await _localDataSource.getPlaylistById(id);
    if (playlist == null) {
      throw Exception('Playlist not found');
    }

    await _localDataSource.deletePlaylist(id);
  }

  @override
  Future<Playlist> addItemToPlaylist(
    String playlistId,
    PlaylistItem item,
  ) async {
    final playlist = await _localDataSource.getPlaylistById(playlistId);
    if (playlist == null) {
      throw Exception('Playlist not found');
    }

    // Check if item already exists in playlist
    final itemExists = playlist.items.any(
      (existingItem) => existingItem.id == item.id,
    );
    if (itemExists) {
      throw Exception('Item already exists in playlist');
    }

    final updatedItems = List<PlaylistItem>.from(playlist.items)..add(item);
    final updatedPlaylist = playlist.copyWith(
      items: updatedItems,
      updatedAt: DateTime.now(),
    );

    await _localDataSource.savePlaylist(updatedPlaylist);
    return updatedPlaylist;
  }

  @override
  Future<Playlist> removeItemFromPlaylist(
    String playlistId,
    String itemId,
  ) async {
    final playlist = await _localDataSource.getPlaylistById(playlistId);
    if (playlist == null) {
      throw Exception('Playlist not found');
    }

    final updatedItems = playlist.items
        .where((item) => item.id != itemId)
        .toList();
    final updatedPlaylist = playlist.copyWith(
      items: updatedItems,
      updatedAt: DateTime.now(),
    );

    await _localDataSource.savePlaylist(updatedPlaylist);
    return updatedPlaylist;
  }

  @override
  Future<Playlist> reorderPlaylistItems(
    String playlistId,
    int oldIndex,
    int newIndex,
  ) async {
    final playlist = await _localDataSource.getPlaylistById(playlistId);
    if (playlist == null) {
      throw Exception('Playlist not found');
    }

    if (oldIndex < 0 ||
        oldIndex >= playlist.items.length ||
        newIndex < 0 ||
        newIndex >= playlist.items.length) {
      throw Exception('Invalid index');
    }

    final updatedItems = List<PlaylistItem>.from(playlist.items);
    final item = updatedItems.removeAt(oldIndex);
    updatedItems.insert(newIndex, item);

    final updatedPlaylist = playlist.copyWith(
      items: updatedItems,
      updatedAt: DateTime.now(),
    );

    await _localDataSource.savePlaylist(updatedPlaylist);
    return updatedPlaylist;
  }

  @override
  Future<Playlist> updatePlaylistItem(
    String playlistId,
    String itemId,
    PlaylistItem updatedItem,
  ) async {
    final playlist = await _localDataSource.getPlaylistById(playlistId);
    if (playlist == null) {
      throw Exception('Playlist not found');
    }

    final itemIndex = playlist.items.indexWhere((item) => item.id == itemId);
    if (itemIndex == -1) {
      throw Exception('Item not found in playlist');
    }

    final updatedItems = List<PlaylistItem>.from(playlist.items);
    updatedItems[itemIndex] = updatedItem;

    final updatedPlaylist = playlist.copyWith(
      items: updatedItems,
      updatedAt: DateTime.now(),
    );

    await _localDataSource.savePlaylist(updatedPlaylist);
    return updatedPlaylist;
  }

  @override
  Future<List<Playlist>> searchPlaylists(String query) async {
    final playlists = await _localDataSource.getAllPlaylists();
    if (query.isEmpty) return playlists;

    final lowercaseQuery = query.toLowerCase();
    return playlists
        .where(
          (playlist) =>
              playlist.name.toLowerCase().contains(lowercaseQuery) ||
              playlist.description.toLowerCase().contains(lowercaseQuery),
        )
        .toList();
  }

  @override
  Future<List<Playlist>> getFavoritePlaylists() async {
    final playlists = await _localDataSource.getAllPlaylists();
    return playlists.where((playlist) => playlist.isFavorite).toList();
  }

  @override
  Future<Playlist> toggleFavorite(String playlistId) async {
    final playlist = await _localDataSource.getPlaylistById(playlistId);
    if (playlist == null) {
      throw Exception('Playlist not found');
    }

    final updatedPlaylist = playlist.copyWith(
      isFavorite: !playlist.isFavorite,
      updatedAt: DateTime.now(),
    );

    await _localDataSource.savePlaylist(updatedPlaylist);
    return updatedPlaylist;
  }

  @override
  Future<List<Playlist>> getPlaylistsByVisibility(bool isPublic) async {
    final playlists = await _localDataSource.getAllPlaylists();
    return playlists
        .where((playlist) => playlist.isPublic == isPublic)
        .toList();
  }

  @override
  Future<List<Playlist>> getRecentPlaylists() async {
    final playlists = await _localDataSource.getAllPlaylists();
    playlists.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return playlists.take(10).toList();
  }

  @override
  Future<void> clearAllPlaylists() async {
    await _localDataSource.clearAllPlaylists();
  }

  @override
  Future<Playlist> duplicatePlaylist(String playlistId, String newName) async {
    final originalPlaylist = await _localDataSource.getPlaylistById(playlistId);
    if (originalPlaylist == null) {
      throw Exception('Playlist not found');
    }

    // Check if new name already exists
    final nameExists = await _localDataSource.doesPlaylistNameExist(newName);
    if (nameExists) {
      throw Exception('Playlist name already exists');
    }

    final id = await _localDataSource.generatePlaylistId();
    final duplicatedPlaylist = originalPlaylist.copyWith(
      id: id,
      name: newName,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isFavorite: false, // Reset favorite status
    );

    await _localDataSource.savePlaylist(duplicatedPlaylist);
    return duplicatedPlaylist;
  }

  @override
  Future<String> exportPlaylist(String playlistId) async {
    final playlist = await _localDataSource.getPlaylistById(playlistId);
    if (playlist == null) {
      throw Exception('Playlist not found');
    }

    // For now, return JSON string. In a real app, you might want to save to file
    return jsonEncode(playlist.toJson());
  }

  @override
  Future<Playlist> importPlaylist(String filePath) async {
    // For now, this is a placeholder. In a real app, you would read from file
    throw UnimplementedError('Import playlist from file not implemented yet');
  }

  @override
  Future<Map<String, dynamic>> getPlaylistStats(String playlistId) async {
    final playlist = await _localDataSource.getPlaylistById(playlistId);
    if (playlist == null) {
      throw Exception('Playlist not found');
    }

    return {
      'itemCount': playlist.itemCount,
      'totalDuration': playlist.totalDuration.inSeconds,
      'isPublic': playlist.isPublic,
      'isFavorite': playlist.isFavorite,
      'createdAt': playlist.createdAt.toIso8601String(),
      'updatedAt': playlist.updatedAt.toIso8601String(),
    };
  }

  @override
  Future<bool> doesPlaylistNameExist(String name, {String? excludeId}) async {
    return await _localDataSource.doesPlaylistNameExist(
      name,
      excludeId: excludeId,
    );
  }

  @override
  Future<int> getPlaylistsCount() async {
    return await _localDataSource.getPlaylistsCount();
  }

  @override
  Future<int> getTotalItemsCount() async {
    return await _localDataSource.getTotalItemsCount();
  }
}
