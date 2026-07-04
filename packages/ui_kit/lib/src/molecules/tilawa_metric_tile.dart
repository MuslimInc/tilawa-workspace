import 'package:flutter/material.dart';

import '../atoms/tilawa_skeleton.dart';
import '../foundation/component_tokens.dart';
import '../foundation/design_tokens.dart';
import '../foundation/semantic_tints.dart';
import '../foundation/tilawa_text_roles.dart';

/// Read-only metric data for [TilawaMetricTileStrip].
///
/// Use [TilawaMetricTileStripped] for hand-laid-out rows; the strip helper
/// accepts a list of these and distributes them evenly.
@immutable
class TilawaMetricData {
  const TilawaMetricData({
    required this.value,
    required this.label,
    this.icon,
    this.tint,
    this.helperText,
    this.semanticLabel,
  });

  /// The numeric value rendered as the dominant element.
  ///
  /// Rendered via `toString()` so callers should pass the already-formatted
  /// display form (e.g. `'12'`, `'1,204'`, `'—'`).
  final String value;

  /// Business-friendly caption underneath [value] (e.g. "Pending requests").
  final String label;

  /// Optional leading glyph. Rendered *plain* (coloured glyph, no fill box)
  /// so metric tiles never read as tap affordances like tinted icon wells do.
  final IconData? icon;

  /// Optional semantic tint applied to [icon] only. Kept calm — it does not
  /// tint the tile surface, so summary metrics stay visually distinct from
  /// the raised, tinted action cards below them.
  final TilawaSemanticTint? tint;

  /// Optional helper / trend line under the label (e.g. "+3 this week").
  final String? helperText;

  /// Optional accessibility label overriding the default "$value, $label".
  final String? semanticLabel;
}

/// Read-only summary metric tile.
///
/// Distinct, by design, from a [TilawaCard] action card:
///
/// - **Flat** tonal surface (`surfaceContainerLow`) with a hairline outline
///   and **no** shadow — recedes behind raised category cards.
/// - **No tap affordance** — no [onTap], no ripple, no arrow, no CTA.
/// - **Plain** leading glyph (coloured icon, no fill box) instead of the
///   tinted icon well used on action cards.
/// - Value is dominant; label is quiet; optional helper/trend line below.
///
/// ```dart
/// TilawaMetricTile(
///   data: TilawaMetricData(
///     value: '12',
///     label: 'Pending requests',
///     icon: Icons.inbox_outlined,
///     tint: TilawaSemanticTint.ink,
///   ),
/// )
/// ```
///
/// Tile theming comes from [MeMuslimComponentTokens.metricTile] (resolved via
/// [ThemeData.componentTokens]); colours come from [ColorScheme] — no
/// hardcoded hex. Wrap a row of tiles in [TilawaMetricTileStrip] for even
/// distribution, RTL support, and a shared skeleton loading state.
class TilawaMetricTile extends StatelessWidget {
  const TilawaMetricTile({
    super.key,
    required this.data,
    this.loading = false,
  });

  /// Metric to render. When [loading] is true [data] is ignored (a skeleton
  /// matching the loaded layout is rendered instead).
  final TilawaMetricData data;

  /// Render a shimmer skeleton placeholder instead of the metric. Place under a
  /// [TilawaSkeleton] scope to shimmer (see [TilawaMetricTileSkeleton]).
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.componentTokens.metricTile;
    final designTokens = theme.tokens;
    final scheme = theme.colorScheme;

    final radius = designTokens.spaceSmall; // smaller radius for metric chips
    final border = tokens.borderOpacity > 0
        ? Border.all(
            color: tokens.borderColor.withValues(alpha: tokens.borderOpacity),
            width: designTokens.borderWidthThin,
          )
        : null;

    final body = Padding(
      padding: tokens.padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (data.icon != null) ...[
            Icon(
              data.icon,
              size: tokens.iconSize,
              color: data.tint == null
                  ? scheme.onSurfaceVariant
                  : scheme.semanticTintForeground(data.tint!),
            ),
            SizedBox(height: tokens.valueToIconSpacing),
          ],
          Text(
            data.label,
            style: tokens.labelTextRole
                .resolve(theme.textTheme)
                ?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                  height: 1.25,
                ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: tokens.valueToLabelSpacing),
          Text(
            data.value,
            style: tokens.valueTextRole
                .resolve(theme.textTheme)
                ?.copyWith(
                  fontWeight: tokens.valueFontWeight,
                  height: tokens.valueLineHeight,
                  color: scheme.onSurface,
                ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (data.helperText != null) ...[
            SizedBox(height: tokens.labelToHelperSpacing),
            Text(
              data.helperText!,
              style: tokens.helperTextRole
                  .resolve(theme.textTheme)
                  ?.copyWith(
                    color: scheme.onSurfaceVariant.withValues(
                      alpha: tokens.helperColorOpacity,
                    ),
                    height: 1.25,
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );

    Widget tile = DecoratedBox(
      decoration: BoxDecoration(
        color: tokens.fillColor,
        borderRadius: BorderRadius.circular(radius),
        border: border,
      ),
      child: body,
    );

    if (loading) {
      tile = _MetricTileSkeleton(
        tokens: tokens,
        radius: radius,
        hasIcon: data.icon != null,
        hasHelper: data.helperText != null,
        theme: theme,
      );
    }

    final semanticLabel = data.semanticLabel ?? '${data.value}, ${data.label}';
    return Semantics(
      container: true,
      label: semanticLabel,
      readOnly: true,
      child: SizedBox(
        width: double.infinity,
        child: tile,
      ),
    );
  }
}

/// A responsive horizontal strip of [TilawaMetricTile]s that distributes them
/// evenly with equal heights.
///
/// Use this for dashboard "overview stats" rows so metrics read as a single
/// summary strip, visually distinct from the **raised** action/category cards
/// rendered below them. The strip keeps the tiles equal-height inside a
/// sliver (unbounded height) parent via [IntrinsicHeight].
///
/// When [loading] is true (or [metrics] is empty and [loadingCount] > 0),
/// [loadingCount] skeleton tiles are rendered so the loading → content swap
/// keeps a stable structure.
///
/// ```dart
/// TilawaMetricTileStrip(
///   metrics: [
///     TilawaMetricData(value: '2', label: 'Pending requests'),
///     TilawaMetricData(value: '5', label: 'Upcoming sessions'),
///     TilawaMetricData(value: '12', label: 'Bookable slots'),
///   ],
/// )
/// ```
class TilawaMetricTileStrip extends StatelessWidget {
  const TilawaMetricTileStrip({
    super.key,
    required this.metrics,
    this.spacing,
    this.loading = false,
    this.loadingCount = 3,
    this.padding,
  });

  /// Metrics to render.
  final List<TilawaMetricData> metrics;

  /// Gap between tiles. Defaults to [MeMuslimDesignTokens.spaceSmall].
  final double? spacing;

  /// When true, renders [loadingCount] skeleton tiles and ignores [metrics].
  final bool loading;

  /// Number of skeleton tiles to render while [loading].
  final int loadingCount;

  /// Outer padding. Defaults to a dashboard strip padding
  /// (`spaceLarge / spaceMedium / spaceLarge / spaceSmall`).
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final gap = spacing ?? tokens.spaceSmall;

    final EdgeInsetsGeometry resolvedPadding =
        padding ??
        EdgeInsetsDirectional.fromSTEB(
          tokens.spaceLarge,
          tokens.spaceMedium,
          tokens.spaceLarge,
          tokens.spaceSmall,
        );

    final List<Widget> tiles;
    if (loading) {
      tiles = List.generate(
        loadingCount,
        (_) => const Expanded(child: TilawaMetricTileSkeleton()),
      );
    } else {
      tiles = [
        for (final metric in metrics)
          Expanded(child: TilawaMetricTile(data: metric)),
      ];
    }

    return Padding(
      padding: resolvedPadding,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: gap,
          children: tiles,
        ),
      ),
    );
  }
}

/// Skeleton placeholder for one [TilawaMetricTile], matching the loaded layout
/// so the loading → content swap does not jump. Place under a [TilawaSkeleton]
/// scope to shimmer.
class TilawaMetricTileSkeleton extends StatelessWidget {
  const TilawaMetricTileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.componentTokens.metricTile;
    final designTokens = theme.tokens;
    final radius = designTokens.spaceSmall;
    final border = tokens.borderOpacity > 0
        ? Border.all(
            color: tokens.borderColor.withValues(alpha: tokens.borderOpacity),
            width: designTokens.borderWidthThin,
          )
        : null;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: tokens.fillColor,
        borderRadius: BorderRadius.circular(radius),
        border: border,
      ),
      child: Padding(
        padding: tokens.padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            TilawaSkeletonBone(
              width: tokens.iconSize,
              height: tokens.iconSize,
              borderRadius: designTokens.spaceExtraSmall,
            ),
            SizedBox(height: tokens.valueToIconSpacing),
            TilawaSkeletonLine(
              style: tokens.labelTextRole.resolve(theme.textTheme),
            ),
            SizedBox(height: tokens.valueToLabelSpacing),
            TilawaSkeletonLine(
              width: 80,
              style: tokens.valueTextRole.resolve(theme.textTheme),
            ),
          ],
        ),
      ),
    );
  }
}

/// Internal skeleton used when [TilawaMetricTile.loading] is toggled inline.
/// Exists so a single `loading` tile shimmers inside a [TilawaSkeleton] scope.
class _MetricTileSkeleton extends StatelessWidget {
  const _MetricTileSkeleton({
    required this.tokens,
    required this.radius,
    required this.hasIcon,
    required this.hasHelper,
    required this.theme,
  });

  final TilawaMetricTileTokens tokens;
  final double radius;
  final bool hasIcon;
  final bool hasHelper;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final designTokens = theme.tokens;
    final border = tokens.borderOpacity > 0
        ? Border.all(
            color: tokens.borderColor.withValues(alpha: tokens.borderOpacity),
            width: designTokens.borderWidthThin,
          )
        : null;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: tokens.fillColor,
        borderRadius: BorderRadius.circular(radius),
        border: border,
      ),
      child: Padding(
        padding: tokens.padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hasIcon) ...[
              TilawaSkeletonBone(
                width: tokens.iconSize,
                height: tokens.iconSize,
                borderRadius: designTokens.spaceExtraSmall,
              ),
              SizedBox(height: tokens.valueToIconSpacing),
            ],
            TilawaSkeletonLine(
              style: tokens.labelTextRole.resolve(theme.textTheme),
            ),
            SizedBox(height: tokens.valueToLabelSpacing),
            TilawaSkeletonLine(
              width: 80,
              style: tokens.valueTextRole.resolve(theme.textTheme),
            ),
            if (hasHelper) ...[
              SizedBox(height: tokens.labelToHelperSpacing),
              TilawaSkeletonLine(
                width: 64,
                style: tokens.helperTextRole.resolve(theme.textTheme),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
