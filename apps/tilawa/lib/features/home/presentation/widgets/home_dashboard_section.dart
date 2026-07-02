import 'package:flutter/material.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

/// Shared title → subtitle → content rhythm for Home dashboard zones.
///
/// Set [compact] to `true` for secondary sections (More) to tighten subtitle
/// and content spacing — section titles stay the same size across zones.
class HomeDashboardSection extends StatelessWidget {
  const HomeDashboardSection({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.contentSpacing,
    this.compact = false,
    required this.child,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final double? contentSpacing;

  /// When true, tightens subtitle/content spacing for secondary sections.
  final bool compact;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final theme = Theme.of(context);

    final Widget titleWidget = Semantics(
      header: true,
      child: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w800,
          color: theme.colorScheme.onSurface,
          height: 1.15,
          letterSpacing: -0.2,
        ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (trailing == null)
          titleWidget
        else
          Row(
            children: [
              Expanded(child: titleWidget),
              trailing!,
            ],
          ),
        if (subtitle != null) ...[
          SizedBox(
            height: compact ? tokens.spaceExtraSmall : tokens.spaceSmall,
          ),
          Text(
            subtitle!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.35,
            ),
          ),
        ],
        SizedBox(
          height:
              contentSpacing ??
              (compact
                  ? tokens.spaceMedium + tokens.spaceExtraSmall
                  : tokens.spaceLarge + tokens.spaceExtraSmall),
        ),
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
