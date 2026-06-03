import 'package:dartz_plus/dartz_plus.dart';
import 'package:injectable/injectable.dart';
import 'package:tilawa_core/utils/typedefs.dart';

import '../entities/active_playback_snapshot.dart';
import '../repositories/audio_player_repository.dart';

/// Reads the live handler session (survives Flutter hot restart).
@injectable
class SyncActivePlaybackFromHandlerUseCase {
  const SyncActivePlaybackFromHandlerUseCase(this._repository);

  final AudioPlayerRepository _repository;

  ResultFuture<ActivePlaybackSnapshot?> call() async {
    return Right(_repository.readActivePlaybackSnapshot());
  }
}
