import 'package:equatable/equatable.dart';

import 'tour_content_align.dart';
import 'tour_target_shape.dart';

/// A single step in a product tour — copy and target id only (no Flutter types).
class TourStep extends Equatable {
  const TourStep({
    required this.id,
    required this.targetId,
    required this.title,
    required this.description,
    this.contentAlign = TourContentAlign.bottom,
    this.targetShape = TourTargetShape.roundedRectangle,
    this.enableTargetTap = false,
  });

  /// Stable step id within the parent [TourDefinition].
  final String id;

  /// Key registered via [TourTarget] / [TourTargetRegistry].
  final String targetId;

  final String title;
  final String description;
  final TourContentAlign contentAlign;
  final TourTargetShape targetShape;

  /// When true, tapping the highlighted widget advances the tour.
  final bool enableTargetTap;

  @override
  List<Object?> get props => <Object?>[
    id,
    targetId,
    title,
    description,
    contentAlign,
    targetShape,
    enableTargetTap,
  ];
}
