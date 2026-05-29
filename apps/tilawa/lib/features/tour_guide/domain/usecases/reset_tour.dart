import 'package:injectable/injectable.dart';

import '../repositories/tour_repository.dart';

@injectable
class ResetTour {
  ResetTour(this._repository);

  final TourRepository _repository;

  Future<void> call(String tourId) => _repository.resetTour(tourId);
}
