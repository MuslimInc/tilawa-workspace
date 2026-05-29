import 'package:injectable/injectable.dart';

import '../entities/player_background_configuration.dart';
import '../repositories/player_background_repository.dart';

/// Restores [PlayerBackgroundConfiguration] from hydrated Bloc storage JSON.
@injectable
class DecodePersistedPlayerBackgroundUseCase {
  const DecodePersistedPlayerBackgroundUseCase(this._repository);

  final PlayerBackgroundRepository _repository;

  PlayerBackgroundConfiguration call(Map<String, dynamic> json) {
    return _repository.decodePersistedConfiguration(json);
  }
}
