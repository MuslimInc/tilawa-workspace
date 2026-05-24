import 'package:injectable/injectable.dart';

import '../repositories/tour_repository.dart';

@injectable
class ResetAllTours {
  ResetAllTours(this._repository);

  final TourRepository _repository;

  Future<void> call() => _repository.resetAllTours();
}
