import 'package:dartz_plus/dartz_plus.dart';
import 'package:injectable/injectable.dart';
import 'package:tilawa_core/core.dart';

import '../repositories/prayer_times_repository.dart';

/// Requests location access for automatic prayer-time calculation.
@injectable
class RequestLocationPermissionUseCase {
  const RequestLocationPermissionUseCase(this._repository);

  final PrayerTimesRepository _repository;

  Future<Either<Failure, bool>> call() async {
    try {
      final bool granted = await _repository.requestLocationPermission();
      return Right(granted);
    } catch (e) {
      return Left(Failure.unexpectedError(e.toString()));
    }
  }
}
