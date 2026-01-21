import 'package:dartz_plus/dartz_plus.dart';
import 'package:injectable/injectable.dart';

import 'package:tilawa_core/core.dart';
import '../entities/entities.dart';
import '../repositories/prayer_times_repository.dart';

@injectable
class SavePrayerSettingsUseCase {
  SavePrayerSettingsUseCase(this._repository);

  final PrayerTimesRepository _repository;

  Future<Either<Failure, void>> call({
    required PrayerSettingsEntity settings,
  }) async {
    try {
      await _repository.saveSettings(settings);
      return const Right(null);
    } catch (e) {
      return Left(Failure.unexpectedError(e.toString()));
    }
  }
}
