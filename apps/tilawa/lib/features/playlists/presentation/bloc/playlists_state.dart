part of 'playlists_bloc.dart';

@freezed
sealed class PlaylistsState with _$PlaylistsState {
  const factory PlaylistsState.initial() = PlaylistsInitial;

  const factory PlaylistsState.loading() = PlaylistsLoading;

  const factory PlaylistsState.loaded({
    required List<Playlist> playlists,
    @Default('') String searchQuery,
    @Default([]) List<Playlist> filteredPlaylists,
  }) = PlaylistsLoaded;

  const factory PlaylistsState.error(String message) = PlaylistsError;

  const factory PlaylistsState.playlistCreated({
    required Playlist playlist,
    required List<Playlist> playlists,
  }) = PlaylistCreated;

  const factory PlaylistsState.playlistUpdated({
    required Playlist playlist,
    required List<Playlist> playlists,
  }) = PlaylistUpdated;

  const factory PlaylistsState.playlistDeleted({
    required String playlistId,
    required List<Playlist> playlists,
  }) = PlaylistDeleted;

  const factory PlaylistsState.itemAdded({
    required Playlist playlist,
    required List<Playlist> playlists,
  }) = ItemAdded;

  const factory PlaylistsState.itemRemoved({
    required Playlist playlist,
    required List<Playlist> playlists,
  }) = ItemRemoved;

  const factory PlaylistsState.itemsReordered({
    required Playlist playlist,
    required List<Playlist> playlists,
  }) = ItemsReordered;

  const factory PlaylistsState.playlistDuplicated({
    required Playlist playlist,
    required List<Playlist> playlists,
  }) = PlaylistDuplicated;

  const factory PlaylistsState.favoriteToggled({
    required Playlist playlist,
    required List<Playlist> playlists,
  }) = FavoriteToggled;
}
