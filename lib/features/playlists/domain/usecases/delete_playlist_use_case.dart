import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:muzakri/core/errors/failures.dart';
import 'package:muzakri/core/utils/typedefs.dart';
import 'package:muzakri/features/playlists/domain/repositories/playlists_repository.dart';

@Singleton()
class DeletePlaylistUseCase {
  const DeletePlaylistUseCase(this._repository);

  final PlaylistsRepository _repository;

  ResultFuture<void> call(String playlistId) async {
    try {
      await _repository.deletePlaylist(playlistId);
      return const Right(null);
    } catch (e) {
      return Left(AudioFailure(e.toString()));
    }
  }
}
