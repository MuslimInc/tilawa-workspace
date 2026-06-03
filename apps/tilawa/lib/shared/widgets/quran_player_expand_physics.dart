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
    bool interactiveDrag = false,

    /// Progress where collapse intent started during an interactive drag.
    /// Blends expand-forward and collapse metrics to avoid one-frame jumps.
    double? interactiveCollapseAnchor,
  }) {
    final double t = progress.clamp(0.0, 1.0);

    if (interactiveDrag) {
      return _computeInteractiveDragMetrics(
        progress: t,
        miniPlayerHeight: miniPlayerHeight,
        collapseAnchor: collapseBiased ? interactiveCollapseAnchor : null,
      );
    }

    const double expandedStart = 0.08;
    const double expandedFull = 0.48;
    const double queueStart = 0.86;
    const double sheetSettledExpanded = 0.98;

    final double miniOpacity;
    if (collapseBiased && !heroHandoff) {
      // Footer handoff after `/player` pops: mini returns as progress falls.
      const double miniHiddenAbove = 0.88;
      const double miniFullBelow = 0.22;
      if (t >= miniHiddenAbove) {
        miniOpacity = 0;
      } else if (t <= miniFullBelow) {
        miniOpacity = 1;
      } else {
        miniOpacity = Curves.easeInOut.transform(
          (miniHiddenAbove - t) / (miniHiddenAbove - miniFullBelow),
        );
      }
    } else {
      // YouTube Music: mini lingers while the sheet rides up; morph handles
      // artwork/title through mid-transition (not a hard cut at ~40%).
      final double miniFull = heroHandoff ? 0.10 : 0.06;
      final double miniGone = heroHandoff ? 0.82 : 0.78;
      miniOpacity = t >= miniGone
          ? 0
          : t <= miniFull
          ? 1
          : Curves.easeInOut.transform(
              (miniGone - t) / (miniGone - miniFull),
            );
    }

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
      // Track progress but ease out opacity near fully expanded so the sheet
      // does not read as a solid panel during the first collapse frames.
      sheetTravelDim = t * (0.25 + 0.75 * t);
    } else if (t >= sheetSettledExpanded) {
      sheetTravelDim = 1;
    } else {
      // YouTube Music: feed stays visible; panel fill follows the finger and
      // only becomes solid near the top (no opaque half-screen block at t≈0.5).
      const double sheetOpaqueFrom = 0.90;
      sheetTravelDim = Curves.easeIn.transform(
        (t / sheetOpaqueFrom).clamp(0.0, 1.0),
      );
    }
    final double sheetPresentationOpacity =
        (expandedOpacity * sheetTravelDim).clamp(0.0, 1.0);

    // Dim scrim only — never paint an opaque surface backdrop during the
    // transition (that reads as a full-height white flash while collapsing).
    final double scrimBase = collapseBiased
        ? (t * (0.12 + 0.38 * expandedOpacity)).clamp(0.0, 0.5)
        : (0.45 * Curves.easeIn.transform(t)).clamp(0.0, 0.45);
    final double scrimOpacity = collapseBiased
        ? (scrimBase * Curves.easeIn.transform(t)).clamp(0.0, 0.5)
        : scrimBase;

    const double backdropOpacity = 0;

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
      showExpandedSheet: t > 0.001 &&
          sheetPresentationOpacity > 0.08 &&
          (!collapseBiased || t > 0.74),
      showMorphLayer: effectiveHandoffT > 0.02,
    );
  }

  /// Finger-driven expand/collapse — linear sheet travel (1:1 with finger).
  static PlayerExpandTransitionMetrics _computeInteractiveDragMetrics({
    required double progress,
    required double miniPlayerHeight,
    double? collapseAnchor,
  }) {
    final PlayerExpandTransitionMetrics expandForward =
        _computeInteractiveExpandForwardMetrics(
      progress: progress,
      miniPlayerHeight: miniPlayerHeight,
    );

    final double? anchor = collapseAnchor;
    if (anchor == null || progress >= anchor - 0.001) {
      return expandForward;
    }

    final PlayerExpandTransitionMetrics collapse =
        _computeInteractiveCollapseDragMetrics(
      progress: progress,
      miniPlayerHeight: miniPlayerHeight,
    );

    const double blendSpan = 0.35;
    final double blend = Curves.easeInOut.transform(
      ((anchor - progress) / blendSpan).clamp(0.0, 1.0),
    );
    return _lerpTransitionMetrics(expandForward, collapse, blend);
  }

  static PlayerExpandTransitionMetrics _computeInteractiveExpandForwardMetrics({
    required double progress,
    required double miniPlayerHeight,
  }) {
    final double t = progress.clamp(0.0, 1.0);

    const double miniFull = 0.06;
    const double miniGone = 0.78;
    final double miniOpacity = t >= miniGone
        ? 0
        : t <= miniFull
        ? 1
        : Curves.easeInOut.transform(
            (miniGone - t) / (miniGone - miniFull),
          );

    const double expandedStart = 0.08;
    const double expandedFull = 0.48;
    final double expandedOpacity = t <= expandedStart
        ? 0
        : t >= expandedFull
        ? 1
        : Curves.easeOut.transform(
            (t - expandedStart) / (expandedFull - expandedStart),
          );

    const double sheetOpaqueFrom = 0.90;
    final double sheetTravelDim = Curves.easeIn.transform(
      (t / sheetOpaqueFrom).clamp(0.0, 1.0),
    );
    final double sheetPresentationOpacity =
        (expandedOpacity * sheetTravelDim).clamp(0.0, 1.0);

    final double miniSlideY = (1 - miniOpacity) * miniPlayerHeight * 0.2;
    final double scrimOpacity = (0.45 * Curves.easeIn.transform(t)).clamp(
      0.0,
      0.45,
    );

    return PlayerExpandTransitionMetrics(
      miniOpacity: miniOpacity,
      expandedOpacity: expandedOpacity,
      handoffT: 0,
      stageChromeOpacity: 1,
      miniIdentityOpacity: miniOpacity,
      sheetPresentationOpacity: sheetPresentationOpacity,
      backdropOpacity: 0,
      scrimOpacity: scrimOpacity,
      miniSlideY: miniSlideY,
      sheetMotionT: t,
      queueChromeT: 0,
      showMiniPlayer: miniOpacity > 0.08,
      showExpandedSheet: t > 0.001 && sheetPresentationOpacity > 0.08,
      showMorphLayer: false,
    );
  }

  /// Collapse-intent drag metrics with linear sheet travel (no path flip).
  static PlayerExpandTransitionMetrics _computeInteractiveCollapseDragMetrics({
    required double progress,
    required double miniPlayerHeight,
  }) {
    final double t = progress.clamp(0.0, 1.0);
    final PlayerExpandTransitionMetrics settled =
        PlayerExpandTransitionMetrics.compute(
      progress: t,
      miniPlayerHeight: miniPlayerHeight,
      collapseBiased: true,
    );

    // Ramp morph fades during finger-driven collapse (no step at ~0.78).
    final double morphBlend = _interactiveCollapseMorphBlend(t);
    final double handoffT = settled.handoffT * morphBlend;
    final double stageChromeOpacity =
        1 + (settled.stageChromeOpacity - 1) * morphBlend;

    return PlayerExpandTransitionMetrics(
      miniOpacity: settled.miniOpacity,
      expandedOpacity: settled.expandedOpacity,
      handoffT: handoffT,
      stageChromeOpacity: stageChromeOpacity,
      miniIdentityOpacity:
          1 + (settled.miniIdentityOpacity - 1) * morphBlend,
      sheetPresentationOpacity: settled.sheetPresentationOpacity,
      backdropOpacity: settled.backdropOpacity,
      scrimOpacity: settled.scrimOpacity,
      miniSlideY: settled.miniSlideY,
      sheetMotionT: t,
      queueChromeT: settled.queueChromeT,
      showMiniPlayer: settled.miniOpacity > 0.08,
      showExpandedSheet:
          t > 0.001 && settled.sheetPresentationOpacity > 0.08 && t > 0.74,
      showMorphLayer: handoffT > 0.02,
    );
  }

  /// 0 above [high], 1 below [low], eased between (interactive collapse drag).
  static double _interactiveCollapseMorphBlend(
    double progress, {
    double high = 0.90,
    double low = 0.42,
  }) {
    final double t = progress.clamp(0.0, 1.0);
    if (t >= high) {
      return 0;
    }
    if (t <= low) {
      return 1;
    }
    return Curves.easeInOut.transform((high - t) / (high - low));
  }

  static PlayerExpandTransitionMetrics _lerpTransitionMetrics(
    PlayerExpandTransitionMetrics a,
    PlayerExpandTransitionMetrics b,
    double t,
  ) {
    double lerp(double x, double y) => x + (y - x) * t;
    final double miniOpacity = lerp(a.miniOpacity, b.miniOpacity);
    final double sheetPresentationOpacity = lerp(
      a.sheetPresentationOpacity,
      b.sheetPresentationOpacity,
    );
    return PlayerExpandTransitionMetrics(
      miniOpacity: miniOpacity,
      expandedOpacity: lerp(a.expandedOpacity, b.expandedOpacity),
      handoffT: lerp(a.handoffT, b.handoffT),
      stageChromeOpacity: lerp(a.stageChromeOpacity, b.stageChromeOpacity),
      miniIdentityOpacity: lerp(a.miniIdentityOpacity, b.miniIdentityOpacity),
      sheetPresentationOpacity: sheetPresentationOpacity,
      backdropOpacity: lerp(a.backdropOpacity, b.backdropOpacity),
      scrimOpacity: lerp(a.scrimOpacity, b.scrimOpacity),
      miniSlideY: lerp(a.miniSlideY, b.miniSlideY),
      sheetMotionT: lerp(a.sheetMotionT, b.sheetMotionT),
      queueChromeT: lerp(a.queueChromeT, b.queueChromeT),
      showMiniPlayer: miniOpacity > 0.08,
      showExpandedSheet:
          sheetPresentationOpacity > 0.08 && lerp(a.sheetMotionT, b.sheetMotionT) > 0.001,
      showMorphLayer: lerp(a.handoffT, b.handoffT) > 0.02,
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
