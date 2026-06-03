/// Shell-footer expand drag routing (recognizer vs global [PointerRoute]).
///
/// Extracted for unit tests that lock YouTube Music-style gesture behavior.
enum QuranPlayerExpandDragChannel {
  /// Footer mini vertical drag recognizer.
  footerRecognizer,

  /// Expanded sheet / stage / queue recognizers.
  expandedRecognizer,

  /// Global pointer route (retains moves when overlay covers the mini).
  pointerRoute,
}

/// Policy for which channels may apply expand drag deltas.
abstract final class QuranPlayerExpandGesturePolicy {
  /// When the shell pointer route is active, only [pointerRoute] should apply
  /// drag pixels. Recognizer callbacks would otherwise double-count deltas.
  static bool shouldApplyRecognizerDragDelta({
    required bool pointerRouteAttached,
    required QuranPlayerExpandDragChannel channel,
  }) {
    if (!pointerRouteAttached) {
      return true;
    }
    return channel == QuranPlayerExpandDragChannel.pointerRoute;
  }

  /// Only track the pointer that started the active expand drag.
  static bool shouldPointerRouteApplyMove({
    required bool isUserDraggingExpand,
    required int? activePointerId,
    required int eventPointerId,
  }) {
    if (!isUserDraggingExpand) {
      return false;
    }
    if (activePointerId == null) {
      return true;
    }
    return activePointerId == eventPointerId;
  }

  /// Finishes an orphaned shell drag when the overlay covered the footer mini
  /// and [GestureDetector.onVerticalDragEnd] never fired.
  ///
  /// Uses zero velocity — recognizer end is preferred when it arrives first.
  static bool shouldPointerRouteFinishOnRelease({
    required bool pointerRouteAttached,
    required bool dragEndHandled,
    required int? activePointerId,
    required int eventPointerId,
  }) {
    if (!pointerRouteAttached || dragEndHandled) {
      return false;
    }
    if (activePointerId == null) {
      return true;
    }
    return activePointerId == eventPointerId;
  }
}
