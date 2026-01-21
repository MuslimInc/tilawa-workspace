import 'package:dartz_plus/dartz_plus.dart';
import 'package:injectable/injectable.dart';

import 'package:tilawa_core/errors/failures.dart';
import '../entities/playlist.dart';
import '../repositories/playlists_repository.dart';

@Singleton()
class UpdatePlaylistUseCase {
  const UpdatePlaylistUseCase(this._repository);

  final PlaylistsRepository _repository;

  Future<Either<Failure, Playlist>> call(Playlist playlist) async {
    try {
      final Playlist updatedPlaylist = await _repository.updatePlaylist(
        playlist,
      );
      return Right(updatedPlaylist);
    } catch (e) {
      return Left(AudioFailure(e.toString()));
    }
  }
}
