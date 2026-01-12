import 'package:dartz_plus/dartz_plus.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/core.dart';
import '../repositories/prayer_times_repository.dart';

@injectable
class GetCurrentLocationUseCase {
  GetCurrentLocationUseCase(this._repository);

  final PrayerTimesRepository _repository;

  Future<Either<Failure, LocationResult>> call() async {
    try {
      final bool hasPermission = await _repository.hasLocationPermission();

      if (!hasPermission) {
        final bool granted = await _repository.requestLocationPermission();
        if (!granted) {
          return Left(Failure.permissionDenied('Location permission denied'));
        }
      }

      final LocationResult location = await _repository.getCurrentLocation();

      if (location.hasError) {
        return Left(Failure.unexpectedError(location.error!));
      }

      return Right(location);
    } catch (e) {
      return Left(Failure.unexpectedError(e.toString()));
    }
  }
}
