import '../entities/tour_definition.dart';

/// Read-only registry of tours available in the app.
abstract interface class TourCatalog {
  TourDefinition? getDefinition(String tourId);

  Iterable<TourDefinition> get definitions;
}
