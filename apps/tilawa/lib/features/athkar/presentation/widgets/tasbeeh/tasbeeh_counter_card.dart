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
    this.targetCount,
    this.targetFeedbackPulse = 0,
  });

  final int displayCount;
  final VoidCallback onTap;
  final int? targetCount;
  final int targetFeedbackPulse;

  bool get _usesTargetFeedback => targetCount != null && targetCount! > 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final colorScheme = theme.colorScheme;
    final int? total = targetCount;
    final bool isDone = total != null && total > 0 && displayCount >= total;

    final Widget counterBody = _usesTargetFeedback
        ? TilawaCountProgressRing(
            currentCount: displayCount.clamp(0, total!),
            totalCount: total,
            isDone: isDone,
          )
        : _QuickCountDisplay(count: displayCount);

    final Widget counterCard = TilawaCard(
      borderRadius: tokens.radiusExtraLarge,
      surface: TilawaCardSurface.raised,
      backgroundColor: colorScheme.surface,
      expandHeight: true,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: counterBody,
            ),
          ),
          SizedBox(height: tokens.spaceLarge),
          Text(
            context.l10n.tasbeehTapToCount,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
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

class _QuickCountDisplay extends StatelessWidget {
  const _QuickCountDisplay({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final colorScheme = theme.colorScheme;

    return Container(
      padding: EdgeInsets.all(tokens.spaceExtraLarge),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colorScheme.primary.withValues(alpha: tokens.opacitySubtle),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: tokens.opacityMedium),
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
        '$count',
        style: theme.textTheme.displayMedium?.copyWith(
          color: colorScheme.primary,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
