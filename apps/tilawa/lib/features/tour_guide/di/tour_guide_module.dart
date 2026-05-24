import 'package:injectable/injectable.dart';

import '../domain/entities/tour_definition.dart';

/// Registers tour definitions from features.
///
/// Add new tours by appending to [provideTourDefinitions] or splitting into
/// feature-specific modules that export lists merged here.
@module
abstract class TourGuideModule {
  @lazySingleton
  List<TourDefinition> provideTourDefinitions() => const <TourDefinition>[];
}
