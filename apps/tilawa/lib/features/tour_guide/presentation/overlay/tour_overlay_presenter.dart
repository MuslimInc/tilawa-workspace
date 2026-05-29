import 'package:flutter/widgets.dart';

import '../../domain/entities/tour_content_align.dart';
import '../../domain/entities/tour_target_shape.dart';

/// Description of one coach-mark overlay step (presentation layer).
class TourOverlayStep {
  const TourOverlayStep({
    required this.identify,
    required this.targetKey,
    required this.title,
    required this.description,
    required this.contentAlign,
    required this.targetShape,
    required this.enableTargetTap,
    required this.isLastStep,
    required this.stepIndex,
    required this.stepCount,
    required this.nextLabel,
    required this.skipLabel,
    required this.finishLabel,
    required this.stepSemanticsLabel,
  });

  final String identify;
  final GlobalKey targetKey;
  final String title;
  final String description;
  final TourContentAlign contentAlign;
  final TourTargetShape targetShape;
  final bool enableTargetTap;
  final bool isLastStep;
  final int stepIndex;
  final int stepCount;
  final String nextLabel;
  final String skipLabel;
  final String finishLabel;
  final String stepSemanticsLabel;
}

/// Visual configuration for the tour overlay scrim and focus ring.
class TourOverlayStyle {
  const TourOverlayStyle({
    required this.shadowColor,
    required this.shadowOpacity,
    required this.focusPadding,
    required this.useSafeArea,
  });

  final Color shadowColor;
  final double shadowOpacity;
  final double focusPadding;
  final bool useSafeArea;
}

/// Abstraction over `tutorial_coach_mark` (or any overlay implementation).
abstract interface class TourOverlayPresenter {
  Future<void> show({
    required BuildContext context,
    required List<TourOverlayStep> steps,
    required TourOverlayStyle style,
    required VoidCallback onFinish,
    required VoidCallback onSkip,
  });

  void dismiss();
}
