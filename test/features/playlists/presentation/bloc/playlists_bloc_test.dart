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
  });
}
