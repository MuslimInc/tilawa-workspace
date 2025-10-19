import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:muzakri/core/errors/failures.dart';
import 'package:muzakri/features/playlists/domain/entities/playlist.dart';
import 'package:muzakri/features/playlists/domain/repositories/playlists_repository.dart';

@Singleton()
class UpdatePlaylistUseCase {
  const UpdatePlaylistUseCase(this._repository);

  final PlaylistsRepository _repository;

  Future<Either<Failure, Playlist>> call(Playlist playlist) async {
    try {
      final updatedPlaylist = await _repository.updatePlaylist(playlist);
      return Right(updatedPlaylist);
    } catch (e) {
      return Left(AudioFailure(e.toString()));
    }
  }
}
