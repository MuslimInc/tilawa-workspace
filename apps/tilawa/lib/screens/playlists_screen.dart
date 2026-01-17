import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/core/utils/toast_utils.dart';

import '../features/playlists/domain/entities/playlist.dart';
import '../features/playlists/presentation/bloc/playlists_bloc.dart';
import '../features/playlists/presentation/widgets/create_playlist_dialog.dart';
import '../features/playlists/presentation/widgets/playlist_card.dart';
import '../features/playlists/presentation/widgets/playlist_search_bar.dart';
import '../l10n/generated/app_localizations.dart';

class PlaylistsScreen extends StatefulWidget {
  const PlaylistsScreen({super.key});

  @override
  State<PlaylistsScreen> createState() => _PlaylistsScreenState();
}

class _PlaylistsScreenState extends State<PlaylistsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<PlaylistsBloc>().add(const LoadPlaylistsEvent());
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.playlists),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<PlaylistsBloc>().add(const RefreshPlaylistsEvent());
            },
          ),
        ],
      ),
      body: BlocConsumer<PlaylistsBloc, PlaylistsState>(
        listener: (context, state) {
          state.whenOrNull(
            playlistUpdated: (playlist, playlists) {
              ToastUtils.showSuccessToast(l10n.playlistUpdated);
            },
            playlistDeleted: (playlistId, playlists) {
              ToastUtils.showSuccessToast(l10n.playlistDeleted);
            },
            favoriteToggled: (playlist, playlists) {
              ToastUtils.showToast(
                msg: playlist.isFavorite
                    ? l10n.addedToFavorites
                    : l10n.removedFromFavorites,
                backgroundColor: Colors.blue,
              );
            },
            error: (message) {
              ToastUtils.showErrorToast(message);
            },
          );
        },
        builder: (context, state) {
          return state.when(
            initial: () => const Center(child: CircularProgressIndicator()),
            loading: () => const Center(child: CircularProgressIndicator()),
            loaded: (playlists, searchQuery, filteredPlaylists) => Column(
              children: [
                PlaylistSearchBar(
                  onSearchChanged: (query) {
                    context.read<PlaylistsBloc>().add(
                      SearchPlaylistsEvent(query),
                    );
                  },
                  onClearSearch: () {
                    context.read<PlaylistsBloc>().add(const ClearSearchEvent());
                  },
                ),
                Expanded(
                  child: filteredPlaylists.isEmpty
                      ? _buildEmptyState(context, l10n)
                      : ListView.builder(
                          itemCount: filteredPlaylists.length,
                          itemBuilder: (context, index) {
                            final Playlist playlist = filteredPlaylists[index];
                            return PlaylistCard(
                              playlist: playlist,
                              onTap: () =>
                                  _navigateToPlaylistDetails(context, playlist),
                              onEdit: () =>
                                  _showEditPlaylistDialog(context, playlist),
                              onDelete: () =>
                                  _showDeletePlaylistDialog(context, playlist),
                              onToggleFavorite: () {
                                context.read<PlaylistsBloc>().add(
                                  ToggleFavoriteEvent(playlist.id),
                                );
                              },
                              onPlay: () => _playPlaylist(context, playlist),
                            );
                          },
                        ),
                ),
              ],
            ),
            error: (message) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    message,
                    style: Theme.of(context).textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.read<PlaylistsBloc>().add(
                        const LoadPlaylistsEvent(),
                      );
                    },
                    child: Text(l10n.retry),
                  ),
                ],
              ),
            ),
            playlistCreated: (playlist, playlists) =>
                _buildPlaylistsList(context, l10n, playlists),
            playlistUpdated: (playlist, playlists) =>
                _buildPlaylistsList(context, l10n, playlists),
            playlistDeleted: (playlistId, playlists) =>
                _buildPlaylistsList(context, l10n, playlists),
            itemAdded: (playlist, playlists) =>
                _buildPlaylistsList(context, l10n, playlists),
            itemRemoved: (playlist, playlists) =>
                _buildPlaylistsList(context, l10n, playlists),
            itemsReordered: (playlist, playlists) =>
                _buildPlaylistsList(context, l10n, playlists),
            playlistDuplicated: (playlist, playlists) =>
                _buildPlaylistsList(context, l10n, playlists),
            favoriteToggled: (playlist, playlists) =>
                _buildPlaylistsList(context, l10n, playlists),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'playlists_fab',
        onPressed: () => _showCreatePlaylistDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.playlist_add,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            l10n.noPlaylistsYet,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            l10n.createFirstPlaylistMessage,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showCreatePlaylistDialog(context),
            icon: const Icon(Icons.add),
            label: Text(l10n.createPlaylist),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaylistsList(
    BuildContext context,
    AppLocalizations l10n,
    List<dynamic> playlists,
  ) {
    return Column(
      children: [
        PlaylistSearchBar(
          onSearchChanged: (query) {
            context.read<PlaylistsBloc>().add(SearchPlaylistsEvent(query));
          },
          onClearSearch: () {
            context.read<PlaylistsBloc>().add(const ClearSearchEvent());
          },
        ),
        Expanded(
          child: playlists.isEmpty
              ? _buildEmptyState(context, l10n)
              : ListView.builder(
                  itemCount: playlists.length,
                  itemBuilder: (context, index) {
                    final Playlist playlist = playlists[index];
                    return PlaylistCard(
                      playlist: playlist,
                      onTap: () =>
                          _navigateToPlaylistDetails(context, playlist),
                      onEdit: () => _showEditPlaylistDialog(context, playlist),
                      onDelete: () =>
                          _showDeletePlaylistDialog(context, playlist),
                      onToggleFavorite: () {
                        context.read<PlaylistsBloc>().add(
                          ToggleFavoriteEvent(playlist.id),
                        );
                      },
                      onPlay: () => _playPlaylist(context, playlist),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _showCreatePlaylistDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const CreatePlaylistDialog(),
    );
  }

  void _showEditPlaylistDialog(BuildContext context, Playlist playlist) {
    // TODO(username): Implement edit playlist dialog
    final AppLocalizations l10n = context.l10n;
    ToastUtils.showToast(msg: l10n.editPlaylistComingSoon);
  }

  void _showDeletePlaylistDialog(BuildContext context, dynamic playlist) {
    final AppLocalizations l10n = context.l10n;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deletePlaylist),
        content: Text(l10n.deletePlaylistMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.read<PlaylistsBloc>().add(
                DeletePlaylistEvent((playlist as Playlist).id),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
  }

  void _navigateToPlaylistDetails(BuildContext context, Playlist playlist) {
    // TODO(username): Implement playlist details screen
    final AppLocalizations l10n = context.l10n;
    ToastUtils.showToast(msg: l10n.playlistDetailsComingSoon);
  }

  void _playPlaylist(BuildContext context, Playlist playlist) {
    // TODO(username): Implement play playlist functionality
    final AppLocalizations l10n = context.l10n;
    ToastUtils.showToast(msg: l10n.playPlaylistComingSoon);
  }
}
