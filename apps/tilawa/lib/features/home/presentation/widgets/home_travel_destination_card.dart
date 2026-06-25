import 'package:flutter/material.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import 'home_dashboard_card.dart';

/// Travel-app destination card shell — warm header band + white body.
class HomeTravelDestinationCard extends StatelessWidget {
  const HomeTravelDestinationCard({
    super.key,
    required this.tintIndex,
    required this.icon,
    required this.onTap,
    required this.title,
    this.subtitle,
    this.trailing,
    this.semanticLabel,
  });

  final int tintIndex;
  final IconData icon;
  final VoidCallback onTap;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final MeMuslimDesignTokens tokens = theme.tokens;
    final ColorScheme colorScheme = theme.colorScheme;
    final TilawaHomeDashboardCardTokens cardTokens =
        theme.componentTokens.homeDashboardCard;
    final double radius = tokens.resolveRadius(family: TilawaRadiusFamily.hero);
    final Color headerTint = cardTokens.destinationHeaderTint(tintIndex);
    // Arabic previews (e.g. the daily ayah) read better with looser leading.
    final bool isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return Semantics(
      button: true,
      label: semanticLabel ?? title,
      child: HomeDashboardCard(
        surface: TilawaCardSurface.raised,
        padding: EdgeInsets.zero,
        borderRadius: radius,
        onTap: onTap,
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final Widget body = Padding(
              padding: EdgeInsets.all(tokens.spaceMedium),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: tokens.spaceSmall,
                children: [
                  Expanded(
                    child: Column(
                      mainAxisSize: .min,
                      crossAxisAlignment: .start,
                      spacing: tokens.spaceExtraSmall,
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: colorScheme.onSurface,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (subtitle case final String bodyText)
                          Flexible(
                            child: Text(
                              bodyText,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                                height: isArabic
                                    ? tokens.textHeightLoose
                                    : null,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  ?trailing,
                ],
              ),
            );
            final bool stretchBody =
                constraints.hasBoundedHeight && constraints.maxHeight.isFinite;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.max,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: headerTint,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(radius),
                    ),
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: tokens.spaceMedium,
                      vertical: tokens.spaceMedium,
                    ),
                    child: Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: Icon(
                        icon,
                        size: tokens.iconSizeLarge,
                        color: cardTokens.travelDestinationIconColor,
                      ),
                    ),
                  ),
                ),
                if (stretchBody) Expanded(child: body) else body,
              ],
            );
          },
        ),
      ),
    );
  }
}
