import 'package:injectable/injectable.dart';

import '../entities/player_background_configuration.dart';
import '../repositories/player_background_repository.dart';

/// Serializes [PlayerBackgroundConfiguration] for hydrated Bloc storage.
@injectable
class EncodePlayerBackgroundConfigurationUseCase {
  const EncodePlayerBackgroundConfigurationUseCase(this._repository);

  final PlayerBackgroundRepository _repository;

  Map<String, dynamic> call(PlayerBackgroundConfiguration config) {
    return _repository.encodeConfiguration(config);
  }
}
