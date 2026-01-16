import 'package:dartz_plus/dartz_plus.dart';

import 'package:tilawa_core/entities/audio.dart';
import 'package:tilawa_core/utils/typedefs.dart';
import '../repositories/audio_player_repository.dart';

class GetPlaybackStateUseCase {
  const GetPlaybackStateUseCase(this._repository);

  final AudioPlayerRepository _repository;

  ResultFuture<PlaybackStateEntity> call() async {
    return Right(_repository.getPlaybackState);
  }
}
