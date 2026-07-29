import 'package:get_it/get_it.dart';
import 'package:tilawa/core/di/get_it_idempotent.dart';
import 'package:tilawa/shared/audio/audio_player_handler.dart';
import 'package:tilawa/shared/services/audio_position_service.dart';

/// Manual GetIt registrations for `shared`.
class SharedDi {
  SharedDi._();

  static void register(GetIt getIt) {
    getIt.registerLazySingletonIfAbsent<AudioPositionService>(
      () => AudioPositionServiceImpl(getIt<AudioPlayerHandler>()),
    );
  }
}
