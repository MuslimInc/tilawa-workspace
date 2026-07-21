import 'package:flutter/material.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/features/home/presentation/widgets/home_dashboard_elevated_surface.dart';
import 'package:tilawa/features/home/presentation/widgets/home_dashboard_icon_well.dart';
import 'package:tilawa/features/home/presentation/widgets/home_dashboard_section.dart';
import 'package:tilawa/features/home/presentation/widgets/home_feature_pastel.dart';
import 'package:tilawa/router/app_router_config.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import 'home_shell_tab_navigation.dart';

/// Secondary tools branch — Reciters, Qibla, Tasbeeh.
///
/// Soft mind-map island under worship; lighter tiles than primary actions.
class HomeQuickToolsSection extends StatelessWidget {
  const HomeQuickToolsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final double radius = tokens.resolveRadius(
      family: TilawaRadiusFamily.decorative,
    );
    final double iconSize = tokens.iconSizeLarge;
    final product = Theme.of(context).productColors;
    final items = _QuickToolsCatalog.items(context);

    return HomeDashboardSection(
      title: context.l10n.homeQuickToolsTitle,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: tokens.spaceSmall,
          children: [
            for (final item in items)
              Expanded(
                child: _QuickToolTile(
                  icon: item.buildIcon(
                    HomeFeaturePastel.accentFor(item.feature, product),
                    iconSize,
                  ),
                  label: item.label,
                  accent: HomeFeaturePastel.accentFor(item.feature, product),
                  radius: radius,
                  onTap: item.onTap,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _QuickToolTile extends StatelessWidget {
  const _QuickToolTile({
    required this.icon,
    required this.label,
    required this.accent,
    required this.radius,
    required this.onTap,
  });

  final Widget icon;
  final String label;
  final Color accent;
  final double radius;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final Color surface = colorScheme.surface;
    final BorderRadius borderRadius = BorderRadius.circular(radius);
    return HomeDashboardElevatedSurface.interactive(
      context: context,
      borderRadius: borderRadius,
      onTap: onTap,
      semanticLabel: label,
      stateLayerColor: accent,
      color: surface,
      tier: HomeDashboardElevationTier.quickTool,
      child: Padding(
        padding: EdgeInsets.symmetric(
          vertical: tokens.spaceMedium,
          horizontal: tokens.spaceSmall,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          spacing: tokens.spaceSmall,
          children: [
            HomeDashboardIconWell(
              accent: accent,
              fillAlpha: HomeFeaturePastel.iconWellFillAlpha,
              extent: tokens.iconBoxSize,
              child: icon,
            ),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: theme.textTheme.labelMedium?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w500,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

@immutable
class _QuickToolItem {
  const _QuickToolItem({
    required this.feature,
    required this.buildIcon,
    required this.label,
    required this.onTap,
  });

  final HomeExploreFeature feature;
  final Widget Function(Color color, double size) buildIcon;
  final String label;
  final VoidCallback onTap;
}

abstract final class _QuickToolsCatalog {
  static List<_QuickToolItem> items(BuildContext context) {
    final l10n = context.l10n;
    return <_QuickToolItem>[
      _QuickToolItem(
        feature: HomeExploreFeature.reciters,
        buildIcon: (color, size) => Icon(
          TilawaIcons.reciters,
          size: size,
          color: color,
        ),
        label: l10n.homeQuickReciters,
        onTap: () => openHomeRecitersTab(context),
      ),
      _QuickToolItem(
        feature: HomeExploreFeature.qibla,
        buildIcon: (color, size) => Icon(
          TilawaIcons.qibla,
          size: size,
          color: color,
        ),
        label: l10n.homeQuickQibla,
        onTap: () => const QiblaRoute().push<void>(context),
      ),
      _QuickToolItem(
        feature: HomeExploreFeature.tasbeeh,
        buildIcon: (color, size) => TilawaIcons.tasbih.svg(
          color: color,
          size: size,
        ),
        label: l10n.homeQuickTasbeeh,
        onTap: () => const TasbeehRoute().push<void>(context),
      ),
    ];
  }
}
