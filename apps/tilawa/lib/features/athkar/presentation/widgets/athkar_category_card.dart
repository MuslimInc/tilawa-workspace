import 'package:flutter/material.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

class AthkarCategoryCard extends StatelessWidget {
  const AthkarCategoryCard({
    super.key,
    required this.name,
    required this.icon,
    required this.onTap,
  });
  final String name;
  final String icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final colorScheme = theme.colorScheme;

    final IconData iconData = _iconForName(icon);

    return TilawaCard(
      onTap: onTap,
      borderRadius: tokens.radiusExtraLarge,
      surface: TilawaCardSurface.raised,
      backgroundColor: colorScheme.surface,
      padding: EdgeInsets.all(tokens.spaceLarge),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: tokens.spaceMedium,
        children: [
          TilawaIconBox(
            icon: iconData,
            size: tokens.iconSizeLarge,
            backgroundColor: colorScheme.primary.withValues(
              alpha: tokens.opacitySubtle,
            ),
            iconColor: colorScheme.primary,
            borderRadius: tokens.radiusLarge,
          ),
          Text(
            name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconForName(String iconName) {
    switch (iconName) {
      case 'wb_sunny_rounded':
        return Icons.wb_sunny_rounded;
      case 'nights_stay_rounded':
        return Icons.nights_stay_rounded;
      case 'prayer_times_rounded':
        return Icons.auto_awesome_rounded;
      case 'tasbeeh':
        return Icons.radio_button_checked_rounded;
      default:
        return Icons.bookmark_added_rounded;
    }
  }
}
