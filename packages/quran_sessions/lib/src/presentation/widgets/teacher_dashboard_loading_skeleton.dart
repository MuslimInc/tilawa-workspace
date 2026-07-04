import 'package:flutter/material.dart';
import 'package:quran_sessions/core/l10n_extensions.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

/// Shimmer placeholder for [TeacherDashboardScreen] during the initial load.
///
/// Mirrors the loaded layout — glance-stats row followed by the category
/// cards — so the loading → content swap keeps a stable structure instead of
/// jumping from a centered spinner to a full dashboard. One [TilawaSkeleton]
/// scope shares the shimmer sweep and announces a single loading label.
class TeacherDashboardLoadingSkeleton extends StatelessWidget {
  const TeacherDashboardLoadingSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).tokens;

    return TilawaSkeleton(
      semanticLabel: context.quranSessionsL10n.teacherDashboardLoadingLabel,
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsetsDirectional.only(bottom: tokens.spaceExtraLarge),
        children: const [
          _SummaryStatsSkeleton(),
          _DashboardCategoriesSkeleton(),
        ],
      ),
    );
  }
}

class _SummaryStatsSkeleton extends StatelessWidget {
  const _SummaryStatsSkeleton();

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).tokens;

    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(
        tokens.spaceLarge,
        tokens.spaceMedium,
        tokens.spaceLarge,
        tokens.spaceSmall,
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: tokens.spaceSmall,
          children: const [
            Expanded(child: _SummaryStatTileSkeleton()),
            Expanded(child: _SummaryStatTileSkeleton()),
            Expanded(child: _SummaryStatTileSkeleton()),
          ],
        ),
      ),
    );
  }
}

class _SummaryStatTileSkeleton extends StatelessWidget {
  const _SummaryStatTileSkeleton();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final double iconRestSize = _iconRestSize(
      context,
      tokens.iconSizeSmall,
    );
    final double decorativeRadius = tokens.resolveRadius(
      family: TilawaRadiusFamily.decorative,
    );

    return TilawaCard(
      padding: EdgeInsets.all(tokens.spaceSmall + tokens.spaceExtraSmall),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          TilawaSkeletonBone(
            width: iconRestSize,
            height: iconRestSize,
            borderRadius: decorativeRadius,
          ),
          SizedBox(height: tokens.spaceSmall),
          TilawaSkeletonLine(
            width: 40,
            style: theme.textTheme.headlineSmall,
          ),
          SizedBox(height: tokens.spaceTiny),
          TilawaSkeletonLine(style: theme.textTheme.labelSmall),
          SizedBox(height: tokens.spaceExtraSmall),
          TilawaSkeletonLine(
            width: 64,
            style: theme.textTheme.labelSmall,
          ),
        ],
      ),
    );
  }
}

class _DashboardCategoriesSkeleton extends StatelessWidget {
  const _DashboardCategoriesSkeleton();

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).tokens;
    final l10n = context.quranSessionsL10n;

    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(
        tokens.spaceLarge,
        tokens.spaceMedium,
        tokens.spaceLarge,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          TilawaSectionHeader(
            title: l10n.teacherDashboardCategoriesTitle,
            subtitle: l10n.teacherDashboardCategoriesSubtitle,
            padding: EdgeInsets.zero,
            trailing: const _HeaderActionSkeleton(),
          ),
          SizedBox(height: tokens.spaceMedium),
          TilawaContentGrid(
            targetItemExtent: 220,
            childAspectRatio: 0.95,
            mainAxisSpacing: tokens.spaceSmall,
            crossAxisSpacing: tokens.spaceSmall,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 3,
            itemBuilder: (context, index) => const _CategoryCardSkeleton(),
          ),
        ],
      ),
    );
  }
}

class _HeaderActionSkeleton extends StatelessWidget {
  const _HeaderActionSkeleton();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final double actionSize = theme.componentTokens.iconActionButton.size;
    final double radius = tokens.resolveRadius(
      family: TilawaRadiusFamily.icon,
      width: actionSize,
      height: actionSize,
    );

    return SizedBox.square(
      dimension: actionSize,
      child: TilawaCard(
        padding: EdgeInsets.zero,
        borderRadius: radius,
        child: Center(
          child: TilawaSkeletonBone(
            width: tokens.iconSizeMedium,
            height: tokens.iconSizeMedium,
            borderRadius: tokens.spaceExtraSmall,
          ),
        ),
      ),
    );
  }
}

class _CategoryCardSkeleton extends StatelessWidget {
  const _CategoryCardSkeleton();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final double iconRestSize = _iconRestSize(
      context,
      tokens.iconSizeMedium,
    );
    final double decorativeRadius = tokens.resolveRadius(
      family: TilawaRadiusFamily.decorative,
    );

    return TilawaCard(
      expandHeight: true,
      padding: EdgeInsets.all(tokens.spaceMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              TilawaSkeletonBone(
                width: iconRestSize,
                height: iconRestSize,
                borderRadius: decorativeRadius,
              ),
              const Spacer(),
              TilawaSkeletonLine(
                width: 32,
                style: theme.textTheme.titleLarge,
              ),
            ],
          ),
          SizedBox(height: tokens.spaceSmall),
          TilawaSkeletonLine(style: theme.textTheme.titleSmall),
          SizedBox(height: tokens.spaceExtraSmall),
          TilawaSkeletonLine(style: theme.textTheme.bodySmall),
          SizedBox(height: tokens.spaceExtraSmall),
          TilawaSkeletonLine(
            width: 96,
            style: theme.textTheme.bodySmall,
          ),
          const Spacer(),
          Row(
            mainAxisSize: MainAxisSize.min,
            spacing: tokens.spaceExtraSmall,
            children: [
              TilawaSkeletonLine(
                width: 44,
                style: theme.textTheme.labelMedium,
              ),
              TilawaSkeletonBone(
                width: tokens.iconSizeSmall,
                height: tokens.iconSizeSmall,
                borderRadius: tokens.spaceExtraSmall,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

double _iconRestSize(BuildContext context, double iconSize) {
  return iconSize + Theme.of(context).componentTokens.iconBox.padding * 2;
}
