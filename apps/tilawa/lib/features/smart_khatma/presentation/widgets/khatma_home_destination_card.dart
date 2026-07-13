import 'package:flutter/material.dart';
import 'package:tilawa/features/home/presentation/widgets/home_dashboard_card.dart';
import 'package:tilawa/features/home/presentation/widgets/home_dashboard_icon_well.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

/// Smart Khatma home entry — full-card primary gradient.
class KhatmaHomeDestinationCard extends StatelessWidget {
  const KhatmaHomeDestinationCard({
    super.key,
    required this.icon,
    required this.onTap,
    required this.title,
    this.subtitle,
    this.trailing,
    this.semanticLabel,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final colorScheme = theme.colorScheme;
    final radius = tokens.resolveRadius(family: TilawaRadiusFamily.hero);
    final bool isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final List<Color> gradientColors = <Color>[
      colorScheme.primary,
      Color.alphaBlend(
        colorScheme.primary.withValues(alpha: 0.80),
        colorScheme.surface,
      ),
    ];

    return Semantics(
      button: true,
      label: semanticLabel ?? title,
      child: HomeDashboardCard(
        padding: EdgeInsets.zero,
        borderRadius: radius,
        backgroundColor: Colors.transparent,
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            gradient: LinearGradient(
              begin: AlignmentDirectional.topStart,
              end: AlignmentDirectional.bottomEnd,
              colors: gradientColors,
            ),
          ),
          child: Padding(
            padding: EdgeInsets.all(tokens.spaceMedium),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: tokens.spaceSmall,
              children: [
                HomeDashboardIconWell(
                  accent: colorScheme.onPrimary,
                  child: Icon(
                    icon,
                    size: tokens.iconSizeLarge,
                    color: colorScheme.onPrimary,
                  ),
                ),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: tokens.spaceExtraSmall,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: colorScheme.onPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (subtitle case final String bodyText)
                        Text(
                          bodyText,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onPrimary.withValues(
                              alpha: 0.86,
                            ),
                            height: isArabic ? tokens.textHeightLoose : 1.45,
                          ),
                        ),
                    ],
                  ),
                ),
                ?trailing,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
