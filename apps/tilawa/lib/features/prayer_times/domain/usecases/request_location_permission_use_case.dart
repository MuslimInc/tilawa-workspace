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
      // Explicit user action: allow opening app settings when permanently
      // denied so the user can re-grant permission.
      final bool granted = await _repository.requestLocationPermission(
        allowOpenSettings: true,
      );
      return Right(granted);
    } catch (e) {
      return Left(Failure.unexpectedError(e.toString()));
    }
  }
}
