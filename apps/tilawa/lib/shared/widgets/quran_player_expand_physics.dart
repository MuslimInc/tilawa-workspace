import 'dart:math' as math;

import 'package:flutter/animation.dart';
import 'package:meta/meta.dart';

/// Pure helpers for Quran player expand/collapse drag and release snapping.
abstract final class QuranPlayerExpandPhysics {
  /// Screen travel (px) for a full 0→1 expand gesture at [dragSensitivity].
  static double travelPixels(double viewportHeight, double dragSensitivity) {
    if (viewportHeight <= 0 || dragSensitivity <= 0) {
      return 1;
    }
    return viewportHeight / dragSensitivity;
  }

  /// Applies a vertical drag in logical pixels.
  ///
  /// [dragPixels] > 0 when the finger moves down (collapse). [rubberBandExtent]
  /// is the fraction past 0/1 that resists overscroll (calm, not bouncy).
  static double applyDragDelta({
    required double current,
    required double dragPixels,
    required double travelPixels,
    double rubberBandExtent = 0.08,
  }) {
    if (travelPixels <= 0) {
      return current.clamp(0.0, 1.0);
    }
    final double raw = current - dragPixels / travelPixels;
    return _rubberBandClamp(raw, rubberBandExtent);
  }

  static double _rubberBandClamp(double value, double extent) {
    if (value >= 0 && value <= 1) {
      return value;
    }
    if (extent <= 0) {
      return value.clamp(0.0, 1.0);
    }
    if (value < 0) {
      return -(_rubberBandOverscroll(-value, extent));
    }
    return 1 + _rubberBandOverscroll(value - 1, extent);
  }

  /// Diminishing overscroll past 0 or 1 (no spring oscillation).
  static double _rubberBandOverscroll(double overscroll, double extent) {
    return extent * (1 - 1 / (1 + overscroll / extent));
  }

  /// Resolves whether the sheet should settle expanded or collapsed.
  ///
  /// [primaryVelocity] follows Flutter: positive when the finger moves down.
  /// [netDragDy] > 0 means the finger moved down overall (minimize intent).
  static PlayerExpandSnapTarget resolveSnap({
    required double progress,
    required double primaryVelocity,
    required double progressThreshold,
    required double velocityThreshold,
    double netDragDy = 0,
    double netDragBiasThreshold = 28,
    double collapseVelocityFactor = 0.72,
  }) {
    final double upwardVelocity = -primaryVelocity;

    if (upwardVelocity > velocityThreshold) {
      return PlayerExpandSnapTarget.expand;
    }
    if (upwardVelocity < -velocityThreshold * collapseVelocityFactor) {
      return PlayerExpandSnapTarget.collapse;
    }

    final bool collapseIntent =
        netDragDy > netDragBiasThreshold;
    final bool expandIntent =
        netDragDy < -netDragBiasThreshold;

    if (collapseIntent && !expandIntent) {
      return PlayerExpandSnapTarget.collapse;
    }
    if (expandIntent && !collapseIntent) {
      return PlayerExpandSnapTarget.expand;
    }

    if (progress >= progressThreshold) {
      return PlayerExpandSnapTarget.expand;
    }
    return PlayerExpandSnapTarget.collapse;
  }
}

/// Visual layering for expand/collapse (mini vs expanded vs queue chrome).
@immutable
class PlayerExpandTransitionMetrics {
  const PlayerExpandTransitionMetrics({
    required this.miniOpacity,
    required this.expandedOpacity,
    required this.handoffT,
    required this.stageChromeOpacity,
    required this.miniIdentityOpacity,
    required this.sheetPresentationOpacity,
    required this.backdropOpacity,
    required this.scrimOpacity,
    required this.miniSlideY,
    required this.sheetMotionT,
    required this.queueChromeT,
    required this.showMiniPlayer,
    required this.showExpandedSheet,
    required this.showMorphLayer,
  });

  final double miniOpacity;
  final double expandedOpacity;

  /// Strength of the shared morph overlay (artwork + title flight).
  final double handoffT;

  /// Opacity for expanded-stage artwork + centered metadata.
  final double stageChromeOpacity;

  /// Opacity for mini-bar artwork + title (controls stay visible).
  final double miniIdentityOpacity;

  /// Opacity applied to the sliding expanded sheet (fades with [sheetMotionT]
  /// during collapse so a partially translated sheet is not fully opaque).
  final double sheetPresentationOpacity;

  /// Full-screen surface fill behind the sheet (fades with collapse drag).
  final double backdropOpacity;

  final double scrimOpacity;
  final double miniSlideY;
  final double sheetMotionT;
  final double queueChromeT;
  final bool showMiniPlayer;
  final bool showExpandedSheet;
  final bool showMorphLayer;

  /// Bell-shaped morph strength (0 at settled mini/expanded).
  static double computeHandoffT(double progress) {
    final double t = progress.clamp(0.0, 1.0);
    if (t <= 0.03 || t >= 0.97) {
      return 0;
    }
    const double start = 0.05;
    const double end = 0.95;
    final double u = ((t - start) / (end - start)).clamp(0.0, 1.0);
    return math.sin(u * math.pi);
  }

  /// Staggered crossfade so mini, expanded stage, and queue never stack loudly.
  ///
  /// When [collapseBiased] is true (route collapse), sheet opacity tracks
  /// [progress] so the panel stays visible at the start of the reverse
  /// animation and dims with the Hero handoff (no one-frame flash at t≈1).
  ///
  /// When [heroHandoff] is true, the footer mini lingers longer so artwork
  /// and metadata can complete their Hero flight before the bar fades.
  static PlayerExpandTransitionMetrics compute({
    required double progress,
    required double miniPlayerHeight,
    bool collapseBiased = false,
    bool heroHandoff = false,
  }) {
    final double t = progress.clamp(0.0, 1.0);

    // Hero handoff: keep footer mini visible until the flight is mostly done.
    final double miniFull = heroHandoff ? 0.10 : 0.08;
    final double miniGone = heroHandoff ? 0.82 : 0.42;
    const double expandedStart = 0.08;
    const double expandedFull = 0.48;
    const double queueStart = 0.86;
    const double sheetSettledExpanded = 0.98;

    final double miniOpacity = t >= miniGone
        ? 0
        : t <= miniFull
        ? 1
        : Curves.easeInOut.transform((miniGone - t) / (miniGone - miniFull));

    final double expandedOpacity = t <= expandedStart
        ? 0
        : t >= expandedFull
        ? 1
        : Curves.easeOut.transform(
            (t - expandedStart) / (expandedFull - expandedStart),
          );

    final double miniSlideY = (1 - miniOpacity) * miniPlayerHeight * 0.2;

    // Linear travel tracks finger distance; easing is only for programmatic runs.
    final double sheetMotionT = t;

    final double sheetTravelDim;
    if (collapseBiased) {
      sheetTravelDim = t;
    } else if (t >= sheetSettledExpanded) {
      sheetTravelDim = 1;
    } else {
      const double sheetFadeInBy = 0.58;
      sheetTravelDim = Curves.easeOut.transform(
        (t / sheetFadeInBy).clamp(0.0, 1.0),
      );
    }
    final double sheetPresentationOpacity =
        (expandedOpacity * sheetTravelDim).clamp(0.0, 1.0);

    // Keep a minimum dim while the expanded sheet is visible (avoids white flash).
    final double scrimBase =
        (t * (0.12 + 0.38 * expandedOpacity)).clamp(0.0, 0.5);
    final double scrimOpacity = collapseBiased
        ? (scrimBase * sheetTravelDim).clamp(0.0, 0.5)
        : scrimBase;

    final double backdropOpacity = collapseBiased
        ? (0.92 * sheetPresentationOpacity).clamp(0.0, 0.92)
        : (0.92 * expandedOpacity).clamp(0.0, 0.92);

    final double queueChromeT = t <= queueStart
        ? 0
        : Curves.easeOut.transform((t - queueStart) / (1 - queueStart));

    final double handoffT = collapseBiased
        ? _collapseHandoffT(t)
        : computeHandoffT(t);
    final double effectiveHandoffT = handoffT.clamp(0.0, 1.0);
    final double stageChromeOpacity =
        (1 - effectiveHandoffT * 0.98).clamp(0.0, 1.0);
    final double miniIdentityOpacity =
        (1 - effectiveHandoffT * 0.98).clamp(0.0, 1.0);

    return PlayerExpandTransitionMetrics(
      miniOpacity: miniOpacity,
      expandedOpacity: expandedOpacity,
      handoffT: effectiveHandoffT,
      stageChromeOpacity: stageChromeOpacity,
      miniIdentityOpacity: miniIdentityOpacity,
      sheetPresentationOpacity: sheetPresentationOpacity,
      backdropOpacity: backdropOpacity,
      scrimOpacity: scrimOpacity,
      miniSlideY: miniSlideY,
      sheetMotionT: sheetMotionT,
      queueChromeT: queueChromeT,
      showMiniPlayer: miniOpacity > 0.08,
      showExpandedSheet:
          t > 0.001 && sheetPresentationOpacity > 0.08,
      showMorphLayer: effectiveHandoffT > 0.02,
    );
  }

  /// Morph strength while collapsing from fully expanded (bell curve zeros
  /// near [progress] ≈ 1).
  static double _collapseHandoffT(double progress) {
    final double t = progress.clamp(0.0, 1.0);
    if (t <= expandedStart) {
      return computeHandoffT(t);
    }
    const double collapseMorphEnd = 0.90;
    if (t >= collapseMorphEnd) {
      return Curves.easeOut.transform(
        ((1 - t) / (1 - collapseMorphEnd)).clamp(0.0, 1.0),
      );
    }
    return computeHandoffT(t);
  }

  static const double expandedStart = 0.10;
}

/// Settled state after the user releases an expand/collapse drag.
enum PlayerExpandSnapTarget {
  expand,
  collapse,
}
