import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Scroll-position helpers and lock state for alphabet scrub on [RecitersScreen].
class RecitersAlphabetScrubCoordinator {
  RecitersAlphabetScrubCoordinator({
    required this._innerController,
    required this._primaryController,
  });

  final ScrollController? Function() _innerController;
  final ScrollController? Function() _primaryController;

  bool alphabetScrubbingActive = false;
  bool enforcingScrubLock = false;
  bool scrubOverscrollClampScheduled = false;

  ScrollPosition? scrubLockedCatalogPosition;
  double? scrubLockedCatalogOffset;
  ScrollPosition? scrubLockedHeaderPosition;
  double? scrubLockedHeaderOffset;
  ScrollPosition? trackedOuterScrollPosition;
  double? trackedOuterScrollPixels;
  Map<ScrollPosition, double> scrubAllPositionLocks =
      <ScrollPosition, double>{};
  double? scrubPinnedHeaderOffset;
  double? scrubPinnedCatalogOffset;

  void clearLockState() {
    scrubAllPositionLocks.clear();
    scrubPinnedHeaderOffset = null;
    scrubPinnedCatalogOffset = null;
    scrubLockedCatalogPosition = null;
    scrubLockedCatalogOffset = null;
    scrubLockedHeaderPosition = null;
    scrubLockedHeaderOffset = null;
  }

  void beginScrub() {
    alphabetScrubbingActive = true;
    clampNestedScrollOverscroll();
    captureScrubScrollLocks();
    scrubPinnedHeaderOffset =
        scrubLockedHeaderOffset ??
        trackedOuterScrollPixels ??
        scrubLockedHeaderPosition?.pixels ??
        0;
    scrubPinnedCatalogOffset = scrubLockedCatalogOffset ?? 0;
  }

  void clampNestedScrollOverscroll() {
    for (final ScrollController? controller in <ScrollController?>[
      _innerController(),
      _primaryController(),
    ]) {
      if (controller == null || !controller.hasClients) {
        continue;
      }
      for (final ScrollPosition position in controller.positions) {
        if (position.pixels >= 0) {
          continue;
        }
        position.jumpTo(0);
      }
    }
  }

  void captureScrubScrollLocks() {
    scrubAllPositionLocks.clear();
    scrubLockedCatalogPosition = null;
    scrubLockedCatalogOffset = null;
    scrubLockedHeaderPosition = null;
    scrubLockedHeaderOffset = null;

    final ScrollController? innerController = _innerController();
    final ScrollController? primaryScrollController = _primaryController();

    for (final ScrollController? controller in <ScrollController?>[
      innerController,
      primaryScrollController,
    ]) {
      if (controller == null || !controller.hasClients) {
        continue;
      }
      for (final ScrollPosition position in controller.positions) {
        if (position.hasContentDimensions) {
          scrubAllPositionLocks[position] = position.pixels;
        }
      }
    }

    final ScrollPosition? catalogPosition = largestScrollExtentPosition(
      innerController,
    );
    final ScrollPosition? headerPosition = headerScrollPosition(
      primaryScrollController,
    );

    if (catalogPosition != null) {
      scrubLockedCatalogPosition = catalogPosition;
      scrubLockedCatalogOffset = catalogPosition.pixels;
    }

    if (headerPosition != null) {
      scrubLockedHeaderPosition = headerPosition;
      final double trackedPixels = trackedOuterScrollPixels ?? 0;
      scrubLockedHeaderOffset = math.max(headerPosition.pixels, trackedPixels);
      scrubAllPositionLocks[headerPosition] = scrubLockedHeaderOffset!;
    } else if (catalogPosition != null) {
      final ScrollPosition? fallbackHeader = fallbackHeaderScrollPosition(
        scrubAllPositionLocks.keys,
        catalogPosition,
      );
      if (fallbackHeader != null) {
        scrubLockedHeaderPosition = fallbackHeader;
        scrubLockedHeaderOffset = fallbackHeader.pixels;
      }
    }

    applyTrackedOuterScrollHeaderLock();
  }

  void applyTrackedOuterScrollHeaderLock() {
    final ScrollPosition? tracked = trackedOuterScrollPosition;
    if (tracked == null || !tracked.hasContentDimensions) {
      return;
    }

    final double trackedPixels = trackedOuterScrollPixels ?? tracked.pixels;
    final ScrollPosition? currentHeader = scrubLockedHeaderPosition;
    final bool headerLockMissing =
        currentHeader == null || (scrubLockedHeaderOffset ?? 0).abs() < 0.5;
    final bool headerPositionUnusable =
        currentHeader != null && currentHeader.maxScrollExtent <= 0;
    final bool trackedHasMeaningfulOffset = trackedPixels.abs() > 0.5;

    if (!headerLockMissing &&
        !headerPositionUnusable &&
        !(trackedHasMeaningfulOffset &&
            (scrubLockedHeaderOffset ?? 0).abs() < 0.5)) {
      return;
    }

    scrubLockedHeaderPosition = tracked;
    scrubLockedHeaderOffset = trackedPixels;
    scrubAllPositionLocks[tracked] = trackedPixels;
  }

  void trackScrollMetrics(ScrollNotification notification) {
    if (alphabetScrubbingActive) {
      return;
    }

    final BuildContext? scrollContext = notification.context;
    if (scrollContext == null) {
      return;
    }
    final ScrollPosition? position = Scrollable.maybeOf(
      scrollContext,
    )?.position;
    if (position == null || !position.hasContentDimensions) {
      return;
    }

    if (position.maxScrollExtent <= 0 || position.maxScrollExtent > 500) {
      return;
    }

    trackedOuterScrollPosition = position;
    trackedOuterScrollPixels = notification.metrics.pixels;
  }

  bool handleNestedScrollNotification(ScrollNotification notification) {
    trackScrollMetrics(notification);

    if (!alphabetScrubbingActive) {
      return false;
    }

    if (notification.metrics.pixels < 0) {
      return true;
    }

    if (notification is! ScrollUpdateNotification) {
      return false;
    }

    final double catalogDrift = livePinnedCatalogDrift();
    final double headerDrift = livePinnedHeaderDrift();
    return catalogDrift.abs() > 0.5 || headerDrift.abs() > 0.5;
  }

  void enforcePinnedHeaderLock() {
    if (!alphabetScrubbingActive || scrubPinnedHeaderOffset == null) {
      return;
    }
    if (enforcingScrubLock) {
      return;
    }

    enforcingScrubLock = true;
    try {
      final double target = scrubPinnedHeaderOffset!;
      final ScrollController? primaryController = _primaryController();
      if (primaryController != null && primaryController.hasClients) {
        for (final ScrollPosition position in primaryController.positions) {
          if (!position.hasContentDimensions ||
              position.maxScrollExtent <= 0 ||
              position.maxScrollExtent > 500) {
            continue;
          }
          final double clamped = target.clamp(0.0, position.maxScrollExtent);
          if ((position.pixels - clamped).abs() > 0.5) {
            position.jumpTo(clamped);
          }
          scrubAllPositionLocks[position] = target;
        }
      }

      final ScrollPosition? header = headerScrollPosition(primaryController);
      if (header != null) {
        scrubLockedHeaderPosition = header;
        scrubLockedHeaderOffset = target;
      }
    } finally {
      enforcingScrubLock = false;
    }
  }

  void enforcePinnedCatalogLock() {
    if (!alphabetScrubbingActive || scrubPinnedCatalogOffset == null) {
      return;
    }
    if (enforcingScrubLock) {
      return;
    }

    enforcingScrubLock = true;
    try {
      final double target = scrubPinnedCatalogOffset!;
      final ScrollController? innerController = _innerController();
      if (innerController == null || !innerController.hasClients) {
        return;
      }

      for (final ScrollPosition position in innerController.positions) {
        if (!position.hasContentDimensions) {
          continue;
        }
        final double clamped = target.clamp(0.0, position.maxScrollExtent);
        if ((position.pixels - clamped).abs() > 0.5) {
          position.jumpTo(clamped);
        }
        scrubAllPositionLocks[position] = target;
        scrubLockedCatalogPosition = position;
        scrubLockedCatalogOffset = target;
      }
    } finally {
      enforcingScrubLock = false;
    }
  }

  void enforcePinnedScrollLocks() {
    enforcePinnedHeaderLock();
    enforcePinnedCatalogLock();
  }

  void restoreNonCatalogScrubScrollLocks() {
    if (enforcingScrubLock) {
      return;
    }
    enforcePinnedHeaderLock();
  }

  void scrollInnerCatalogToTopPreservingHeader() {
    clampNestedScrollOverscroll();

    final ScrollPosition? catalogPosition = scrubLockedCatalogPosition;
    if (catalogPosition != null && catalogPosition.hasContentDimensions) {
      catalogPosition.jumpTo(0);
    }

    restoreNonCatalogScrubScrollLocks();
  }

  double livePinnedHeaderDrift() {
    final ScrollPosition? header = headerScrollPosition(_primaryController());
    return (header?.pixels ?? 0) - (scrubPinnedHeaderOffset ?? 0);
  }

  double livePinnedCatalogDrift() {
    final ScrollPosition? catalog = largestScrollExtentPosition(
      _innerController(),
    );
    return (catalog?.pixels ?? 0) - (scrubPinnedCatalogOffset ?? 0);
  }
}

ScrollPosition? largestScrollExtentPosition(ScrollController? controller) {
  if (controller == null || !controller.hasClients) {
    return null;
  }

  ScrollPosition? largest;
  for (final ScrollPosition position in controller.positions) {
    if (!position.hasContentDimensions) {
      continue;
    }
    if (largest == null || position.maxScrollExtent > largest.maxScrollExtent) {
      largest = position;
    }
  }
  return largest;
}

ScrollPosition? headerScrollPosition(ScrollController? controller) {
  if (controller == null || !controller.hasClients) {
    return null;
  }

  ScrollPosition? best;
  for (final ScrollPosition position in controller.positions) {
    if (!position.hasContentDimensions ||
        position.maxScrollExtent <= 0 ||
        position.maxScrollExtent > 500) {
      continue;
    }
    if (best == null ||
        position.pixels > best.pixels ||
        (position.pixels == best.pixels &&
            position.maxScrollExtent < best.maxScrollExtent)) {
      best = position;
    }
  }
  return best;
}

ScrollPosition? fallbackHeaderScrollPosition(
  Iterable<ScrollPosition> positions,
  ScrollPosition catalogPosition,
) {
  ScrollPosition? fallbackHeader;
  for (final ScrollPosition position in positions) {
    if (position == catalogPosition || position.maxScrollExtent <= 0) {
      continue;
    }
    if (position.maxScrollExtent >= catalogPosition.maxScrollExtent) {
      continue;
    }
    if (fallbackHeader == null ||
        position.maxScrollExtent < fallbackHeader.maxScrollExtent) {
      fallbackHeader = position;
    }
  }
  return fallbackHeader;
}
