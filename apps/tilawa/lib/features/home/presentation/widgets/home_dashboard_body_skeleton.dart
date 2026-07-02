import 'package:flutter/material.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import 'home_dashboard_card.dart';
import 'home_dashboard_elevated_surface.dart';
import 'home_dashboard_section.dart';

/// Shimmer placeholder for [HomeDashboardBody] during the initial dashboard
/// load.
///
/// Mirrors the loaded body's zone order, section chrome, and card geometry so
/// the loading → content swap keeps a stable layout: real section titles stay
/// visible (they are static l10n copy, not loaded data) while the interactive
/// card content renders as bones under one shared [TilawaSkeleton] sweep.
/// Below-the-fold zones mirror the loaded body layout during cold start.
class HomeDashboardBodySkeleton extends StatelessWidget {
  const HomeDashboardBodySkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final double zoneGap = tokens.spaceExtraLarge;
    final double sectionGap = tokens.spaceLarge;

    return TilawaSkeleton(
      semanticLabel: context.l10n.loading,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          HomeDashboardSection(
            title: context.l10n.homeMainActionsTitle,
            child: const _PrimaryActionTilesSkeleton(),
          ),
          SizedBox(height: sectionGap + tokens.spaceExtraSmall),
          const _QuickToolsRowSkeleton(),
          SizedBox(height: zoneGap),
          HomeDashboardSection(
            title: context.l10n.moreOptions,
            subtitle: context.l10n.homeMoreOptionsSubtitle,
            compact: true,
            child: const _GroupedListSkeleton(rowCount: 4),
          ),
          SizedBox(height: zoneGap),
          HomeDashboardSection(
            title: context.l10n.homeInspirationTitle,
            subtitle: context.l10n.homeInspirationSubtitle,
            child: const _InspirationCardSkeleton(),
          ),
        ],
      ),
    );
  }
}

/// Two primary tile placeholders — mirrors `HomePrimaryActionsSection`.
class _PrimaryActionTilesSkeleton extends StatelessWidget {
  const _PrimaryActionTilesSkeleton();

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: tokens.spaceMedium,
        children: const [
          Expanded(child: _PrimaryActionTileSkeleton()),
          Expanded(child: _PrimaryActionTileSkeleton()),
        ],
      ),
    );
  }
}

class _PrimaryActionTileSkeleton extends StatelessWidget {
  const _PrimaryActionTileSkeleton();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final double radius = tokens.resolveRadius(
      family: TilawaRadiusFamily.hero,
    );
    final double iconBoxSize = tokens.iconBoxSize;
    final double accentRailWidth = tokens.spaceExtraSmall;

    return DecoratedBox(
      decoration: HomeDashboardElevatedSurface.decoration(
        context,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Padding(
        // Mirrors [HomePrimaryActionTile] content padding (incl. accent rail).
        padding: EdgeInsetsDirectional.fromSTEB(
          tokens.spaceMedium + accentRailWidth,
          tokens.spaceMedium,
          tokens.spaceMedium,
          tokens.spaceMedium + tokens.spaceExtraSmall,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TilawaSkeletonBone(
              width: iconBoxSize,
              height: iconBoxSize,
              borderRadius: tokens.radiusLarge,
            ),
            SizedBox(height: tokens.spaceMedium + tokens.spaceExtraSmall),
            TilawaSkeletonLine(
              width: 96,
              style: theme.textTheme.titleMedium,
            ),
            SizedBox(height: tokens.spaceExtraSmall),
            TilawaSkeletonLine(style: theme.textTheme.bodySmall),
            SizedBox(height: tokens.spaceExtraSmall),
            TilawaSkeletonLine(
              width: 88,
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

/// Three compact tool placeholders — mirrors `HomeQuickToolsSection`.
class _QuickToolsRowSkeleton extends StatelessWidget {
  const _QuickToolsRowSkeleton();

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: tokens.spaceSmall,
        children: const [
          Expanded(child: _QuickToolTileSkeleton()),
          Expanded(child: _QuickToolTileSkeleton()),
          Expanded(child: _QuickToolTileSkeleton()),
        ],
      ),
    );
  }
}

class _QuickToolTileSkeleton extends StatelessWidget {
  const _QuickToolTileSkeleton();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final double radius = tokens.resolveRadius(
      family: TilawaRadiusFamily.decorative,
    );
    final double iconBoxSize = tokens.minIconSize;

    return DecoratedBox(
      decoration: HomeDashboardElevatedSurface.decoration(
        context,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          vertical: tokens.spaceSmall + tokens.spaceExtraSmall,
          horizontal: tokens.spaceExtraSmall,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: tokens.spaceMedium,
          children: [
            TilawaSkeletonBone(
              width: iconBoxSize,
              height: iconBoxSize,
              borderRadius: tokens.radiusMedium,
            ),
            TilawaSkeletonLine(
              width: 48,
              style: theme.textTheme.labelSmall,
            ),
          ],
        ),
      ),
    );
  }
}

/// Flat grouped-list placeholder — mirrors `HomeMoreActionsGroup` rows.
class _GroupedListSkeleton extends StatelessWidget {
  const _GroupedListSkeleton({required this.rowCount});

  final int rowCount;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final colorScheme = Theme.of(context).colorScheme;

    return HomeDashboardCard(
      surface: TilawaCardSurface.flat,
      padding: EdgeInsets.zero,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < rowCount; i++) ...[
            if (i > 0)
              TilawaDivider(
                height: tokens.borderWidthThin,
                color: colorScheme.outlineVariant,
              ),
            const _GroupedListRowSkeleton(),
          ],
        ],
      ),
    );
  }
}

class _GroupedListRowSkeleton extends StatelessWidget {
  const _GroupedListRowSkeleton();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final double iconBoxSize = tokens.minIconSize;

    return ConstrainedBox(
      constraints: BoxConstraints(
        minHeight: tokens.minInteractiveDimension,
      ),
      child: Padding(
        // Mirrors [HomeGroupedListRow] row padding.
        padding: EdgeInsetsDirectional.symmetric(
          horizontal: tokens.spaceMedium,
          vertical: tokens.spaceSmall + tokens.spaceExtraSmall,
        ),
        child: Row(
          spacing: tokens.spaceMedium,
          children: [
            TilawaSkeletonBone(
              width: iconBoxSize,
              height: iconBoxSize,
              borderRadius: tokens.radiusMedium,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                spacing: tokens.spaceExtraSmall,
                children: [
                  TilawaSkeletonLine(
                    width: 120,
                    style: theme.textTheme.titleSmall,
                  ),
                  TilawaSkeletonLine(
                    width: 176,
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Grouped inspiration card placeholder — mirrors
/// `HomeDailyInspirationSection` (two rows split by a hairline).
class _InspirationCardSkeleton extends StatelessWidget {
  const _InspirationCardSkeleton();

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final colorScheme = Theme.of(context).colorScheme;

    return HomeDashboardCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _InspirationRowSkeleton(),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: tokens.spaceMedium),
            child: TilawaDivider(
              height: tokens.borderWidthThin,
              color: colorScheme.outlineVariant,
            ),
          ),
          const _InspirationRowSkeleton(),
        ],
      ),
    );
  }
}

class _InspirationRowSkeleton extends StatelessWidget {
  const _InspirationRowSkeleton();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;

    return Padding(
      padding: EdgeInsets.all(tokens.spaceMedium),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: tokens.minInteractiveDimension,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: tokens.spaceMedium,
          children: [
            TilawaSkeletonBone(
              width: tokens.spaceExtraSmall,
              height: tokens.spaceExtraLarge + tokens.spaceSmall,
              borderRadius: tokens.resolveRadius(
                family: TilawaRadiusFamily.decorative,
              ),
            ),
            Expanded(
              child: Column(
                spacing: tokens.spaceSmall,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    spacing: tokens.spaceSmall,
                    children: [
                      Expanded(
                        child: Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: TilawaSkeletonLine(
                            width: 88,
                            style: theme.textTheme.titleSmall,
                          ),
                        ),
                      ),
                      TilawaSkeletonLine(
                        width: 56,
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                  TilawaSkeletonLine(style: theme.textTheme.bodyMedium),
                  TilawaSkeletonLine(
                    width: 200,
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
