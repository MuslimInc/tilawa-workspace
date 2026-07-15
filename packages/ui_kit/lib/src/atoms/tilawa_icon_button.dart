import 'package:flutter/material.dart';

import '../foundation/tilawa_interactive_surface.dart';

/// A custom icon button that uses [TilawaInteractiveSurface] for press feedback.
///
/// Designed as a replacement for Flutter's [IconButton] that aligns with
/// the Tilawa design system's interactive behaviors.
class TilawaIconButton extends StatelessWidget {
  const TilawaIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.semanticLabel,
    this.tooltip,
  });

  /// The widget below this widget in the tree, typically an [Icon].
  final Widget icon;

  /// Called when the button is tapped or otherwise activated.
  ///
  /// If this is null, the button will be disabled.
  final VoidCallback? onPressed;

  /// Screen reader label for the control.
  final String? semanticLabel;

  /// Optional tooltip / long-press hint (e.g. Material "Back").
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: IconButton(
        onPressed: onPressed,
        icon: icon,
        tooltip: tooltip ?? semanticLabel,
      ),
    );
  }
}
