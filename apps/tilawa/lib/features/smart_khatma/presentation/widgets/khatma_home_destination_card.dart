import 'package:flutter/material.dart';
import 'package:tilawa/features/home/presentation/widgets/home_dashboard_card.dart';
import 'package:tilawa/features/home/presentation/widgets/home_dashboard_icon_well.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

/// Smart Khatma home entry — full-card primary gradient.
///
/// Vertical featured layout for phone readability (taller tap target, larger
/// title/body than the previous compact row).
class KhatmaHomeDestinationCard extends StatelessWidget {
  const KhatmaHomeDestinationCard({
    super.key,
    required this.icon,
    required this.onTap,
    required this.title,
    this.subtitle,
    this.detail,
    this.trailing,
    this.semanticLabel,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String title;
  final String? subtitle;

  /// Optional second body line (e.g. today's page range / confirm count).
  final String? detail;
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
    final TextStyle? bodyStyle = theme.textTheme.bodyLarge?.copyWith(
      color: colorScheme.onPrimary.withValues(alpha: 0.88),
      height: isArabic ? tokens.textHeightLoose : 1.45,
    );

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
            padding: EdgeInsets.all(tokens.spaceLarge),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: tokens.spaceMedium,
              children: [
                Row(
                  children: [
                    HomeDashboardIconWell(
                      accent: colorScheme.onPrimary,
                      extent: tokens.iconBadgeSize,
                      child: Icon(
                        icon,
                        size: tokens.iconSizeLarge + tokens.spaceExtraSmall,
                        color: colorScheme.onPrimary,
                      ),
                    ),
                    const Spacer(),
                    ?trailing,
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: tokens.spaceSmall,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: colorScheme.onPrimary,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                        letterSpacing: -0.2,
                      ),
                    ),
                    if (subtitle case final String bodyText)
                      Text(
                        bodyText,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: bodyStyle,
                      ),
                    if (detail case final String detailText)
                      Text(
                        detailText,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: bodyStyle?.copyWith(
                          color: colorScheme.onPrimary.withValues(alpha: 0.78),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
