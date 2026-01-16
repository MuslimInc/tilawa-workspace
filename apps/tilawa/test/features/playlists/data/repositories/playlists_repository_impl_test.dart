import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:tilawa/features/playlists/data/datasources/playlists_local_datasource.dart';
import 'package:tilawa/features/playlists/data/repositories/playlists_repository_impl.dart';
import 'package:tilawa/features/playlists/domain/entities/playlist.dart';

import 'playlists_repository_impl_test.mocks.dart';

@GenerateMocks([PlaylistsLocalDataSource])
void main() {
  late PlaylistsRepositoryImpl repository;
  late MockPlaylistsLocalDataSource mockLocalDataSource;

  setUp(() {
    mockLocalDataSource = MockPlaylistsLocalDataSource();
    repository = PlaylistsRepositoryImpl(mockLocalDataSource);
  });

  final tPlaylist = Playlist(
    id: 'playlist_1',
    name: 'Test Playlist',
    description: 'Test Description',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
    items: const [],
  );

  group('createPlaylist', () {
    test('should return new playlist when name does not exist', () async {
      // Arrange
      when(
        mockLocalDataSource.doesPlaylistNameExist(any),
      ).thenAnswer((_) async => false);
      when(
        mockLocalDataSource.generatePlaylistId(),
      ).thenAnswer((_) async => 'playlist_1');
      when(mockLocalDataSource.savePlaylist(any)).thenAnswer((_) async => {});

      // Act
      final Playlist result = await repository.createPlaylist(
        name: 'Test Playlist',
        description: 'Test Description',
      );

      // Assert
      expect(result.name, 'Test Playlist');
      expect(result.id, 'playlist_1');
      verify(
        mockLocalDataSource.doesPlaylistNameExist('Test Playlist'),
      ).called(1);
      verify(mockLocalDataSource.savePlaylist(any)).called(1);
    });

    test('should throw exception when name already exists', () async {
      // Arrange
      when(
        mockLocalDataSource.doesPlaylistNameExist(any),
      ).thenAnswer((_) async => true);

      // Act
      final Future<Playlist> Function({
        String? coverImageUrl,
        required String description,
        bool isPublic,
        required String name,
      })
      call = repository.createPlaylist;

      // Assert
      expect(
        () => call(name: 'Test Playlist', description: 'Test Description'),
        throwsException,
      );
    });
  });

  group('addItemToPlaylist', () {
    final tPlaylistItem = PlaylistItem(
      id: 'i1',
      title: 'Item 1',
      artist: 'Artist 1',
      url: 'url1',
      duration: const Duration(seconds: 10),
      addedAt: DateTime.now(),
    );

    test('should add item and return updated playlist', () async {
      // Arrange
      when(
        mockLocalDataSource.getPlaylistById(any),
      ).thenAnswer((_) async => tPlaylist);
      when(mockLocalDataSource.savePlaylist(any)).thenAnswer((_) async => {});

      // Act
      final Playlist result = await repository.addItemToPlaylist(
        'playlist_1',
        tPlaylistItem,
      );

      // Assert
      expect(result.items.length, 1);
      expect(result.items.first, tPlaylistItem);
      verify(mockLocalDataSource.getPlaylistById('playlist_1')).called(1);
      verify(mockLocalDataSource.savePlaylist(any)).called(1);
    });

    test('should throw exception when item already exists', () async {
      // Arrange
      final Playlist playlistWithItem = tPlaylist.copyWith(
        items: [tPlaylistItem],
      );
      when(
        mockLocalDataSource.getPlaylistById(any),
      ).thenAnswer((_) async => playlistWithItem);

      // Act
      final Future<Playlist> Function(String playlistId, PlaylistItem item)
      call = repository.addItemToPlaylist;

      // Assert
      expect(() => call('playlist_1', tPlaylistItem), throwsException);
    });
  });

  group('searchPlaylists', () {
    test('should return filtered playlists locally', () async {
      // Arrange
      final List<Playlist> tPlaylists = [
        tPlaylist,
        tPlaylist.copyWith(
          id: 'playlist_2',
          name: 'Other',
          description: 'Other description',
        ),
      ];
      when(
        mockLocalDataSource.getAllPlaylists(),
      ).thenAnswer((_) async => tPlaylists);

      // Act
      final List<Playlist> result = await repository.searchPlaylists('Test');

      // Assert
      expect(result.length, 1);
      expect(result.first.name, 'Test Playlist');
    });
  });

  group('updatePlaylist', () {
    test('should update and return updated playlist', () async {
      // Arrange
      when(
        mockLocalDataSource.getPlaylistById(any),
      ).thenAnswer((_) async => tPlaylist);
      when(
        mockLocalDataSource.doesPlaylistNameExist(
          any,
          excludeId: anyNamed('excludeId'),
        ),
      ).thenAnswer((_) async => false);
      when(mockLocalDataSource.savePlaylist(any)).thenAnswer((_) async => {});

      final Playlist updatedPlaylist = tPlaylist.copyWith(name: 'Updated Name');

      // Act
      final Playlist result = await repository.updatePlaylist(updatedPlaylist);

      // Assert
      expect(result.name, 'Updated Name');
      verify(mockLocalDataSource.savePlaylist(any)).called(1);
    });
  });

  group('deletePlaylist', () {
    test('should call delete on local data source', () async {
      // Arrange
      when(
        mockLocalDataSource.getPlaylistById(any),
      ).thenAnswer((_) async => tPlaylist);
      when(mockLocalDataSource.deletePlaylist(any)).thenAnswer((_) async => {});

      // Act
      await repository.deletePlaylist('playlist_1');

      // Assert
      verify(mockLocalDataSource.deletePlaylist('playlist_1')).called(1);
    });
  });
}
