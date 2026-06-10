import 'package:flutter/material.dart';

import 'tilawa_illustrated_state.dart';

/// A generic, feature-agnostic empty-state widget.
///
/// Thin wrapper over [TilawaIllustratedState] so every empty state in the
/// product shares one visual system ([TilawaStateVisual] icon treatment,
/// typography, and action layout). Does not include any business-specific
/// copy.
class TilawaEmptyState extends StatelessWidget {
  /// Creates an empty-state placeholder.
  const TilawaEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
    this.iconColor,
  });

  /// The icon shown above the title.
  final IconData icon;

  /// Primary message displayed below the icon.
  final String title;

  /// Optional secondary description below the title.
  final String? subtitle;

  /// Optional action widget (e.g. a button) below the subtitle.
  final Widget? action;

  /// Accent override for the state visual. Defaults to the theme primary.
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return TilawaIllustratedState(
      icon: icon,
      iconColor: iconColor,
      title: title,
      subtitle: subtitle,
      primaryAction: action,
    );
  }
}
