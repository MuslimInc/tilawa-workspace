import 'package:flutter/material.dart';

import '../foundation/component_tokens.dart';
import '../foundation/design_tokens.dart';
import 'tilawa_button.dart';
import 'tilawa_illustrated_state.dart';
import 'tilawa_state_visual.dart';

/// A generic, feature-agnostic error-state widget with retry capability.
///
/// Thin wrapper over [TilawaIllustratedState] so error states share the same
/// visual system as empty states, with an error-toned [TilawaStateVisual] and
/// a [TilawaButton] retry action. Does not include any business-specific copy.
class TilawaErrorState extends StatelessWidget {
  /// Creates an error-state placeholder.
  const TilawaErrorState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.retryLabel,
    this.onRetry,
    this.iconColor,
    this.isRetrying = false,
  });

  /// The icon shown above the title.
  final IconData icon;

  /// Primary message displayed below the icon.
  final String title;

  /// Optional secondary description below the title.
  final String? subtitle;

  /// Label for the retry button. If null, the button is not shown.
  final String? retryLabel;

  /// Callback when the retry button is pressed.
  final VoidCallback? onRetry;

  /// Accent override for the state visual. Defaults to the error tone.
  final Color? iconColor;

  /// When true, the retry button shows a loading indicator and ignores taps.
  final bool isRetrying;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final stateTokens = theme.componentTokens.emptyState;

    return TilawaIllustratedState(
      visual: TilawaStateVisual(
        icon: icon,
        tone: TilawaStateVisualTone.error,
        accentColor: iconColor,
        size: stateTokens.iconSize + theme.tokens.spaceExtraLarge * 2,
      ),
      title: title,
      subtitle: subtitle,
      primaryAction: (retryLabel != null && onRetry != null)
          ? TilawaButton(
              text: retryLabel!,
              isLoading: isRetrying,
              onPressed: isRetrying ? null : onRetry,
            )
          : null,
    );
  }
}
