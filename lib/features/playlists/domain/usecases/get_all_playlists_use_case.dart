import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:muzakri/core/errors/failures.dart';
import 'package:muzakri/features/playlists/domain/entities/playlist.dart';
import 'package:muzakri/features/playlists/domain/repositories/playlists_repository.dart';

@Singleton()
class GetAllPlaylistsUseCase {
  const GetAllPlaylistsUseCase(this._repository);

  final PlaylistsRepository _repository;

  Future<Either<Failure, List<Playlist>>> call() async {
    try {
      final playlists = await _repository.getAllPlaylists();
      return Right(playlists);
    } catch (e) {
      return Left(AudioFailure(e.toString()));
    }
  }
}
