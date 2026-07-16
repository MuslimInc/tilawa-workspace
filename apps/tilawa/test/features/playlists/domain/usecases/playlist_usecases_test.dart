import 'package:dartz_plus/dartz_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:tilawa_core/errors/failures.dart';
import 'package:tilawa/features/playlists/domain/entities/playlist.dart';
import 'package:tilawa/features/playlists/domain/repositories/playlists_repository.dart';
import 'package:tilawa/features/playlists/domain/usecases/add_item_to_playlist_use_case.dart';
import 'package:tilawa/features/playlists/domain/usecases/create_playlist_use_case.dart';
import 'package:tilawa/features/playlists/domain/usecases/delete_playlist_use_case.dart';
import 'package:tilawa/features/playlists/domain/usecases/get_all_playlists_use_case.dart';
import 'package:tilawa/features/playlists/domain/usecases/remove_item_from_playlist_use_case.dart';
import 'package:tilawa/features/playlists/domain/usecases/search_playlists_use_case.dart';
import 'package:tilawa/features/playlists/domain/usecases/toggle_favorite_playlist_use_case.dart';
import 'package:tilawa/features/playlists/domain/usecases/update_playlist_use_case.dart';

import 'playlist_usecases_test.mocks.dart';

@GenerateMocks([PlaylistsRepository])
void main() {
  late CreatePlaylistUseCase createPlaylistUseCase;
  late GetAllPlaylistsUseCase getAllPlaylistsUseCase;
  late AddItemToPlaylistUseCase addItemToPlaylistUseCase;
  late RemoveItemFromPlaylistUseCase removeItemFromPlaylistUseCase;
  late SearchPlaylistsUseCase searchPlaylistsUseCase;
  late DeletePlaylistUseCase deletePlaylistUseCase;
  late UpdatePlaylistUseCase updatePlaylistUseCase;
  late ToggleFavoritePlaylistUseCase toggleFavoritePlaylistUseCase;
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
    deletePlaylistUseCase = DeletePlaylistUseCase(mockRepository);
    updatePlaylistUseCase = UpdatePlaylistUseCase(mockRepository);
    toggleFavoritePlaylistUseCase = ToggleFavoritePlaylistUseCase(
      mockRepository,
    );
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

  group('DeletePlaylistUseCase', () {
    test('should call deletePlaylist on repository', () async {
      when(
        mockRepository.deletePlaylist(any),
      ).thenAnswer((_) async {
        return;
      });

      final Either<Failure, void> result = await deletePlaylistUseCase('1');

      expect(result, const Right<Failure, void>(null));
      verify(mockRepository.deletePlaylist('1')).called(1);
    });

    test('wraps repository exceptions in AudioFailure', () async {
      when(
        mockRepository.deletePlaylist(any),
      ).thenThrow(Exception('boom'));

      final Either<Failure, void> result = await deletePlaylistUseCase('1');

      expect(result.isLeft(), isTrue);
      result.fold(
        (f) {
          expect(f, isA<AudioFailure>());
          expect(f.message, contains('boom'));
        },
        (_) => fail('Expected Left result'),
      );
    });
  });

  group('UpdatePlaylistUseCase', () {
    test('should call updatePlaylist and return updated playlist', () async {
      final updated = tPlaylist.copyWith(name: 'Renamed');
      when(
        mockRepository.updatePlaylist(any),
      ).thenAnswer((_) async => updated);

      final Either<Failure, Playlist> result = await updatePlaylistUseCase(
        tPlaylist,
      );

      expect(result, Right<Failure, Playlist>(updated));
      verify(mockRepository.updatePlaylist(tPlaylist)).called(1);
    });

    test('wraps repository exceptions in AudioFailure', () async {
      when(
        mockRepository.updatePlaylist(any),
      ).thenThrow(Exception('db down'));

      final Either<Failure, Playlist> result = await updatePlaylistUseCase(
        tPlaylist,
      );

      result.fold(
        (f) {
          expect(f, isA<AudioFailure>());
          expect(f.message, contains('db down'));
        },
        (_) => fail('Expected Left result'),
      );
    });
  });

  group('ToggleFavoritePlaylistUseCase', () {
    test('should call toggleFavorite and return playlist', () async {
      final favorited = tPlaylist.copyWith(isFavorite: true);
      when(
        mockRepository.toggleFavorite(any),
      ).thenAnswer((_) async => favorited);

      final Either<Failure, Playlist> result =
          await toggleFavoritePlaylistUseCase('1');

      expect(result, Right<Failure, Playlist>(favorited));
      verify(mockRepository.toggleFavorite('1')).called(1);
    });

    test('wraps repository exceptions in AudioFailure', () async {
      when(
        mockRepository.toggleFavorite(any),
      ).thenThrow(Exception('write failed'));

      final Either<Failure, Playlist> result =
          await toggleFavoritePlaylistUseCase('1');

      result.fold(
        (f) {
          expect(f, isA<AudioFailure>());
          expect(f.message, contains('write failed'));
        },
        (_) => fail('Expected Left result'),
      );
    });
  });
}
