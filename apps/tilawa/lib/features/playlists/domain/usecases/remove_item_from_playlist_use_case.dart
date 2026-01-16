import 'package:dartz_plus/dartz_plus.dart';
import 'package:injectable/injectable.dart';

import 'package:tilawa_core/errors/failures.dart';
import '../entities/playlist.dart';
import '../repositories/playlists_repository.dart';

@Singleton()
class RemoveItemFromPlaylistUseCase {
  const RemoveItemFromPlaylistUseCase(this._repository);

  final PlaylistsRepository _repository;

  Future<Either<Failure, Playlist>> call({
    required String playlistId,
    required String itemId,
  }) async {
    try {
      final Playlist playlist = await _repository.removeItemFromPlaylist(
        playlistId,
        itemId,
      );
      return Right(playlist);
    } catch (e) {
      return Left(AudioFailure(e.toString()));
    }
  }
}
