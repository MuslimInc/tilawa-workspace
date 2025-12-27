import 'package:bloc_test/bloc_test.dart';
import 'package:dartz_plus/dartz_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:tilawa/core/errors/failures.dart';
import 'package:tilawa/features/playlists/domain/entities/playlist.dart';
import 'package:tilawa/features/playlists/domain/usecases/usecases.dart';
import 'package:tilawa/features/playlists/presentation/bloc/playlists_bloc.dart';

import 'playlists_bloc_test.mocks.dart';

@GenerateMocks([
  GetAllPlaylistsUseCase,
  CreatePlaylistUseCase,
  UpdatePlaylistUseCase,
  DeletePlaylistUseCase,
  AddItemToPlaylistUseCase,
  RemoveItemFromPlaylistUseCase,
  SearchPlaylistsUseCase,
  ToggleFavoritePlaylistUseCase,
  Storage,
])
void main() {
  late PlaylistsBloc bloc;
  late MockGetAllPlaylistsUseCase mockGetAllPlaylistsUseCase;
  late MockCreatePlaylistUseCase mockCreatePlaylistUseCase;
  late MockUpdatePlaylistUseCase mockUpdatePlaylistUseCase;
  late MockDeletePlaylistUseCase mockDeletePlaylistUseCase;
  late MockAddItemToPlaylistUseCase mockAddItemToPlaylistUseCase;
  late MockRemoveItemFromPlaylistUseCase mockRemoveItemFromPlaylistUseCase;
  late MockSearchPlaylistsUseCase mockSearchPlaylistsUseCase;
  late MockToggleFavoritePlaylistUseCase mockToggleFavoritePlaylistUseCase;
  late MockStorage mockStorage;

  setUpAll(() {
    provideDummy<Either<Failure, List<Playlist>>>(const Right([]));
    provideDummy<Either<Failure, Playlist>>(
      Right(
        Playlist(
          id: '1',
          name: 'Test',
          description: 'Desc',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          items: const [],
        ),
      ),
    );
    provideDummy<Either<Failure, void>>(const Right(null));
  });

  setUp(() {
    mockGetAllPlaylistsUseCase = MockGetAllPlaylistsUseCase();
    mockCreatePlaylistUseCase = MockCreatePlaylistUseCase();
    mockUpdatePlaylistUseCase = MockUpdatePlaylistUseCase();
    mockDeletePlaylistUseCase = MockDeletePlaylistUseCase();
    mockAddItemToPlaylistUseCase = MockAddItemToPlaylistUseCase();
    mockRemoveItemFromPlaylistUseCase = MockRemoveItemFromPlaylistUseCase();
    mockSearchPlaylistsUseCase = MockSearchPlaylistsUseCase();
    mockToggleFavoritePlaylistUseCase = MockToggleFavoritePlaylistUseCase();
    mockStorage = MockStorage();

    when(mockStorage.write(any, any)).thenAnswer((_) async => {});
    HydratedBloc.storage = mockStorage;

    bloc = PlaylistsBloc(
      getAllPlaylistsUseCase: mockGetAllPlaylistsUseCase,
      createPlaylistUseCase: mockCreatePlaylistUseCase,
      updatePlaylistUseCase: mockUpdatePlaylistUseCase,
      deletePlaylistUseCase: mockDeletePlaylistUseCase,
      addItemToPlaylistUseCase: mockAddItemToPlaylistUseCase,
      removeItemFromPlaylistUseCase: mockRemoveItemFromPlaylistUseCase,
      searchPlaylistsUseCase: mockSearchPlaylistsUseCase,
      toggleFavoritePlaylistUseCase: mockToggleFavoritePlaylistUseCase,
    );
  });

  final tPlaylist = Playlist(
    id: '1',
    name: 'Test',
    description: 'Desc',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
    items: const [],
  );

  final tDateTime = DateTime(2025);

  final tItem = PlaylistItem(
    id: '1',
    title: 'Title',
    artist: 'Reciter',
    url: 'url',
    duration: const Duration(minutes: 5),
    addedAt: tDateTime,
  );

  group('LoadPlaylistsEvent', () {
    blocTest<PlaylistsBloc, PlaylistsState>(
      'emits [Loading, Loaded] when successful',
      build: () {
        when(
          mockGetAllPlaylistsUseCase(),
        ).thenAnswer((_) async => Right([tPlaylist]));
        return bloc;
      },
      act: (bloc) => bloc.add(const LoadPlaylistsEvent()),
      expect: () => [
        const PlaylistsState.loading(),
        PlaylistsState.loaded(
          playlists: [tPlaylist],
          filteredPlaylists: [tPlaylist],
        ),
      ],
    );

    blocTest<PlaylistsBloc, PlaylistsState>(
      'emits [Loading, Error] when fails',
      build: () {
        when(
          mockGetAllPlaylistsUseCase(),
        ).thenAnswer((_) async => const Left(AudioFailure('Error')));
        return bloc;
      },
      act: (bloc) => bloc.add(const LoadPlaylistsEvent()),
      expect: () => [
        const PlaylistsState.loading(),
        const PlaylistsState.error('Error'),
      ],
    );
  });

  group('CreatePlaylistEvent', () {
    blocTest<PlaylistsBloc, PlaylistsState>(
      'emits [PlaylistCreated] and reloads playlists when successful',
      build: () {
        when(
          mockCreatePlaylistUseCase(
            name: anyNamed('name'),
            description: anyNamed('description'),
            coverImageUrl: anyNamed('coverImageUrl'),
            isPublic: anyNamed('isPublic'),
          ),
        ).thenAnswer((_) async => Right(tPlaylist));
        when(
          mockGetAllPlaylistsUseCase(),
        ).thenAnswer((_) async => Right([tPlaylist]));
        return bloc;
      },
      act: (bloc) => bloc.add(
        const CreatePlaylistEvent(name: 'Test', description: 'Desc'),
      ),
      expect: () => [
        PlaylistsState.playlistCreated(
          playlist: tPlaylist,
          playlists: [tPlaylist],
        ),
      ],
    );
    blocTest<PlaylistsBloc, PlaylistsState>(
      'emits [Error] when creation fails',
      build: () {
        when(
          mockCreatePlaylistUseCase(
            name: anyNamed('name'),
            description: anyNamed('description'),
            coverImageUrl: anyNamed('coverImageUrl'),
            isPublic: anyNamed('isPublic'),
          ),
        ).thenAnswer((_) async => const Left(AudioFailure('Create Error')));
        return bloc;
      },
      act: (bloc) => bloc.add(
        const CreatePlaylistEvent(name: 'Test', description: 'Desc'),
      ),
      expect: () => [const PlaylistsState.error('Create Error')],
    );

    blocTest<PlaylistsBloc, PlaylistsState>(
      'emits [Error] when reload fails after creation',
      build: () {
        when(
          mockCreatePlaylistUseCase(
            name: anyNamed('name'),
            description: anyNamed('description'),
            coverImageUrl: anyNamed('coverImageUrl'),
            isPublic: anyNamed('isPublic'),
          ),
        ).thenAnswer((_) async => Right(tPlaylist));
        when(
          mockGetAllPlaylistsUseCase(),
        ).thenAnswer((_) async => const Left(AudioFailure('Reload Error')));
        return bloc;
      },
      act: (bloc) => bloc.add(
        const CreatePlaylistEvent(name: 'Test', description: 'Desc'),
      ),
      expect: () => [const PlaylistsState.error('Reload Error')],
    );
  });

  group('UpdatePlaylistEvent', () {
    blocTest<PlaylistsBloc, PlaylistsState>(
      'emits [PlaylistUpdated] and reloads playlists when successful',
      build: () {
        when(
          mockUpdatePlaylistUseCase(any),
        ).thenAnswer((_) async => Right(tPlaylist));
        when(
          mockGetAllPlaylistsUseCase(),
        ).thenAnswer((_) async => Right([tPlaylist]));
        return bloc;
      },
      seed: () => PlaylistsState.loaded(
        playlists: [tPlaylist],
        filteredPlaylists: [tPlaylist],
      ),
      act: (bloc) => bloc.add(
        const UpdatePlaylistEvent(
          id: '1',
          name: 'Updated Name',
          description: 'Desc',
        ),
      ),
      expect: () => [
        PlaylistsState.playlistUpdated(
          playlist: tPlaylist,
          playlists: [tPlaylist],
        ),
      ],
    );

    blocTest<PlaylistsBloc, PlaylistsState>(
      'does nothing if state is not loaded',
      build: () => bloc,
      act: (bloc) => bloc.add(
        const UpdatePlaylistEvent(
          id: '1',
          name: 'Updated Name',
          description: 'Desc',
        ),
      ),
      expect: () => [],
    );

    blocTest<PlaylistsBloc, PlaylistsState>(
      'emits [Error] when update fails',
      build: () {
        when(
          mockUpdatePlaylistUseCase(any),
        ).thenAnswer((_) async => const Left(AudioFailure('Update Error')));
        return bloc;
      },
      seed: () => PlaylistsState.loaded(
        playlists: [tPlaylist],
        filteredPlaylists: [tPlaylist],
      ),
      act: (bloc) => bloc.add(
        const UpdatePlaylistEvent(
          id: '1',
          name: 'Updated Name',
          description: 'Desc',
        ),
      ),
      expect: () => [const PlaylistsState.error('Update Error')],
    );
  });

  group('DeletePlaylistEvent', () {
    blocTest<PlaylistsBloc, PlaylistsState>(
      'emits [PlaylistDeleted] and reloads playlists when successful',
      build: () {
        when(
          mockDeletePlaylistUseCase(any),
        ).thenAnswer((_) async => const Right(null));
        when(
          mockGetAllPlaylistsUseCase(),
        ).thenAnswer((_) async => const Right([]));
        return bloc;
      },
      act: (bloc) => bloc.add(const DeletePlaylistEvent('1')),
      expect: () => [
        const PlaylistsState.playlistDeleted(playlistId: '1', playlists: []),
      ],
    );

    blocTest<PlaylistsBloc, PlaylistsState>(
      'emits [Error] when deletion fails',
      build: () {
        when(
          mockDeletePlaylistUseCase(any),
        ).thenAnswer((_) async => const Left(AudioFailure('Delete Error')));
        return bloc;
      },
      act: (bloc) => bloc.add(const DeletePlaylistEvent('1')),
      expect: () => [const PlaylistsState.error('Delete Error')],
    );
  });

  group('AddItemToPlaylistEvent', () {
    final tItem = PlaylistItem(
      id: 's1',
      title: 'Surah',
      artist: 'Reciter',
      url: 'url',
      duration: Duration.zero,
      addedAt: tDateTime,
    );

    blocTest<PlaylistsBloc, PlaylistsState>(
      'emits [ItemAdded] and reloads playlists when successful',
      build: () {
        when(
          mockAddItemToPlaylistUseCase(
            playlistId: anyNamed('playlistId'),
            item: anyNamed('item'),
          ),
        ).thenAnswer((_) async => Right(tPlaylist));
        when(
          mockGetAllPlaylistsUseCase(),
        ).thenAnswer((_) async => Right([tPlaylist]));
        return bloc;
      },
      act: (bloc) =>
          bloc.add(AddItemToPlaylistEvent(playlistId: '1', item: tItem)),
      expect: () => [
        PlaylistsState.itemAdded(playlist: tPlaylist, playlists: [tPlaylist]),
      ],
    );

    blocTest<PlaylistsBloc, PlaylistsState>(
      'emits [Error] when addition fails',
      build: () {
        when(
          mockAddItemToPlaylistUseCase(
            playlistId: anyNamed('playlistId'),
            item: anyNamed('item'),
          ),
        ).thenAnswer((_) async => const Left(AudioFailure('Add Error')));
        return bloc;
      },
      act: (bloc) =>
          bloc.add(AddItemToPlaylistEvent(playlistId: '1', item: tItem)),
      expect: () => [const PlaylistsState.error('Add Error')],
    );
  });

  group('RemoveItemFromPlaylistEvent', () {
    blocTest<PlaylistsBloc, PlaylistsState>(
      'emits [ItemRemoved] and reloads playlists when successful',
      build: () {
        when(
          mockRemoveItemFromPlaylistUseCase(
            playlistId: anyNamed('playlistId'),
            itemId: anyNamed('itemId'),
          ),
        ).thenAnswer((_) async => Right(tPlaylist));
        when(
          mockGetAllPlaylistsUseCase(),
        ).thenAnswer((_) async => Right([tPlaylist]));
        return bloc;
      },
      act: (bloc) => bloc.add(
        const RemoveItemFromPlaylistEvent(playlistId: '1', itemId: 's1'),
      ),
      expect: () => [
        PlaylistsState.itemRemoved(playlist: tPlaylist, playlists: [tPlaylist]),
      ],
    );

    blocTest<PlaylistsBloc, PlaylistsState>(
      'emits [Error] when removal fails',
      build: () {
        when(
          mockRemoveItemFromPlaylistUseCase(
            playlistId: anyNamed('playlistId'),
            itemId: anyNamed('itemId'),
          ),
        ).thenAnswer((_) async => const Left(AudioFailure('Remove Error')));
        return bloc;
      },
      act: (bloc) => bloc.add(
        const RemoveItemFromPlaylistEvent(playlistId: '1', itemId: 's1'),
      ),
      expect: () => [const PlaylistsState.error('Remove Error')],
    );
  });

  group('SearchPlaylistsEvent', () {
    blocTest<PlaylistsBloc, PlaylistsState>(
      'emits loaded state with search results',
      build: () {
        when(
          mockSearchPlaylistsUseCase(any),
        ).thenAnswer((_) async => Right([tPlaylist]));
        return bloc;
      },
      seed: () => PlaylistsState.loaded(
        playlists: [tPlaylist],
        filteredPlaylists: [tPlaylist],
      ),
      act: (bloc) => bloc.add(const SearchPlaylistsEvent('query')),
      expect: () => [
        PlaylistsState.loaded(
          playlists: [tPlaylist],
          filteredPlaylists: [tPlaylist],
          searchQuery: 'query',
        ),
      ],
    );

    blocTest<PlaylistsBloc, PlaylistsState>(
      'returns original list on empty query',
      build: () => bloc,
      seed: () => PlaylistsState.loaded(
        playlists: [tPlaylist],
        filteredPlaylists: [],
        searchQuery: 'prev',
      ),
      act: (bloc) => bloc.add(const SearchPlaylistsEvent('')),
      expect: () => [
        PlaylistsState.loaded(
          playlists: [tPlaylist],
          filteredPlaylists: [tPlaylist],
        ),
      ],
    );

    blocTest<PlaylistsBloc, PlaylistsState>(
      'does nothing if state is not loaded',
      build: () => bloc,
      act: (bloc) => bloc.add(const SearchPlaylistsEvent('query')),
      expect: () => [],
    );

    blocTest<PlaylistsBloc, PlaylistsState>(
      'emits error when search fails',
      build: () {
        when(
          mockSearchPlaylistsUseCase(any),
        ).thenAnswer((_) async => const Left(AudioFailure('Search Error')));
        return bloc;
      },
      seed: () => PlaylistsState.loaded(
        playlists: [tPlaylist],
        filteredPlaylists: [tPlaylist],
      ),
      act: (bloc) => bloc.add(const SearchPlaylistsEvent('query')),
      expect: () => [const PlaylistsState.error('Search Error')],
    );
  });

  group('ToggleFavoriteEvent', () {
    blocTest<PlaylistsBloc, PlaylistsState>(
      'emits [FavoriteToggled] when successful',
      build: () {
        when(
          mockToggleFavoritePlaylistUseCase(any),
        ).thenAnswer((_) async => Right(tPlaylist));
        when(
          mockGetAllPlaylistsUseCase(),
        ).thenAnswer((_) async => Right([tPlaylist]));
        return bloc;
      },
      act: (bloc) => bloc.add(const ToggleFavoriteEvent('1')),
      expect: () => [
        PlaylistsState.favoriteToggled(
          playlist: tPlaylist,
          playlists: [tPlaylist],
        ),
      ],
    );

    blocTest<PlaylistsBloc, PlaylistsState>(
      'emits error when toggle fails',
      build: () {
        when(
          mockToggleFavoritePlaylistUseCase(any),
        ).thenAnswer((_) async => const Left(AudioFailure('Toggle Error')));
        return bloc;
      },
      act: (bloc) => bloc.add(const ToggleFavoriteEvent('1')),
      expect: () => [const PlaylistsState.error('Toggle Error')],
    );
  });

  group('Special Events', () {
    blocTest<PlaylistsBloc, PlaylistsState>(
      'ReorderPlaylistItemsEvent emits error',
      build: () => bloc,
      act: (bloc) => bloc.add(
        const ReorderPlaylistItemsEvent(
          playlistId: '1',
          oldIndex: 0,
          newIndex: 1,
        ),
      ),
      expect: () => [
        const PlaylistsState.error('Reorder functionality not implemented yet'),
      ],
    );

    blocTest<PlaylistsBloc, PlaylistsState>(
      'DuplicatePlaylistEvent emits error',
      build: () => bloc,
      act: (bloc) => bloc.add(
        const DuplicatePlaylistEvent(playlistId: '1', newName: 'New Name'),
      ),
      expect: () => [
        const PlaylistsState.error(
          'Duplicate functionality not implemented yet',
        ),
      ],
    );

    blocTest<PlaylistsBloc, PlaylistsState>(
      'ClearSearchEvent clears search query',
      build: () => bloc,
      seed: () => PlaylistsState.loaded(
        playlists: [tPlaylist],
        filteredPlaylists: [],
        searchQuery: 'query',
      ),
      act: (bloc) => bloc.add(const ClearSearchEvent()),
      expect: () => [
        PlaylistsState.loaded(
          playlists: [tPlaylist],
          filteredPlaylists: [tPlaylist],
        ),
      ],
    );

    blocTest<PlaylistsBloc, PlaylistsState>(
      'RefreshPlaylistsEvent adds LoadPlaylistsEvent',
      build: () {
        when(
          mockGetAllPlaylistsUseCase(),
        ).thenAnswer((_) async => Right([tPlaylist]));
        return bloc;
      },
      act: (bloc) => bloc.add(const RefreshPlaylistsEvent()),
      expect: () => [
        const PlaylistsState.loading(),
        PlaylistsState.loaded(
          playlists: [tPlaylist],
          filteredPlaylists: [tPlaylist],
        ),
      ],
    );
    blocTest<PlaylistsBloc, PlaylistsState>(
      'emits [Error] when update fails - playlist not found',
      build: () => bloc,
      seed: () => PlaylistsState.loaded(
        playlists: [tPlaylist],
        filteredPlaylists: [tPlaylist],
      ),
      act: (bloc) => bloc.add(
        const UpdatePlaylistEvent(
          id: 'non-existent',
          name: 'Name',
          description: 'Desc',
        ),
      ),
      expect: () => [const PlaylistsState.error('Playlist not found')],
    );

    blocTest<PlaylistsBloc, PlaylistsState>(
      'emits [Error] when reload fails after creation',
      build: () {
        when(
          mockCreatePlaylistUseCase(
            name: anyNamed('name'),
            description: anyNamed('description'),
            coverImageUrl: anyNamed('coverImageUrl'),
            isPublic: anyNamed('isPublic'),
          ),
        ).thenAnswer((_) async => Right(tPlaylist));
        when(
          mockGetAllPlaylistsUseCase(),
        ).thenAnswer((_) async => const Left(AudioFailure('Reload Error')));
        return bloc;
      },
      act: (bloc) =>
          bloc.add(const CreatePlaylistEvent(name: 'New', description: 'Desc')),
      expect: () => [const PlaylistsState.error('Reload Error')],
    );

    blocTest<PlaylistsBloc, PlaylistsState>(
      'emits [Error] when reload fails after delete',
      build: () {
        when(
          mockDeletePlaylistUseCase(any),
        ).thenAnswer((_) async => const Right(null));
        when(
          mockGetAllPlaylistsUseCase(),
        ).thenAnswer((_) async => const Left(AudioFailure('Reload Error')));
        return bloc;
      },
      act: (bloc) => bloc.add(const DeletePlaylistEvent('1')),
      expect: () => [const PlaylistsState.error('Reload Error')],
    );

    blocTest<PlaylistsBloc, PlaylistsState>(
      'emits [Error] when reload fails after add item',
      build: () {
        when(
          mockAddItemToPlaylistUseCase(
            playlistId: anyNamed('playlistId'),
            item: anyNamed('item'),
          ),
        ).thenAnswer((_) async => Right(tPlaylist));
        when(
          mockGetAllPlaylistsUseCase(),
        ).thenAnswer((_) async => const Left(AudioFailure('Reload Error')));
        return bloc;
      },
      act: (bloc) =>
          bloc.add(AddItemToPlaylistEvent(playlistId: '1', item: tItem)),
      expect: () => [const PlaylistsState.error('Reload Error')],
    );

    blocTest<PlaylistsBloc, PlaylistsState>(
      'emits [Error] when reload fails after favorite toggle',
      build: () {
        when(
          mockToggleFavoritePlaylistUseCase(any),
        ).thenAnswer((_) async => Right(tPlaylist));
        when(
          mockGetAllPlaylistsUseCase(),
        ).thenAnswer((_) async => const Left(AudioFailure('Reload Error')));
        return bloc;
      },
      act: (bloc) => bloc.add(const ToggleFavoriteEvent('1')),
      expect: () => [const PlaylistsState.error('Reload Error')],
    );

    blocTest<PlaylistsBloc, PlaylistsState>(
      'emits [Error] when reload fails after update',
      build: () {
        when(
          mockUpdatePlaylistUseCase(any),
        ).thenAnswer((_) async => Right(tPlaylist));
        when(
          mockGetAllPlaylistsUseCase(),
        ).thenAnswer((_) async => const Left(AudioFailure('Reload Error')));
        return bloc;
      },
      seed: () => PlaylistsState.loaded(
        playlists: [tPlaylist],
        filteredPlaylists: [tPlaylist],
      ),
      act: (bloc) => bloc.add(
        const UpdatePlaylistEvent(id: '1', name: 'New', description: 'Desc'),
      ),
      expect: () => [const PlaylistsState.error('Reload Error')],
    );

    blocTest<PlaylistsBloc, PlaylistsState>(
      'emits [Error] when reload fails after remove item',
      build: () {
        when(
          mockRemoveItemFromPlaylistUseCase(
            playlistId: anyNamed('playlistId'),
            itemId: anyNamed('itemId'),
          ),
        ).thenAnswer((_) async => Right(tPlaylist));
        when(
          mockGetAllPlaylistsUseCase(),
        ).thenAnswer((_) async => const Left(AudioFailure('Reload Error')));
        return bloc;
      },
      act: (bloc) => bloc.add(
        const RemoveItemFromPlaylistEvent(playlistId: '1', itemId: 's1'),
      ),
      expect: () => [const PlaylistsState.error('Reload Error')],
    );

    test('fromJson returns initial state', () {
      expect(bloc.fromJson({}), const PlaylistsState.initial());
    });

    test('toJson returns null', () {
      expect(bloc.toJson(const PlaylistsState.initial()), null);
    });
  });
}
