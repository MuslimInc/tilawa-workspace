import 'package:flutter/material.dart';

import '../foundation/component_tokens.dart';
import '../foundation/design_tokens.dart';

/// A generic, feature-agnostic error-state widget with retry capability.
///
/// Shows a centered column with an icon, title, optional subtitle,
/// and a retry button. Uses design tokens for spacing and sizing.
/// Does not include any business-specific copy.
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

  /// Override color for the icon. Defaults to
  /// `colorScheme.onSurface` with token-driven opacity.
  final Color? iconColor;

  /// When true, the retry button shows a loading indicator and ignores taps.
  final bool isRetrying;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.componentTokens.errorState;
    final designTokens = theme.tokens;
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: tokens.padding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: tokens.iconSize,
              color:
                  iconColor ??
                  colorScheme.onSurface.withValues(alpha: tokens.iconOpacity),
            ),
            SizedBox(height: tokens.titleSpacing),
            Text(
              title,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontSize: tokens.titleFontSize,
                fontWeight: tokens.titleFontWeight,
                color: colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              SizedBox(height: tokens.subtitleSpacing),
              Text(
                subtitle!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: tokens.subtitleFontSize,
                  color: colorScheme.onSurface.withValues(
                    alpha: tokens.subtitleOpacity,
                  ),
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (retryLabel != null && onRetry != null) ...[
              SizedBox(height: tokens.actionSpacing),
              ElevatedButton(
                // fix: Feedback & states — optional in-flight retry affordance
                onPressed: isRetrying ? null : onRetry,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      tokens.retryButtonBackgroundColor ??
                      colorScheme.onSurface,
                  foregroundColor:
                      tokens.retryButtonForegroundColor ?? colorScheme.surface,
                  padding: tokens.retryButtonPadding,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      tokens.retryButtonBorderRadius,
                    ),
                  ),
                ),
                child: isRetrying
                    ? SizedBox(
                        width: designTokens.iconSizeLarge,
                        height: designTokens.iconSizeLarge,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color:
                              tokens.retryButtonForegroundColor ??
                              colorScheme.surface,
                        ),
                      )
                    : Text(retryLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
