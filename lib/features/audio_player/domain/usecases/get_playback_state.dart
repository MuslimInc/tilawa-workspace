import 'package:muzakri/core/entities/audio.dart';
import 'package:muzakri/core/utils/typedefs.dart';
import 'package:muzakri/features/audio_player/domain/repositories/audio_player_repository.dart';

class GetPlaybackState {
  const GetPlaybackState(this._repository);

  final AudioPlayerRepository _repository;

  ResultFuture<PlaybackStateEntity> call() async {
    return await _repository.getPlaybackState();
  }
}
