import 'package:flutter/material.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

/// Shared title → subtitle → content rhythm for Home dashboard zones.
class HomeDashboardSection extends StatelessWidget {
  const HomeDashboardSection({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.contentSpacing,
    required this.child,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final double? contentSpacing;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (trailing == null)
          TilawaSectionTitle(title: title)
        else
          Row(
            children: [
              Expanded(child: TilawaSectionTitle(title: title)),
              trailing!,
            ],
          ),
        if (subtitle != null) ...[
          SizedBox(height: tokens.spaceExtraSmall),
          Text(
            subtitle!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        SizedBox(height: contentSpacing ?? tokens.spaceMedium),
        child,
      ],
    );
  }
}

/// Sub-section header with actions on a second row to avoid crowding at
/// large text scales on narrow phones.
class HomeDashboardSubsectionHeader extends StatelessWidget {
  const HomeDashboardSubsectionHeader({
    super.key,
    required this.title,
    this.trailing,
  });

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    if (trailing == null) {
      return TilawaSectionTitle(title: title);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: tokens.spaceExtraSmall,
      children: [
        TilawaSectionTitle(title: title),
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: trailing!,
        ),
      ],
    );
  }
}
