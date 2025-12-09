import 'package:dartz_plus/dartz_plus.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/typedefs.dart';
import '../entities/playlist.dart';
import '../repositories/playlists_repository.dart';

@Singleton()
class CreatePlaylistUseCase {
  const CreatePlaylistUseCase(this._repository);

  final PlaylistsRepository _repository;

  ResultFuture<Playlist> call({
    required String name,
    required String description,
    String? coverImageUrl,
    bool isPublic = false,
  }) async {
    try {
      final Playlist playlist = await _repository.createPlaylist(
        name: name,
        description: description,
        coverImageUrl: coverImageUrl,
        isPublic: isPublic,
      );
      return Right(playlist);
    } catch (e) {
      return Left(AudioFailure(e.toString()));
    }
  }
}
