import 'package:dartz_plus/dartz_plus.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failures.dart';
import '../entities/playlist.dart';
import '../repositories/playlists_repository.dart';

@Singleton()
class AddItemToPlaylistUseCase {
  const AddItemToPlaylistUseCase(this._repository);

  final PlaylistsRepository _repository;

  Future<Either<Failure, Playlist>> call({
    required String playlistId,
    required PlaylistItem item,
  }) async {
    try {
      final Playlist playlist = await _repository.addItemToPlaylist(
        playlistId,
        item,
      );
      return Right(playlist);
    } catch (e) {
      return Left(AudioFailure(e.toString()));
    }
  }
}
