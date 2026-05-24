import 'package:injectable/injectable.dart';

import '../repositories/tour_repository.dart';
import '../services/tour_catalog.dart';

/// Returns whether a tour should be skipped for the current definition version.
@injectable
class IsTourCompleted {
  IsTourCompleted(this._repository, this._catalog);

  final TourRepository _repository;
  final TourCatalog _catalog;

  Future<bool> call(String tourId) async {
    final definition = _catalog.getDefinition(tourId);
    if (definition == null) {
      return true;
    }
    final record = await _repository.getCompletion(tourId);
    return record.isSatisfiedBy(definition.version);
  }
}
