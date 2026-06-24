import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/material.dart' show Brightness, ColorScheme, Theme;
import 'package:flutter/widgets.dart';
import 'package:injectable/injectable.dart';

import '../../domain/entities/tour_definition.dart';
import '../../domain/entities/tour_step.dart';
import '../overlay/tour_overlay_presenter.dart';
import '../../domain/repositories/tour_repository.dart';
import '../../domain/services/tour_catalog.dart';
import '../../domain/services/tour_flow_guard.dart';
import '../../domain/services/tour_target_registry.dart';
import '../../domain/usecases/complete_tour.dart';
import 'tour_guide_labels.dart';

export '../overlay/tour_overlay_presenter.dart' show TourOverlayStyle;

/// Orchestrates when and how in-app tours are shown.
///
/// UI layers call [tryShowTour] with a [BuildContext] and tour id; widgets
/// register targets via [TourTarget] without importing coach-mark types.
@lazySingleton
class TourGuideService {
  TourGuideService(
    this._catalog,
    this._repository,
    this._registry,
    this._presenter,
    this._flowGuard,
    this._completeTour,
    this._labels,
  );

  final TourCatalog _catalog;
  final TourRepository _repository;
  final TourTargetRegistry _registry;
  final TourOverlayPresenter _presenter;
  final TourFlowGuard _flowGuard;
  final CompleteTour _completeTour;
  final TourGuideLabels _labels;

  String? _activeTourId;

  bool get isShowingTour => _activeTourId != null;

  /// Shows [tourId] when not completed, not blocked, and all targets exist.
  ///
  /// Pass [definition] for feature-local tours with localized copy; otherwise
  /// the tour is resolved from [TourCatalog].
  ///
  /// Set [force] to true to ignore completion (debug / settings replay).
  Future<bool> tryShowTour({
    required BuildContext context,
    required String tourId,
    TourDefinition? definition,
    bool force = false,
    TourOverlayStyle? style,
  }) async {
    if (_flowGuard.isBlocked) {
      return false;
    }
    if (isShowingTour) {
      return false;
    }

    final TourDefinition? resolved =
        definition ?? _catalog.getDefinition(tourId);
    if (resolved == null || resolved.steps.isEmpty) {
      developer.log(
        'Tour definition missing or empty: $tourId',
        name: 'tour_guide',
      );
      return false;
    }

    if (!force) {
      final record = await _repository.getCompletion(tourId);
      if (record.isSatisfiedBy(resolved.version)) {
        return false;
      }
    }

    if (!context.mounted) {
      return false;
    }

    final List<TourOverlayStep>? steps = _buildOverlaySteps(
      context: context,
      definition: resolved,
    );
    if (steps == null || steps.isEmpty) {
      return false;
    }

    _activeTourId = tourId;
    var tourEnded = false;

    Future<void> endTour() async {
      if (tourEnded) {
        return;
      }
      tourEnded = true;
      await _completeTour(tourId, version: resolved.version);
      _coachDismissOnly();
      _activeTourId = null;
    }

    try {
      final TourOverlayStyle resolvedStyle = style ?? _defaultStyle(context);
      await _presenter.show(
        context: context,
        steps: steps,
        style: resolvedStyle,
        onFinish: () => unawaited(endTour()),
        onSkip: () => unawaited(endTour()),
      );
      return true;
    } catch (e, s) {
      developer.log(
        'Failed to show tour $tourId',
        name: 'tour_guide',
        error: e,
        stackTrace: s,
      );
      _activeTourId = null;
      _presenter.dismiss();
      return false;
    }
  }

  Future<void> dismissActiveTour() async {
    if (_activeTourId == null) {
      return;
    }
    _coachDismissOnly();
    _activeTourId = null;
  }

  void _coachDismissOnly() {
    _presenter.dismiss();
  }

  List<TourOverlayStep>? _buildOverlaySteps({
    required BuildContext context,
    required TourDefinition definition,
  }) {
    final List<TourOverlayStep> built = <TourOverlayStep>[];
    final int count = definition.steps.length;

    for (var index = 0; index < count; index++) {
      final TourStep step = definition.steps[index];
      final GlobalKey? key = _registry.keyFor(step.targetId);
      if (key == null) {
        developer.log(
          'Tour target not registered: ${step.targetId}',
          name: 'tour_guide',
        );
        return null;
      }

      built.add(
        TourOverlayStep(
          identify: step.id,
          targetKey: key,
          title: step.title,
          description: step.description,
          contentAlign: step.contentAlign,
          targetShape: step.targetShape,
          enableTargetTap: step.enableTargetTap,
          isLastStep: index == count - 1,
          stepIndex: index,
          stepCount: count,
          nextLabel: _labels.next(context),
          skipLabel: _labels.skip(context),
          finishLabel: _labels.finish(context),
          stepSemanticsLabel: _labels.stepSemantics(
            context,
            current: index + 1,
            total: count,
          ),
        ),
      );
    }
    return built;
  }

  TourOverlayStyle _defaultStyle(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return TourOverlayStyle(
      shadowColor: scheme.brightness == Brightness.dark
          ? scheme.scrim
          : scheme.onSurface,
      shadowOpacity: 0.72,
      focusPadding: 8,
      useSafeArea: true,
    );
  }
}
