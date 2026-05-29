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
      // Whole card is one navigation target; let [TilawaCard.onTap] receive taps
      // from decorative children (icon box, label).
      child: IgnorePointer(
        child: Column(
          spacing: tokens.spaceMedium,
          crossAxisAlignment: .stretch,
          mainAxisAlignment: .center,
          children: [
            Expanded(
              child: TilawaIconBox(
                icon: iconData,
                size: tokens.iconSizeLarge,
                backgroundColor: colorScheme.primary.withValues(
                  alpha: tokens.opacitySubtle,
                ),
                iconColor: colorScheme.primary,
                borderRadius: tokens.radiusLarge,
              ),
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
      ),
    );
  }

  IconData _iconForName(String iconName) {
    switch (iconName) {
      case 'wb_sunny_rounded':
        return Icons.wb_sunny_rounded;
      case 'nights_stay_rounded':
        return Icons.nights_stay_rounded;
      case 'bedtime_rounded':
        return Icons.bedtime_rounded;
      case 'alarm_rounded':
        return Icons.alarm_rounded;
      case 'mosque_rounded':
        return Icons.mosque_rounded;
      case 'auto_stories_rounded':
        return Icons.auto_stories_rounded;
      case 'prayer_times_rounded':
        return Icons.auto_awesome_rounded;
      case 'tasbeeh':
        return Icons.radio_button_checked_rounded;
      default:
        return Icons.bookmark_added_rounded;
    }
  }
}
