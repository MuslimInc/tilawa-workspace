import 'package:flutter/material.dart';

import '../atoms/tilawa_icon_box.dart';
import '../foundation/component_tokens.dart';
import '../foundation/design_tokens.dart';
import '../foundation/semantic_tints.dart';
import '../foundation/tilawa_icons.dart';
import '../molecules/tilawa_verified_teacher_badge.dart';

/// Premium capability entry card for approved roles and elevated settings CTAs.
///
/// Calm brand gradient, generous padding, and a secondary badge row so the
/// title stays primary. Use outside worship surfaces (reader, prayer, athkar).
class TilawaCapabilityActionCard extends StatelessWidget {
  const TilawaCapabilityActionCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.leadingIcon,
    required this.onTap,
    this.badgeLabel,
    this.trailingIcon,
    this.useGradient = true,
    this.semanticLabel,
    this.leadingIconSemanticTint = TilawaSemanticTint.scholar,
    this.margin,
  });

  final String title;
  final String subtitle;
  final IconData leadingIcon;
  final VoidCallback onTap;
  final String? badgeLabel;
  final IconData? trailingIcon;
  final bool useGradient;
  final String? semanticLabel;
  final TilawaSemanticTint leadingIconSemanticTint;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final designTokens = theme.tokens;
    final cardTokens = theme.componentTokens.capabilityActionCard;
    final settingsTokens = theme.componentTokens.settingsGroup;
    final double radius = designTokens.resolveRadius(
      family: TilawaRadiusFamily.card,
    );
    final BorderRadius borderRadius = BorderRadius.circular(radius);
    final EdgeInsetsGeometry resolvedMargin = margin ?? cardTokens.outerPadding;
    final String resolvedSemanticLabel = semanticLabel ?? '$title. $subtitle';

    return Padding(
      padding: resolvedMargin,
      child: Semantics(
        button: true,
        label: resolvedSemanticLabel,
        child: SizedBox(
          width: double.infinity,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: borderRadius,
              boxShadow: [
                BoxShadow(
                  color: colorScheme.shadow.withValues(
                    alpha: designTokens.opacityShadow,
                  ),
                  blurRadius: designTokens.blurShadow,
                  offset: designTokens.shadowOffsetMedium,
                ),
              ],
            ),
            child: Material(
              color: useGradient ? null : colorScheme.surface,
              elevation: 0,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: borderRadius,
                side: BorderSide(
                  color: cardTokens.borderColor,
                  width: settingsTokens.tileDividerThickness,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: onTap,
                splashColor: cardTokens.splashColor,
                highlightColor: cardTokens.highlightColor,
                child: Ink(
                  decoration: useGradient
                      ? BoxDecoration(
                          gradient: cardTokens.backgroundGradient(),
                          borderRadius: borderRadius,
                        )
                      : null,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: designTokens.minInteractiveDimension,
                    ),
                    child: Padding(
                      padding: cardTokens.contentPadding,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: cardTokens.rowGap,
                        children: [
                          TilawaIconBox(
                            icon: leadingIcon,
                            size: cardTokens.leadingIconSize,
                            variant: TilawaIconBoxVariant.tinted,
                            semanticTint: leadingIconSemanticTint,
                          ),
                          Expanded(
                            child: _CapabilityActionCardCopy(
                              title: title,
                              subtitle: subtitle,
                              badgeLabel: badgeLabel,
                              cardTokens: cardTokens,
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.only(
                              top: designTokens.spaceTiny,
                            ),
                            child: Icon(
                              trailingIcon ?? TilawaIcons.chevronRightSmall,
                              size: cardTokens.trailingIconSize,
                              color: colorScheme.onSurfaceVariant.withValues(
                                alpha: cardTokens.trailingIconOpacity,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CapabilityActionCardCopy extends StatelessWidget {
  const _CapabilityActionCardCopy({
    required this.title,
    required this.subtitle,
    required this.badgeLabel,
    required this.cardTokens,
  });

  final String title;
  final String subtitle;
  final String? badgeLabel;
  final TilawaCapabilityActionCardTokens cardTokens;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.start,
          style: theme.textTheme.titleMedium?.copyWith(
            color: cardTokens.titleColor,
            fontWeight: FontWeight.w600,
            height: 1.25,
          ),
        ),
        SizedBox(height: cardTokens.titleSubtitleSpacing),
        Text(
          subtitle,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          softWrap: true,
          textAlign: TextAlign.start,
          style: theme.textTheme.bodySmall?.copyWith(
            color: cardTokens.subtitleColor,
            fontWeight: FontWeight.w400,
            height: 1.4,
          ),
        ),
        if (badgeLabel != null) ...[
          SizedBox(height: cardTokens.badgeTopSpacing),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TilawaVerifiedTeacherBadge(label: badgeLabel!),
          ),
        ],
      ],
    );
  }
}
