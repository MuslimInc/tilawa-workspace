import 'package:dartz_plus/dartz_plus.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/core.dart';
import '../entities/entities.dart';
import '../repositories/prayer_times_repository.dart';

@injectable
class GetMonthlyPrayerTimesUseCase {
  GetMonthlyPrayerTimesUseCase(this._repository);

  final PrayerTimesRepository _repository;

  Future<Either<Failure, List<PrayerTimeEntity>>> call({
    required double latitude,
    required double longitude,
    required int year,
    required int month,
    required PrayerSettingsEntity settings,
  }) async {
    try {
      final List<PrayerTimeEntity> prayerTimes = await _repository
          .getMonthlyPrayerTimes(
            latitude: latitude,
            longitude: longitude,
            year: year,
            month: month,
            settings: settings,
          );
      return Right(prayerTimes);
    } catch (e) {
      return Left(Failure.unexpectedError(e.toString()));
    }
  }
}
