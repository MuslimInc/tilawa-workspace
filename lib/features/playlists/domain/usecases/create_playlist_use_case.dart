import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:muzakri/core/errors/failures.dart';
import 'package:muzakri/core/utils/typedefs.dart';
import 'package:muzakri/features/playlists/domain/entities/playlist.dart';
import 'package:muzakri/features/playlists/domain/repositories/playlists_repository.dart';

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
      final playlist = await _repository.createPlaylist(
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
