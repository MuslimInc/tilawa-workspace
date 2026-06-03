import 'package:dartz_plus/dartz_plus.dart';
import 'package:injectable/injectable.dart';
import 'package:tilawa_core/core.dart';

import '../repositories/prayer_times_repository.dart';

/// Whether the app may read the device location for prayer times.
@injectable
class CheckLocationPermissionUseCase {
  const CheckLocationPermissionUseCase(this._repository);

  final PrayerTimesRepository _repository;

  Future<Either<Failure, bool>> call() async {
    try {
      final bool granted = await _repository.hasLocationPermission();
      return Right(granted);
    } catch (e) {
      return Left(Failure.unexpectedError(e.toString()));
    }
  }
}
