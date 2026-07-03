import 'package:flutter/material.dart';

import 'tilawa_illustrated_state.dart';
import 'tilawa_state_visual.dart';

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
    this.visualTone = TilawaStateVisualTone.primary,
  });

  /// The icon shown above the title.
  final IconData icon;

  /// Primary message displayed below the icon.
  final String title;

  /// Optional secondary description below the title.
  final String? subtitle;

  /// Optional action widget (e.g. a button) below the subtitle.
  final Widget? action;

  /// Optional accent override for the state visual.
  final Color? iconColor;

  /// Halo and icon tone. Empty states default to [TilawaStateVisualTone.primary].
  final TilawaStateVisualTone visualTone;

  @override
  Widget build(BuildContext context) {
    return TilawaIllustratedState(
      icon: icon,
      iconColor: iconColor,
      visualTone: visualTone,
      title: title,
      subtitle: subtitle,
      primaryAction: action,
    );
  }
}
