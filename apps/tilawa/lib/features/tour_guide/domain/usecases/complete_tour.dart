import 'package:injectable/injectable.dart';

import '../repositories/tour_repository.dart';
import '../services/tour_catalog.dart';

@injectable
class CompleteTour {
  CompleteTour(this._repository, this._catalog);

  final TourRepository _repository;
  final TourCatalog _catalog;

  Future<void> call(String tourId, {int? version}) async {
    final int? resolvedVersion =
        version ?? _catalog.getDefinition(tourId)?.version;
    if (resolvedVersion == null) {
      return;
    }
    await _repository.markCompleted(
      tourId: tourId,
      version: resolvedVersion,
    );
  }
}
