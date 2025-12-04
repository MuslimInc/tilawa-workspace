import 'package:dartz_plus/dartz_plus.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/typedefs.dart';
import '../repositories/playlists_repository.dart';

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
