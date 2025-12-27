import 'package:collection/collection.dart';
import 'package:dartz_plus/dartz_plus.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/playlist.dart';
import '../../domain/usecases/usecases.dart';

part 'playlists_bloc.freezed.dart';
part 'playlists_event.dart';
part 'playlists_state.dart';

@injectable
class PlaylistsBloc extends HydratedBloc<PlaylistsEvent, PlaylistsState> {
  PlaylistsBloc({
    required GetAllPlaylistsUseCase getAllPlaylistsUseCase,
    required CreatePlaylistUseCase createPlaylistUseCase,
    required UpdatePlaylistUseCase updatePlaylistUseCase,
    required DeletePlaylistUseCase deletePlaylistUseCase,
    required AddItemToPlaylistUseCase addItemToPlaylistUseCase,
    required RemoveItemFromPlaylistUseCase removeItemFromPlaylistUseCase,
    required SearchPlaylistsUseCase searchPlaylistsUseCase,
    required ToggleFavoritePlaylistUseCase toggleFavoritePlaylistUseCase,
  }) : _getAllPlaylistsUseCase = getAllPlaylistsUseCase,
       _createPlaylistUseCase = createPlaylistUseCase,
       _updatePlaylistUseCase = updatePlaylistUseCase,
       _deletePlaylistUseCase = deletePlaylistUseCase,
       _addItemToPlaylistUseCase = addItemToPlaylistUseCase,
       _removeItemFromPlaylistUseCase = removeItemFromPlaylistUseCase,
       _searchPlaylistsUseCase = searchPlaylistsUseCase,
       _toggleFavoritePlaylistUseCase = toggleFavoritePlaylistUseCase,
       super(const PlaylistsState.initial()) {
    on<LoadPlaylistsEvent>(_onLoadPlaylists);
    on<CreatePlaylistEvent>(_onCreatePlaylist);
    on<UpdatePlaylistEvent>(_onUpdatePlaylist);
    on<DeletePlaylistEvent>(_onDeletePlaylist);
    on<AddItemToPlaylistEvent>(_onAddItemToPlaylist);
    on<RemoveItemFromPlaylistEvent>(_onRemoveItemFromPlaylist);
    on<ReorderPlaylistItemsEvent>(_onReorderPlaylistItems);
    on<SearchPlaylistsEvent>(_onSearchPlaylists);
    on<ToggleFavoriteEvent>(_onToggleFavorite);
    on<DuplicatePlaylistEvent>(_onDuplicatePlaylist);
    on<ClearSearchEvent>(_onClearSearch);
    on<RefreshPlaylistsEvent>(_onRefreshPlaylists);
  }
  final GetAllPlaylistsUseCase _getAllPlaylistsUseCase;
  final CreatePlaylistUseCase _createPlaylistUseCase;
  final UpdatePlaylistUseCase _updatePlaylistUseCase;
  final DeletePlaylistUseCase _deletePlaylistUseCase;
  final AddItemToPlaylistUseCase _addItemToPlaylistUseCase;
  final RemoveItemFromPlaylistUseCase _removeItemFromPlaylistUseCase;
  final SearchPlaylistsUseCase _searchPlaylistsUseCase;
  final ToggleFavoritePlaylistUseCase _toggleFavoritePlaylistUseCase;

  Future<void> _onLoadPlaylists(
    LoadPlaylistsEvent event,
    Emitter<PlaylistsState> emit,
  ) async {
    emit(const PlaylistsState.loading());

    final Either<Failure, List<Playlist>> result =
        await _getAllPlaylistsUseCase();
    result.fold(
      (failure) => emit(
        PlaylistsState.error(failure.message ?? 'Failed to load playlists'),
      ),
      (playlists) => emit(
        PlaylistsState.loaded(
          playlists: playlists,
          filteredPlaylists: playlists,
        ),
      ),
    );
  }

  Future<void> _onCreatePlaylist(
    CreatePlaylistEvent event,
    Emitter<PlaylistsState> emit,
  ) async {
    final Either<Failure, Playlist> result = await _createPlaylistUseCase(
      name: event.name,
      description: event.description,
      coverImageUrl: event.coverImageUrl,
      isPublic: event.isPublic,
    );

    await result.fold(
      (failure) async => emit(
        PlaylistsState.error(failure.message ?? 'Failed to create playlist'),
      ),
      (playlist) async {
        // Reload playlists to get updated list
        final Either<Failure, List<Playlist>> loadResult =
            await _getAllPlaylistsUseCase();
        await loadResult.fold(
          (failure) async => emit(
            PlaylistsState.error(failure.message ?? 'Failed to load playlists'),
          ),
          (playlists) async => emit(
            PlaylistsState.playlistCreated(
              playlist: playlist,
              playlists: playlists,
            ),
          ),
        );
      },
    );
  }

  Future<void> _onUpdatePlaylist(
    UpdatePlaylistEvent event,
    Emitter<PlaylistsState> emit,
  ) async {
    // Get current playlists to find the one to update
    final PlaylistsState currentState = state;
    if (currentState is! PlaylistsLoaded) {
      return;
    }

    final Playlist? playlistToUpdate = currentState.playlists.firstWhereOrNull(
      (p) => p.id == event.id,
    );

    if (playlistToUpdate == null) {
      emit(const PlaylistsState.error('Playlist not found'));
      return;
    }

    final Playlist updatedPlaylist = playlistToUpdate.copyWith(
      name: event.name,
      description: event.description,
      coverImageUrl: event.coverImageUrl,
      isPublic: event.isPublic,
    );

    final Either<Failure, Playlist> result = await _updatePlaylistUseCase(
      updatedPlaylist,
    );
    await result.fold(
      (failure) async => emit(
        PlaylistsState.error(failure.message ?? 'Failed to update playlist'),
      ),
      (playlist) async {
        // Reload playlists to get updated list
        final Either<Failure, List<Playlist>> loadResult =
            await _getAllPlaylistsUseCase();
        await loadResult.fold(
          (failure) async => emit(
            PlaylistsState.error(failure.message ?? 'Failed to load playlists'),
          ),
          (playlists) async => emit(
            PlaylistsState.playlistUpdated(
              playlist: playlist,
              playlists: playlists,
            ),
          ),
        );
      },
    );
  }

  Future<void> _onDeletePlaylist(
    DeletePlaylistEvent event,
    Emitter<PlaylistsState> emit,
  ) async {
    final Either<Failure, void> result = await _deletePlaylistUseCase(event.id);
    await result.fold(
      (failure) async => emit(
        PlaylistsState.error(failure.message ?? 'Failed to delete playlist'),
      ),
      (_) async {
        // Reload playlists to get updated list
        final Either<Failure, List<Playlist>> loadResult =
            await _getAllPlaylistsUseCase();
        await loadResult.fold(
          (failure) async => emit(
            PlaylistsState.error(failure.message ?? 'Failed to load playlists'),
          ),
          (playlists) async => emit(
            PlaylistsState.playlistDeleted(
              playlistId: event.id,
              playlists: playlists,
            ),
          ),
        );
      },
    );
  }

  Future<void> _onAddItemToPlaylist(
    AddItemToPlaylistEvent event,
    Emitter<PlaylistsState> emit,
  ) async {
    final Either<Failure, Playlist> result = await _addItemToPlaylistUseCase(
      playlistId: event.playlistId,
      item: event.item,
    );

    await result.fold(
      (failure) async => emit(
        PlaylistsState.error(
          failure.message ?? 'Failed to add item to playlist',
        ),
      ),
      (playlist) async {
        // Reload playlists to get updated list
        final Either<Failure, List<Playlist>> loadResult =
            await _getAllPlaylistsUseCase();
        await loadResult.fold(
          (failure) async => emit(
            PlaylistsState.error(failure.message ?? 'Failed to load playlists'),
          ),
          (playlists) async => emit(
            PlaylistsState.itemAdded(playlist: playlist, playlists: playlists),
          ),
        );
      },
    );
  }

  Future<void> _onRemoveItemFromPlaylist(
    RemoveItemFromPlaylistEvent event,
    Emitter<PlaylistsState> emit,
  ) async {
    final Either<Failure, Playlist> result =
        await _removeItemFromPlaylistUseCase(
          playlistId: event.playlistId,
          itemId: event.itemId,
        );

    await result.fold(
      (failure) async => emit(
        PlaylistsState.error(
          failure.message ?? 'Failed to remove item from playlist',
        ),
      ),
      (playlist) async {
        // Reload playlists to get updated list
        final Either<Failure, List<Playlist>> loadResult =
            await _getAllPlaylistsUseCase();
        await loadResult.fold(
          (failure) async => emit(
            PlaylistsState.error(failure.message ?? 'Failed to load playlists'),
          ),
          (playlists) async => emit(
            PlaylistsState.itemRemoved(
              playlist: playlist,
              playlists: playlists,
            ),
          ),
        );
      },
    );
  }

  Future<void> _onReorderPlaylistItems(
    ReorderPlaylistItemsEvent event,
    Emitter<PlaylistsState> emit,
  ) async {
    // This would require a new use case for reordering
    // For now, we'll emit an error
    emit(
      const PlaylistsState.error('Reorder functionality not implemented yet'),
    );
  }

  Future<void> _onSearchPlaylists(
    SearchPlaylistsEvent event,
    Emitter<PlaylistsState> emit,
  ) async {
    final PlaylistsState currentState = state;
    if (currentState is! PlaylistsLoaded) {
      return;
    }

    if (event.query.isEmpty) {
      emit(
        currentState.copyWith(
          searchQuery: '',
          filteredPlaylists: currentState.playlists,
        ),
      );
      return;
    }

    final Either<Failure, List<Playlist>> result =
        await _searchPlaylistsUseCase(event.query);
    result.fold(
      (failure) => emit(
        PlaylistsState.error(failure.message ?? 'Failed to search playlists'),
      ),
      (filteredPlaylists) => emit(
        currentState.copyWith(
          searchQuery: event.query,
          filteredPlaylists: filteredPlaylists,
        ),
      ),
    );
  }

  Future<void> _onToggleFavorite(
    ToggleFavoriteEvent event,
    Emitter<PlaylistsState> emit,
  ) async {
    final Either<Failure, Playlist> result =
        await _toggleFavoritePlaylistUseCase(event.playlistId);
    await result.fold(
      (failure) async => emit(
        PlaylistsState.error(failure.message ?? 'Failed to toggle favorite'),
      ),
      (playlist) async {
        // Reload playlists to get updated list
        final Either<Failure, List<Playlist>> loadResult =
            await _getAllPlaylistsUseCase();
        await loadResult.fold(
          (failure) async => emit(
            PlaylistsState.error(failure.message ?? 'Failed to load playlists'),
          ),
          (playlists) async => emit(
            PlaylistsState.favoriteToggled(
              playlist: playlist,
              playlists: playlists,
            ),
          ),
        );
      },
    );
  }

  Future<void> _onDuplicatePlaylist(
    DuplicatePlaylistEvent event,
    Emitter<PlaylistsState> emit,
  ) async {
    // This would require a new use case for duplicating
    // For now, we'll emit an error
    emit(
      const PlaylistsState.error('Duplicate functionality not implemented yet'),
    );
  }

  Future<void> _onClearSearch(
    ClearSearchEvent event,
    Emitter<PlaylistsState> emit,
  ) async {
    final PlaylistsState currentState = state;
    if (currentState is! PlaylistsLoaded) {
      return;
    }

    emit(
      currentState.copyWith(
        searchQuery: '',
        filteredPlaylists: currentState.playlists,
      ),
    );
  }

  Future<void> _onRefreshPlaylists(
    RefreshPlaylistsEvent event,
    Emitter<PlaylistsState> emit,
  ) async {
    add(const LoadPlaylistsEvent());
  }

  @override
  PlaylistsState? fromJson(Map<String, dynamic> json) {
    // Playlists should be loaded from repository, so we always start with initial state
    return const PlaylistsState.initial();
  }

  @override
  Map<String, dynamic>? toJson(PlaylistsState state) {
    // Don't persist complex playlists data - will reload from repository
    return null;
  }
}
