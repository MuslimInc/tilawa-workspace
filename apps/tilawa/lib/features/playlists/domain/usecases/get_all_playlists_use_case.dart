import 'package:dartz_plus/dartz_plus.dart';
import 'package:injectable/injectable.dart';

import 'package:tilawa_core/errors/failures.dart';
import '../entities/playlist.dart';
import '../repositories/playlists_repository.dart';

@Singleton()
class GetAllPlaylistsUseCase {
  const GetAllPlaylistsUseCase(this._repository);

  final PlaylistsRepository _repository;

  Future<Either<Failure, List<Playlist>>> call() async {
    try {
      final List<Playlist> playlists = await _repository.getAllPlaylists();
      return Right(playlists);
    } catch (e) {
      return Left(AudioFailure(e.toString()));
    }
  }
}
