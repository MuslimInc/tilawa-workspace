import 'package:flutter/material.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/features/home/presentation/widgets/home_dashboard_elevated_surface.dart';
import 'package:tilawa/features/home/presentation/widgets/home_dashboard_icon_well.dart';
import 'package:tilawa/router/app_router_config.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import 'home_shell_tab_navigation.dart';

/// Compact secondary tools row — Reciters, Qibla, Tasbeeh.
///
/// Visually lighter than [HomePrimaryActionsSection] so the Home hierarchy
/// reads Hero → primary cards → quick tools → featured tutor. Each tool is
/// an equal-weight compact tile in a single row.
class HomeQuickToolsSection extends StatelessWidget {
  const HomeQuickToolsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final theme = Theme.of(context);
    final screenTokens = theme.componentTokens.homeScreen;
    final Color iconAccent = screenTokens.homePrayerHeroAccent;
    final double radius = tokens.resolveRadius(
      family: TilawaRadiusFamily.decorative,
    );
    final double iconSize = tokens.iconSizeLarge + tokens.spaceExtraSmall * 0.5;

    final items = _QuickToolsCatalog.items(context);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: tokens.spaceSmall,
        children: [
          for (final item in items)
            Expanded(
              child: _QuickToolTile(
                icon: item.buildIcon(iconAccent, iconSize),
                label: item.label,
                iconAccent: iconAccent,
                radius: radius,
                onTap: item.onTap,
              ),
            ),
        ],
      ),
    );
  }
}

class _QuickToolTile extends StatelessWidget {
  const _QuickToolTile({
    required this.icon,
    required this.label,
    required this.iconAccent,
    required this.radius,
    required this.onTap,
  });

  final Widget icon;
  final String label;
  final Color iconAccent;
  final double radius;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final BorderRadius borderRadius = BorderRadius.circular(radius);

    return TilawaInteractiveSurface(
      onTap: onTap,
      borderRadius: borderRadius,
      semanticLabel: label,
      stateLayerColor: colorScheme.primary,
      child: DecoratedBox(
        decoration: HomeDashboardElevatedSurface.decoration(
          context,
          borderRadius: borderRadius,
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
              HomeDashboardIconWell(
                accent: iconAccent,
                child: icon,
              ),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.9),
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

@immutable
class _QuickToolItem {
  const _QuickToolItem({
    required this.buildIcon,
    required this.label,
    required this.onTap,
  });

  final Widget Function(Color color, double size) buildIcon;
  final String label;
  final VoidCallback onTap;
}

abstract final class _QuickToolsCatalog {
  static List<_QuickToolItem> items(BuildContext context) {
    final l10n = context.l10n;
    return <_QuickToolItem>[
      _QuickToolItem(
        buildIcon: (color, size) => Icon(
          TilawaIcons.reciters,
          size: size,
          color: color,
        ),
        label: l10n.homeQuickReciters,
        onTap: () => openHomeRecitersTab(context),
      ),
      _QuickToolItem(
        buildIcon: (color, size) => Icon(
          TilawaIcons.qibla,
          size: size,
          color: color,
        ),
        label: l10n.homeQuickQibla,
        onTap: () => const QiblaRoute().push(context),
      ),
      _QuickToolItem(
        buildIcon: (color, size) => TilawaIcons.tasbih.svg(
          color: color,
          size: size,
        ),
        label: l10n.homeQuickTasbeeh,
        onTap: () => const TasbeehRoute().push(context),
      ),
    ];
  }
}
