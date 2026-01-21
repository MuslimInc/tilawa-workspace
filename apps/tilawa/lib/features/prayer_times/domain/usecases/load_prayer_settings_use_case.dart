import 'package:dartz_plus/dartz_plus.dart';
import 'package:injectable/injectable.dart';

import 'package:tilawa_core/core.dart';
import '../entities/entities.dart';
import '../repositories/prayer_times_repository.dart';

@injectable
class LoadPrayerSettingsUseCase {
  LoadPrayerSettingsUseCase(this._repository);

  final PrayerTimesRepository _repository;

  Future<Either<Failure, PrayerSettingsEntity>> call() async {
    try {
      final PrayerSettingsEntity settings = await _repository.loadSettings();
      return Right(settings);
    } catch (e) {
      return Left(Failure.unexpectedError(e.toString()));
    }
  }
}
