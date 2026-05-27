import 'package:injectable/injectable.dart';

import '../../domain/entities/tour_definition.dart';
import '../../domain/services/tour_catalog.dart';

/// Aggregates all [TourDefinition] instances registered in DI.
@LazySingleton(as: TourCatalog)
class AppTourCatalog implements TourCatalog {
  AppTourCatalog(List<TourDefinition> definitions)
    : _definitions = definitions,
      _byId = <String, TourDefinition>{
        for (final TourDefinition definition in definitions)
          definition.id: definition,
      };

  final List<TourDefinition> _definitions;
  final Map<String, TourDefinition> _byId;

  @override
  TourDefinition? getDefinition(String tourId) => _byId[tourId];

  @override
  Iterable<TourDefinition> get definitions => _definitions;
}
