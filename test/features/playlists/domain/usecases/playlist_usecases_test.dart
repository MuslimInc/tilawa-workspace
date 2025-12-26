import 'package:dartz_plus/dartz_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:tilawa/core/errors/failures.dart';
import 'package:tilawa/features/playlists/domain/entities/playlist.dart';
import 'package:tilawa/features/playlists/domain/repositories/playlists_repository.dart';
import 'package:tilawa/features/playlists/domain/usecases/add_item_to_playlist_use_case.dart';
import 'package:tilawa/features/playlists/domain/usecases/create_playlist_use_case.dart';
import 'package:tilawa/features/playlists/domain/usecases/get_all_playlists_use_case.dart';
import 'package:tilawa/features/playlists/domain/usecases/remove_item_from_playlist_use_case.dart';
import 'package:tilawa/features/playlists/domain/usecases/search_playlists_use_case.dart';

import 'playlist_usecases_test.mocks.dart';

@GenerateMocks([PlaylistsRepository])
void main() {
  late CreatePlaylistUseCase createPlaylistUseCase;
  late GetAllPlaylistsUseCase getAllPlaylistsUseCase;
  late AddItemToPlaylistUseCase addItemToPlaylistUseCase;
  late RemoveItemFromPlaylistUseCase removeItemFromPlaylistUseCase;
  late SearchPlaylistsUseCase searchPlaylistsUseCase;
  late MockPlaylistsRepository mockRepository;

  setUp(() {
    mockRepository = MockPlaylistsRepository();
    createPlaylistUseCase = CreatePlaylistUseCase(mockRepository);
    getAllPlaylistsUseCase = GetAllPlaylistsUseCase(mockRepository);
    addItemToPlaylistUseCase = AddItemToPlaylistUseCase(mockRepository);
    removeItemFromPlaylistUseCase = RemoveItemFromPlaylistUseCase(
      mockRepository,
    );
    searchPlaylistsUseCase = SearchPlaylistsUseCase(mockRepository);
  });

  final tPlaylist = Playlist(
    id: '1',
    name: 'Test Playlist',
    description: 'Test Description',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
    items: const [],
  );

  group('CreatePlaylistUseCase', () {
    test('should call createPlaylist on repository', () async {
      // Arrange
      when(
        mockRepository.createPlaylist(
          name: anyNamed('name'),
          description: anyNamed('description'),
        ),
      ).thenAnswer((_) async => tPlaylist);

      // Act
      final Either<Failure, Playlist> result = await createPlaylistUseCase(
        name: 'Test Playlist',
        description: 'Test Description',
      );

      // Assert
      expect(result, Right<Failure, Playlist>(tPlaylist));
      verify(
        mockRepository.createPlaylist(
          name: 'Test Playlist',
          description: 'Test Description',
        ),
      ).called(1);
    });
  });

  group('GetAllPlaylistsUseCase', () {
    final tPlaylists = [tPlaylist];

    test('should call getAllPlaylists on repository', () async {
      // Arrange
      when(
        mockRepository.getAllPlaylists(),
      ).thenAnswer((_) async => tPlaylists);

      // Act
      final Either<Failure, List<Playlist>> result =
          await getAllPlaylistsUseCase();

      // Assert
      expect(result, Right<Failure, List<Playlist>>(tPlaylists));
      verify(mockRepository.getAllPlaylists()).called(1);
    });
  });

  group('AddItemToPlaylistUseCase', () {
    final tPlaylistItem = PlaylistItem(
      id: 'i1',
      title: 'Item 1',
      artist: 'Artist 1',
      url: 'url1',
      duration: const Duration(seconds: 10),
      addedAt: DateTime.now(),
    );

    test('should call addItemToPlaylist on repository', () async {
      // Arrange
      final Playlist updatedPlaylist = tPlaylist.copyWith(
        items: [tPlaylistItem],
      );
      when(
        mockRepository.addItemToPlaylist(any, any),
      ).thenAnswer((_) async => updatedPlaylist);

      // Act
      final Either<Failure, Playlist> result = await addItemToPlaylistUseCase(
        playlistId: '1',
        item: tPlaylistItem,
      );

      // Assert
      expect(result, Right<Failure, Playlist>(updatedPlaylist));
      verify(mockRepository.addItemToPlaylist('1', tPlaylistItem)).called(1);
    });
  });

  group('RemoveItemFromPlaylistUseCase', () {
    test('should call removeItemFromPlaylist on repository', () async {
      // Arrange
      when(
        mockRepository.removeItemFromPlaylist(any, any),
      ).thenAnswer((_) async => tPlaylist);

      // Act
      final Either<Failure, Playlist> result =
          await removeItemFromPlaylistUseCase(playlistId: '1', itemId: 'i1');

      // Assert
      expect(result, Right<Failure, Playlist>(tPlaylist));
      verify(mockRepository.removeItemFromPlaylist('1', 'i1')).called(1);
    });
  });

  group('SearchPlaylistsUseCase', () {
    final tPlaylists = [tPlaylist];

    test('should call searchPlaylists on repository', () async {
      // Arrange
      when(
        mockRepository.searchPlaylists(any),
      ).thenAnswer((_) async => tPlaylists);

      // Act
      final Either<Failure, List<Playlist>> result =
          await searchPlaylistsUseCase('test');

      // Assert
      expect(result, Right<Failure, List<Playlist>>(tPlaylists));
      verify(mockRepository.searchPlaylists('test')).called(1);
    });
  });
}
