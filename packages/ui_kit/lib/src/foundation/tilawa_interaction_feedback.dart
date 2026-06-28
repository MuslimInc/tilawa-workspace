import 'package:flutter/services.dart';

/// Haptic tiers for kit interactive feedback (spec 015 FR-B03).
enum TilawaHaptic {
  none,
  selection,
  lightImpact,
}

/// Global interaction feedback helpers for haptics.
///
/// Set [enabled] to `false` in tests to suppress haptics.
abstract final class TilawaInteractionFeedback {
  static bool enabled = true;

  /// Fires a platform haptic when [enabled] is true.
  static void trigger(TilawaHaptic haptic) {
    if (!enabled || haptic == TilawaHaptic.none) {
      return;
    }
    switch (haptic) {
      case TilawaHaptic.none:
        break;
      case TilawaHaptic.selection:
        HapticFeedback.selectionClick();
      case TilawaHaptic.lightImpact:
        HapticFeedback.lightImpact();
    }
  }
}
