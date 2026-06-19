import 'package:flutter/material.dart';

import '../foundation/tilawa_fab_location.dart';
import '../foundation/tilawa_interaction_feedback.dart';

export '../foundation/tilawa_fab_location.dart'
    show TilawaFabLocation, TilawaFabPlacement;

/// Primary floating action for list and hub screens.
///
/// Styled with [ColorScheme.primary] fill. Always pass a unique [heroTag]
/// when multiple FABs exist in a route tree (e.g. shell [IndexedStack]).
///
/// Pair with [TilawaFabLocation.placement] on [Scaffold.floatingActionButtonLocation].
///
/// **Worship-context rule:** not on Quran reader, prayer times, or athkar.
class TilawaPrimaryFab extends StatelessWidget {
  const TilawaPrimaryFab({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.heroTag,
    this.label,
    this.semanticLabel,
    this.tooltip,
    this.placement = TilawaFabPlacement.start,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final Object heroTag;
  final String? label;
  final String? semanticLabel;
  final String? tooltip;

  /// Documented default; actual position is set on [Scaffold.floatingActionButtonLocation].
  final TilawaFabPlacement placement;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    void handlePressed() {
      TilawaInteractionFeedback.trigger(TilawaHaptic.lightImpact);
      onPressed?.call();
    }

    final Widget fab = label == null
        ? FloatingActionButton(
            heroTag: heroTag,
            onPressed: onPressed == null ? null : handlePressed,
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
            tooltip: tooltip ?? semanticLabel,
            child: Icon(icon),
          )
        : FloatingActionButton.extended(
            heroTag: heroTag,
            onPressed: onPressed == null ? null : handlePressed,
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
            tooltip: tooltip ?? semanticLabel,
            icon: Icon(icon),
            label: Text(label!),
          );

    if (semanticLabel == null) {
      return fab;
    }

    return Semantics(
      button: true,
      label: semanticLabel,
      enabled: onPressed != null,
      child: fab,
    );
  }
}
