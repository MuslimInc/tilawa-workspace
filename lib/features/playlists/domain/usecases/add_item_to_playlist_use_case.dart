import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:muzakri/core/errors/failures.dart';
import 'package:muzakri/features/playlists/domain/entities/playlist.dart';
import 'package:muzakri/features/playlists/domain/repositories/playlists_repository.dart';

@Singleton()
class AddItemToPlaylistUseCase {
  const AddItemToPlaylistUseCase(this._repository);

  final PlaylistsRepository _repository;

  Future<Either<Failure, Playlist>> call({
    required String playlistId,
    required PlaylistItem item,
  }) async {
    try {
      final playlist = await _repository.addItemToPlaylist(playlistId, item);
      return Right(playlist);
    } catch (e) {
      return Left(AudioFailure(e.toString()));
    }
  }
}
