import 'package:flutter/material.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../formatters/prayer_location_label_formatter.dart';

/// Compact location row used on prayer-times surfaces and the home dashboard.
class PrayerLocationUtilityCard extends StatelessWidget {
  const PrayerLocationUtilityCard({
    super.key,
    required this.locationName,
    required this.onTap,
    this.isLoading = false,
    this.padding,
  });

  final String? locationName;
  final VoidCallback? onTap;
  final bool isLoading;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final colorScheme = theme.colorScheme;
    final String label = PrayerLocationLabelFormatter.abbreviatedLocationLabel(
      locationName: locationName,
      l10n: context.l10n,
    );

    final Widget card = TilawaCard(
      surface: TilawaCardSurface.raised,
      borderRadius: tokens.resolveRadius(family: TilawaRadiusFamily.card),
      backgroundColor: colorScheme.surface,
      onTap: isLoading ? null : onTap,
      padding: EdgeInsets.symmetric(horizontal: tokens.spaceSmall),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: tokens.minInteractiveDimension,
        ),
        child: Row(
          spacing: tokens.spaceSmall,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              Icons.location_on_outlined,
              size: tokens.iconSizeSmall,
              color: colorScheme.onSurfaceVariant,
            ),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
            if (isLoading)
              SizedBox(
                width: tokens.iconSizeSmall,
                height: tokens.iconSizeSmall,
                child: TilawaLoadingIndicator(
                  centered: false,
                  strokeWidth: 2,
                  color: colorScheme.primary,
                ),
              )
            else
              Icon(
                Icons.gps_fixed_rounded,
                size: tokens.iconSizeSmall,
                color: colorScheme.onSurfaceVariant,
              ),
          ],
        ),
      ),
    );

    if (padding == null) {
      return card;
    }

    return Padding(padding: padding!, child: card);
  }
}
