import 'package:injectable/injectable.dart';

import '../repositories/prayer_times_repository.dart';

@injectable
class GetLocationNameUseCase {
  GetLocationNameUseCase(this._repository);

  final PrayerTimesRepository _repository;

  Future<String?> call({
    required double latitude,
    required double longitude,
    String? localeIdentifier,
  }) {
    return _repository.getLocationName(
      latitude: latitude,
      longitude: longitude,
      localeIdentifier: localeIdentifier,
    );
  }
}
