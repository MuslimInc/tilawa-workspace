part of 'playlists_bloc.dart';

@freezed
sealed class PlaylistsEvent with _$PlaylistsEvent {
  const factory PlaylistsEvent.loadPlaylists() = LoadPlaylistsEvent;

  const factory PlaylistsEvent.createPlaylist({
    required String name,
    required String description,
    String? coverImageUrl,
    @Default(false) bool isPublic,
  }) = CreatePlaylistEvent;

  const factory PlaylistsEvent.updatePlaylist({
    required String id,
    required String name,
    required String description,
    String? coverImageUrl,
    @Default(false) bool isPublic,
  }) = UpdatePlaylistEvent;

  const factory PlaylistsEvent.deletePlaylist(String id) = DeletePlaylistEvent;

  const factory PlaylistsEvent.addItemToPlaylist({
    required String playlistId,
    required PlaylistItem item,
  }) = AddItemToPlaylistEvent;

  const factory PlaylistsEvent.removeItemFromPlaylist({
    required String playlistId,
    required String itemId,
  }) = RemoveItemFromPlaylistEvent;

  const factory PlaylistsEvent.reorderPlaylistItems({
    required String playlistId,
    required int oldIndex,
    required int newIndex,
  }) = ReorderPlaylistItemsEvent;

  const factory PlaylistsEvent.searchPlaylists(String query) =
      SearchPlaylistsEvent;

  const factory PlaylistsEvent.toggleFavorite(String playlistId) =
      ToggleFavoriteEvent;

  const factory PlaylistsEvent.duplicatePlaylist({
    required String playlistId,
    required String newName,
  }) = DuplicatePlaylistEvent;

  const factory PlaylistsEvent.clearSearch() = ClearSearchEvent;

  const factory PlaylistsEvent.refreshPlaylists() = RefreshPlaylistsEvent;
}
