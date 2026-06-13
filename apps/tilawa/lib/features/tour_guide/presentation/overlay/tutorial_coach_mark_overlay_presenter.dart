import 'dart:async';

import 'package:flutter/material.dart';
import 'package:injectable/injectable.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

import '../../domain/entities/tour_content_align.dart';
import '../../domain/entities/tour_target_shape.dart';
import 'tour_overlay_presenter.dart';
import '../widgets/tour_tooltip_card.dart';

/// [TourOverlayPresenter] backed by `tutorial_coach_mark`.
@LazySingleton(as: TourOverlayPresenter)
class TutorialCoachMarkOverlayPresenter implements TourOverlayPresenter {
  TutorialCoachMark? _coach;

  @override
  Future<void> show({
    required BuildContext context,
    required List<TourOverlayStep> steps,
    required TourOverlayStyle style,
    required VoidCallback onFinish,
    required VoidCallback onSkip,
  }) async {
    dismiss();

    final Completer<void> overlayDone = Completer<void>();

    final List<TargetFocus> targets = <TargetFocus>[];
    for (final TourOverlayStep step in steps) {
      targets.add(_buildTarget(step: step));
    }

    void completeOverlay() {
      if (!overlayDone.isCompleted) {
        overlayDone.complete();
      }
    }

    _coach = TutorialCoachMark(
      targets: targets,
      colorShadow: style.shadowColor,
      opacityShadow: style.shadowOpacity,
      paddingFocus: style.focusPadding,
      useSafeArea: style.useSafeArea,
      hideSkip: true,
      onFinish: () {
        onFinish();
        completeOverlay();
      },
      onSkip: () {
        onSkip();
        completeOverlay();
        return true;
      },
    );

    _coach!.show(context: context);
    await overlayDone.future;
  }

  @override
  void dismiss() {
    _coach?.finish();
    _coach = null;
  }

  TargetFocus _buildTarget({required TourOverlayStep step}) {
    return TargetFocus(
      identify: step.identify,
      keyTarget: step.targetKey,
      enableTargetTab: step.enableTargetTap,
      shape: _mapShape(step.targetShape),
      contents: <TargetContent>[
        TargetContent(
          align: _mapAlign(step.contentAlign),
          builder:
              (BuildContext context, TutorialCoachMarkController controller) {
                return TourTooltipCard(
                  title: step.title,
                  description: step.description,
                  stepSemanticsLabel: step.stepSemanticsLabel,
                  primaryActionLabel: step.isLastStep
                      ? step.finishLabel
                      : step.nextLabel,
                  onPrimaryAction: () {
                    controller.next();
                  },
                  skipLabel: step.skipLabel,
                  onSkip: controller.skip,
                  showSkip: true,
                );
              },
        ),
      ],
    );
  }

  ContentAlign _mapAlign(TourContentAlign align) {
    return switch (align) {
      TourContentAlign.top ||
      TourContentAlign.topLeft ||
      TourContentAlign.topRight => ContentAlign.top,
      TourContentAlign.bottom ||
      TourContentAlign.bottomLeft ||
      TourContentAlign.bottomRight => ContentAlign.bottom,
      TourContentAlign.left => ContentAlign.left,
      TourContentAlign.right => ContentAlign.right,
    };
  }

  ShapeLightFocus _mapShape(TourTargetShape shape) {
    return switch (shape) {
      TourTargetShape.circle => ShapeLightFocus.Circle,
      TourTargetShape.roundedRectangle => ShapeLightFocus.RRect,
    };
  }
}
