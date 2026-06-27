import 'package:flutter/material.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../theme/quran_sessions_theme.dart';

/// Raised learning-module card with feature shadows and radius.
class QuranSessionsSurfaceCard extends StatelessWidget {
  const QuranSessionsSurfaceCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
    this.highlighted = false,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final feature = QuranSessionsTheme.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = theme.tokens;

    final decoration = BoxDecoration(
      color: feature.cardBackground,
      borderRadius: BorderRadius.circular(feature.cardRadius),
      border: Border.all(
        color: highlighted
            ? feature.highlightBorderColor
            : feature.cardBorderColor,
        width: Theme.of(context).tokens.borderWidthThin,
      ),
      boxShadow: highlighted ? feature.elevatedCardShadow : feature.cardShadow,
    );

    final content = Padding(
      padding: padding ?? EdgeInsets.all(feature.cardPadding),
      child: child,
    );

    if (onTap == null) {
      return DecoratedBox(decoration: decoration, child: content);
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(feature.cardRadius),
        splashColor: scheme.primary.withValues(alpha: tokens.stateLayerPressed),
        highlightColor: scheme.primary.withValues(
          alpha: tokens.stateLayerHover,
        ),
        child: DecoratedBox(decoration: decoration, child: content),
      ),
    );
  }
}
