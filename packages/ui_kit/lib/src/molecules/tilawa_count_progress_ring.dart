import 'package:flutter/material.dart';

import '../atoms/tilawa_loading_indicator.dart';
import '../foundation/component_tokens.dart';
import '../foundation/design_tokens.dart';

class TilawaCountProgressRing extends StatelessWidget {
  const TilawaCountProgressRing({
    super.key,
    required this.currentCount,
    required this.totalCount,
    required this.isDone,
    this.doneIcon = Icons.check_rounded,
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
    final theme = Theme.of(context);
    final designTokens = theme.tokens;
    final componentTokens = theme.componentTokens.countProgressRing;
    final colorScheme = theme.colorScheme;
    final effectiveActiveColor = activeColor ?? colorScheme.primary;
    final effectiveDoneColor = doneColor ?? colorScheme.tertiary;
    final effectiveColor = isDone ? effectiveDoneColor : effectiveActiveColor;
    final progress = totalCount > 0 ? currentCount / totalCount : 0.0;

    return Column(
      mainAxisSize: .min,
      spacing: componentTokens.progressLabelSpacing,
      children: [
        SizedBox.square(
          dimension: componentTokens.outerSize,
          child: Stack(
            alignment: .center,
            children: [
              SizedBox.square(
                dimension: componentTokens.outerSize,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: progress, end: progress),
                  duration: designTokens.durationMedium,
                  curve: Curves.easeOutBack,
                  builder: (context, value, _) {
                    return TilawaLoadingIndicator(
                      centered: false,
                      value: value,
                      strokeWidth: componentTokens.ringStrokeWidth,
                      backgroundColor: Colors.transparent,
                      valueColor: AlwaysStoppedAnimation<Color>(effectiveColor),
                      strokeCap: StrokeCap.round,
                    );
                  },
                ),
              ),
              Container(
                width: componentTokens.innerSize,
                height: componentTokens.innerSize,
                decoration: BoxDecoration(
                  shape: .circle,
                  border: isDone
                      ? Border.all(
                          color: (doneForegroundColor ?? colorScheme.onTertiary)
                              .withValues(
                                alpha: componentTokens.doneBorderOpacity,
                              ),
                          width: componentTokens.doneBorderWidth,
                        )
                      : null,
                  gradient: LinearGradient(
                    begin: .topLeft,
                    end: .bottomRight,
                    colors: [
                      effectiveColor,
                      effectiveColor.withValues(
                        alpha: isDone
                            ? componentTokens.doneGradientEndOpacity
                            : componentTokens.activeGradientEndOpacity,
                      ),
                    ],
                  ),
                ),
                child: Center(
                  child: AnimatedSwitcher(
                    duration: designTokens.durationFast,
                    switchInCurve: Curves.easeInOut,
                    switchOutCurve: Curves.easeInOut,
                    transitionBuilder: (child, animation) {
                      return ScaleTransition(
                        scale: animation,
                        child: FadeTransition(opacity: animation, child: child),
                      );
                    },
                    child: isDone
                        ? Icon(
                            key: const ValueKey('done'),
                            doneIcon,
                            color:
                                doneForegroundColor ?? colorScheme.onTertiary,
                            size: componentTokens.doneIconSize,
                          )
                        : Text(
                            key: ValueKey(currentCount),
                            '$currentCount',
                            style: theme.textTheme.displaySmall?.copyWith(
                              color:
                                  activeForegroundColor ??
                                  colorScheme.onPrimary,
                              fontWeight: .bold,
                              fontSize: componentTokens.countFontSize,
                              height: componentTokens.countLineHeight,
                            ),
                          ),
                  ),
                ),
              ),
            ],
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
                fontWeight: .w600,
              ),
            ),
          ),
      ],
    );
  }
}
