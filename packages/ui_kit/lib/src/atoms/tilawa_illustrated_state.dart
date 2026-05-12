import 'package:flutter/material.dart';

import '../foundation/component_tokens.dart';
import '../foundation/design_tokens.dart';
import 'tilawa_state_visual.dart';

/// A reusable, feature-agnostic state layout with an illustration slot.
///
/// Use this for premium empty, permission, onboarding-adjacent, or lightweight
/// error states where a small visual improves clarity. The caller owns the
/// feature-specific copy, action behavior, and any asset selection.
class TilawaIllustratedState extends StatelessWidget {
  /// Creates an illustrated state.
  const TilawaIllustratedState({
    super.key,
    required this.title,
    this.subtitle,
    this.visual,
    this.icon,
    this.iconColor,
    this.primaryAction,
    this.secondaryAction,
    this.maxWidth,
    this.semanticLabel,
  }) : assert(
         visual != null || icon != null,
         'Provide either a visual widget or an icon.',
       );

  /// Primary message shown below the visual.
  final String title;

  /// Optional supporting copy.
  final String? subtitle;

  /// Optional illustration or composed visual.
  ///
  /// Prefer reusable UI Kit assets or feature-scoped assets that follow the
  /// Tilawa visual asset guidelines. Decorative visuals should exclude their
  /// own semantics unless they communicate information not present in text.
  final Widget? visual;

  /// Fallback icon when no custom [visual] is provided.
  final IconData? icon;

  /// Optional icon color. Defaults to the active theme primary color.
  final Color? iconColor;

  /// Primary action, usually a `TilawaButton`.
  final Widget? primaryAction;

  /// Optional lower-emphasis action.
  final Widget? secondaryAction;

  /// Maximum content width. Defaults to `TilawaDesignTokens.contentMaxWidthForm`.
  final double? maxWidth;

  /// Optional semantic label for the overall state.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final stateTokens = theme.componentTokens.emptyState;
    final designTokens = theme.tokens;
    final colorScheme = theme.colorScheme;

    final stateVisual =
        visual ??
        TilawaStateVisual(
          icon: icon!,
          accentColor: iconColor ?? colorScheme.primary,
          size: stateTokens.iconSize + designTokens.spaceExtraLarge * 2,
        );

    return Center(
      child: Semantics(
        container: true,
        label: semanticLabel,
        child: Padding(
          padding: stateTokens.padding,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: maxWidth ?? designTokens.contentMaxWidthForm,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                stateVisual,
                SizedBox(height: stateTokens.titleSpacing),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (subtitle != null) ...[
                  SizedBox(height: stateTokens.subtitleSpacing),
                  Text(
                    subtitle!,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                if (primaryAction != null || secondaryAction != null) ...[
                  SizedBox(height: stateTokens.actionSpacing),
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: designTokens.spaceSmall,
                    runSpacing: designTokens.spaceSmall,
                    children: [
                      ?secondaryAction,
                      ?primaryAction,
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
