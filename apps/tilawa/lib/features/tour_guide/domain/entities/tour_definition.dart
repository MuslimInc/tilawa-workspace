import 'package:equatable/equatable.dart';

import 'tour_step.dart';

/// Declarative description of a multi-step in-app tour.
///
/// Register instances in [TourGuideModule] (or feature modules) and trigger
/// them with [TourGuideService.tryShowTour].
class TourDefinition extends Equatable {
  const TourDefinition({
    required this.id,
    required this.steps,
    this.version = 1,
  });

  /// Stable tour id — used for persistence keys (do not rename after release).
  final String id;

  final List<TourStep> steps;

  /// Bump to re-show the tour after copy or step changes.
  final int version;

  @override
  List<Object?> get props => <Object?>[id, steps, version];
}
