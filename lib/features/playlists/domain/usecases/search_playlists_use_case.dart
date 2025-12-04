import 'package:dartz_plus/dartz_plus.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failures.dart';
import '../entities/playlist.dart';
import '../repositories/playlists_repository.dart';

@Singleton()
class SearchPlaylistsUseCase {
  const SearchPlaylistsUseCase(this._repository);

  final PlaylistsRepository _repository;

  Future<Either<Failure, List<Playlist>>> call(String query) async {
    try {
      final List<Playlist> playlists = await _repository.searchPlaylists(query);
      return Right(playlists);
    } catch (e) {
      return Left(AudioFailure(e.toString()));
    }
  }
}
