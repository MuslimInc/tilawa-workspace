import 'package:flutter/material.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import 'tasbeeh_layout_widgets.dart';

/// Tap-to-count surface. Target feedback (shake) is opt-in for saved-dhikr only.
class TasbeehCounterCard extends StatelessWidget {
  const TasbeehCounterCard({
    super.key,
    required this.displayCount,
    required this.onTap,
    this.progress,
    this.targetFeedbackPulse = 0,
  });

  final int displayCount;
  final VoidCallback onTap;
  final double? progress;
  final int targetFeedbackPulse;

  bool get _usesTargetFeedback => progress != null;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final colorScheme = theme.colorScheme;

    final Widget counterCard = TilawaCard(
      borderRadius: tokens.radiusExtraLarge,
      surface: TilawaCardSurface.raised,
      backgroundColor: colorScheme.surface,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(tokens.spaceExtraLarge),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colorScheme.primary.withValues(
                  alpha: tokens.opacitySubtle,
                ),
                border: Border.all(
                  color: colorScheme.primary.withValues(
                    alpha: tokens.opacityMedium,
                  ),
                  width: tokens.borderWidthThin,
                ),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.primary.withValues(
                      alpha: tokens.opacityShadow * 0.35,
                    ),
                    blurRadius: tokens.blurShadow,
                    offset: tokens.shadowOffsetSmall,
                  ),
                ],
              ),
              child: Text(
                '$displayCount',
                style: theme.textTheme.displayMedium?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            SizedBox(height: tokens.spaceLarge),
            if (progress != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(tokens.radiusExtraLarge),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: tokens.progressHeight,
                  backgroundColor: colorScheme.outlineVariant.withValues(
                    alpha: tokens.opacitySubtle,
                  ),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    colorScheme.primary,
                  ),
                ),
              ),
              SizedBox(height: tokens.spaceMedium),
            ],
            Text(
              context.l10n.tasbeehTapToCount,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: _usesTargetFeedback
          ? TasbeehShakeOnTrigger(
              trigger: targetFeedbackPulse,
              child: counterCard,
            )
          : counterCard,
    );
  }
}
