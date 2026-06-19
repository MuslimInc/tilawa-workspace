import 'package:flutter/material.dart';

import '../foundation/component_tokens.dart';
import '../foundation/design_tokens.dart';
import '../foundation/semantic_tints.dart';
import '../molecules/tilawa_chip.dart';

export '../foundation/tilawa_fab_location.dart' show TilawaFabPlacement;

/// Optional metric companion pill on [TilawaHeroSummaryCard].
@immutable
class TilawaHeroSummaryBadge {
  const TilawaHeroSummaryBadge({
    required this.label,
    this.icon,
    this.tint = TilawaSemanticTint.neutral,
  });

  final String label;
  final IconData? icon;
  final TilawaSemanticTint tint;
}

/// Token-backed progress footer for [TilawaHeroSummaryCard].
///
/// Use for compact hub summaries where the card needs a calm trend or goal
/// indicator without introducing a feature-local progress style.
class TilawaHeroSummaryProgress extends StatelessWidget {
  const TilawaHeroSummaryProgress({
    super.key,
    required this.progress,
    this.label,
    this.valueLabel,
    this.tint = TilawaSemanticTint.ink,
  });

  /// Progress from `0.0` to `1.0`. Values outside the range are clamped.
  final double progress;

  /// Optional caption shown before the progress track.
  final String? label;

  /// Optional value shown opposite [label], such as `72%`.
  final String? valueLabel;

  /// Manuscript tint used for the progress fill.
  final TilawaSemanticTint tint;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).tokens;
    final double clampedProgress = progress.clamp(0.0, 1.0).toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: tokens.spaceSmall,
      children: [
        if (label != null || valueLabel != null)
          _HeroSummaryProgressLabels(
            label: label,
            valueLabel: valueLabel,
          ),
        _HeroSummaryProgressTrack(
          clampedProgress: clampedProgress,
          tint: tint,
          value: valueLabel ?? '${(clampedProgress * 100).round()}%',
        ),
      ],
    );
  }
}

/// Dashboard-style summary card for progress hubs (khatma, listening stats).
///
/// One focal metric per screen. Use the [footer] slot for sparklines, rings,
/// or progress bars. Flat hairline surface — no card shadow (brand §5).
///
/// **Worship-context rule:** not for Quran reader, prayer times, or athkar.
class TilawaHeroSummaryCard extends StatelessWidget {
  const TilawaHeroSummaryCard({
    super.key,
    required this.label,
    required this.metric,
    this.badges = const <TilawaHeroSummaryBadge>[],
    this.footer,
    this.padding,
  });

  /// Muted caption above the metric (e.g. "Pages read this week").
  final String label;

  /// Primary value (pre-formatted by the feature).
  final String metric;

  /// Small companion pills below the metric.
  final List<TilawaHeroSummaryBadge> badges;

  /// Optional chart, progress ring, or trend slot.
  final Widget? footer;

  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final tokens = theme.tokens;
    final settingsTokens = theme.componentTokens.settingsGroup;
    final double radius = tokens.resolveRadius(family: TilawaRadiusFamily.hero);
    final EdgeInsetsGeometry resolvedPadding =
        padding ?? EdgeInsetsDirectional.all(tokens.spaceLarge);

    return Padding(
      padding: EdgeInsetsDirectional.symmetric(
        horizontal: settingsTokens.groupHorizontalPadding,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(
            color: settingsTokens.groupContainerBorderColor,
            width: settingsTokens.tileDividerThickness,
          ),
        ),
        child: Padding(
          padding: resolvedPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: tokens.spaceMedium,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: tokens.spaceSmall,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    metric,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w700,
                      height: 1.15,
                    ),
                  ),
                  if (badges.isNotEmpty)
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: tokens.spaceSmall,
                      runSpacing: tokens.spaceSmall,
                      children: [
                        for (final badge in badges)
                          _HeroSummaryBadgeChip(badge: badge),
                      ],
                    ),
                ],
              ),
              if (footer != null) ...[
                Divider(
                  height: tokens.borderWidthThin,
                  thickness: settingsTokens.tileDividerThickness,
                  color: settingsTokens.selectionTileDividerColor,
                ),
                footer!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroSummaryBadgeChip extends StatelessWidget {
  const _HeroSummaryBadgeChip({required this.badge});

  final TilawaHeroSummaryBadge badge;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final chipTokens = Theme.of(context).componentTokens.chip;

    return TilawaChip(
      label: badge.label,
      icon: badge.icon,
      backgroundColor: colorScheme.semanticTintBackground(badge.tint),
      foregroundColor: colorScheme.semanticTintForeground(badge.tint),
      padding: chipTokens.inlinePadding,
      iconSize: chipTokens.inlineIconSize,
      textStyle: Theme.of(context).textTheme.labelSmall?.copyWith(
        fontWeight: chipTokens.statusFontWeight,
        color: colorScheme.semanticTintForeground(badge.tint),
      ),
    );
  }
}

class _HeroSummaryProgressLabels extends StatelessWidget {
  const _HeroSummaryProgressLabels({
    this.label,
    this.valueLabel,
  });

  final String? label;
  final String? valueLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final TextStyle? labelStyle = theme.textTheme.labelSmall?.copyWith(
      color: colorScheme.onSurfaceVariant,
      fontWeight: FontWeight.w600,
    );

    return Row(
      children: [
        if (label != null)
          Expanded(
            child: Text(
              label!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: labelStyle,
            ),
          )
        else
          const Spacer(),
        if (valueLabel != null)
          Text(
            valueLabel!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: labelStyle?.copyWith(color: colorScheme.onSurface),
          ),
      ],
    );
  }
}

class _HeroSummaryProgressTrack extends StatelessWidget {
  const _HeroSummaryProgressTrack({
    required this.clampedProgress,
    required this.tint,
    required this.value,
  });

  final double clampedProgress;
  final TilawaSemanticTint tint;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final tokens = theme.tokens;
    final double trackHeight = tokens.spaceSmall;

    return Semantics(
      value: value,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(
          tokens.resolveRadius(
            family: TilawaRadiusFamily.pill,
            height: trackHeight,
          ),
        ),
        child: ColoredBox(
          color: colorScheme.surfaceContainerHighest,
          child: SizedBox(
            height: trackHeight,
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: FractionallySizedBox(
                widthFactor: clampedProgress,
                heightFactor: 1,
                child: ColoredBox(
                  color: colorScheme.semanticTintForeground(tint),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
