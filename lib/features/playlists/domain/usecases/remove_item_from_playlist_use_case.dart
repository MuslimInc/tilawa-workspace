import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:muzakri/core/errors/failures.dart';
import 'package:muzakri/features/playlists/domain/entities/playlist.dart';
import 'package:muzakri/features/playlists/domain/repositories/playlists_repository.dart';

@Singleton()
class RemoveItemFromPlaylistUseCase {
  const RemoveItemFromPlaylistUseCase(this._repository);

  final PlaylistsRepository _repository;

  Future<Either<Failure, Playlist>> call({
    required String playlistId,
    required String itemId,
  }) async {
    try {
      final playlist = await _repository.removeItemFromPlaylist(playlistId, itemId);
      return Right(playlist);
    } catch (e) {
      return Left(AudioFailure(e.toString()));
    }
  }
}
