import 'package:dartz_plus/dartz_plus.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/core.dart';
import '../entities/entities.dart';
import '../repositories/prayer_times_repository.dart';

@injectable
class GetPrayerTimesUseCase {
  GetPrayerTimesUseCase(this._repository);

  final PrayerTimesRepository _repository;

  Future<Either<Failure, PrayerTimeEntity>> call({
    required double latitude,
    required double longitude,
    required DateTime date,
    required PrayerSettingsEntity settings,
  }) async {
    try {
      final PrayerTimeEntity prayerTimes = await _repository.getPrayerTimes(
        latitude: latitude,
        longitude: longitude,
        date: date,
        settings: settings,
      );
      return Right(prayerTimes);
    } catch (e) {
      return Left(Failure.unexpectedError(e.toString()));
    }
  }
}
