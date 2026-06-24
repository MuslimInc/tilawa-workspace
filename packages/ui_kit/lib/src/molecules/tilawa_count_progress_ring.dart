import 'package:flutter/material.dart';

import '../foundation/component_tokens.dart';
import '../foundation/tilawa_icons.dart';
import '../foundation/design_tokens.dart';
import '../foundation/tilawa_text_roles.dart';

/// Circular athkar-style counter: bold count or done check — no progress ring.
///
/// Progress is conveyed by the number and optional `current / total` caption.
/// Exposes [Semantics] with remaining count for screen readers.
class TilawaCountProgressRing extends StatelessWidget {
  const TilawaCountProgressRing({
    super.key,
    required this.currentCount,
    required this.totalCount,
    required this.isDone,
    this.doneIcon = TilawaIcons.check,
    this.activeColor,
    this.doneColor,
    this.activeForegroundColor,
    this.doneForegroundColor,
    this.showProgressLabel = true,
  });

  final int currentCount;
  final int totalCount;
  final bool isDone;
  final IconData doneIcon;
  final Color? activeColor;
  final Color? doneColor;
  final Color? activeForegroundColor;
  final Color? doneForegroundColor;
  final bool showProgressLabel;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TilawaDesignTokens designTokens = theme.tokens;
    final TilawaCountProgressRingTokens componentTokens =
        theme.componentTokens.countProgressRing;
    final ColorScheme colorScheme = theme.colorScheme;
    final Color effectiveActiveColor = activeColor ?? colorScheme.primary;
    final Color effectiveDoneColor = doneColor ?? colorScheme.tertiary;
    final Color fillColor = isDone ? effectiveDoneColor : effectiveActiveColor;
    final double size = componentTokens.outerSize;

    return Semantics(
      label: isDone ? 'Completed' : 'Count $currentCount of $totalCount',
      value: isDone ? null : '$currentCount',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: componentTokens.progressLabelSpacing,
        children: [
          AnimatedContainer(
            duration: designTokens.durationFast,
            curve: Curves.easeOutCubic,
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: fillColor,
              border: isDone
                  ? Border.all(
                      color: (doneForegroundColor ?? colorScheme.onTertiary)
                          .withValues(
                            alpha: componentTokens.doneBorderOpacity,
                          ),
                      width: componentTokens.doneBorderWidth,
                    )
                  : null,
            ),
            child: Center(
              child: AnimatedSwitcher(
                duration: designTokens.durationFast,
                switchInCurve: Curves.easeInOut,
                switchOutCurve: Curves.easeInOut,
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return ScaleTransition(
                    scale: animation,
                    child: FadeTransition(opacity: animation, child: child),
                  );
                },
                child: isDone
                    ? Icon(
                        key: const ValueKey<String>('done'),
                        doneIcon,
                        color: doneForegroundColor ?? colorScheme.onTertiary,
                        size: componentTokens.doneIconSize,
                      )
                    : Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: componentTokens.countHorizontalPadding,
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            key: ValueKey<int>(currentCount),
                            '$currentCount',
                            maxLines: 1,
                            style:
                                tilawaResolveTextRole(
                                  theme.textTheme,
                                  componentTokens.countTextRole,
                                ).copyWith(
                                  color:
                                      activeForegroundColor ??
                                      colorScheme.onPrimary,
                                  fontWeight: FontWeight.w700,
                                  height: componentTokens.countLineHeight,
                                ),
                          ),
                        ),
                      ),
              ),
            ),
          ),
          if (showProgressLabel && !isDone)
            Container(
              padding: componentTokens.progressLabelPadding,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(
                  alpha: componentTokens.progressLabelBackgroundOpacity,
                ),
                borderRadius: BorderRadius.circular(
                  componentTokens.progressLabelBorderRadius,
                ),
              ),
              child: Text(
                '$currentCount / $totalCount',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
