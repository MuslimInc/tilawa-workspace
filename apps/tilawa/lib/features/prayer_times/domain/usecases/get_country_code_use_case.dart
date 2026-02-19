import 'package:injectable/injectable.dart';

import '../repositories/prayer_times_repository.dart';

@injectable
class GetCountryCodeUseCase {
  GetCountryCodeUseCase(this._repository);

  final PrayerTimesRepository _repository;

  Future<String?> call({
    required double latitude,
    required double longitude,
  }) async {
    return _repository.getCountryCode(latitude: latitude, longitude: longitude);
  }
}
