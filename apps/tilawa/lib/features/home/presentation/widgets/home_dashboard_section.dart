import 'package:flutter/material.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

/// Shared title → subtitle → content rhythm for Home dashboard zones.
///
/// Set [compact] to `true` for secondary sections (Discover, More) to use
/// quieter title styling, creating a visual weight hierarchy that follows
/// the F-Pattern scanning order.
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

  /// When true, renders a quieter title for secondary sections.
  final bool compact;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final theme = Theme.of(context);

    final Widget titleWidget = compact
        ? _CompactSectionTitle(title: title)
        : Semantics(
            header: true,
            child: Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.onSurface,
                height: 1.2,
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

/// Quieter section title for secondary/supporting sections.
class _CompactSectionTitle extends StatelessWidget {
  const _CompactSectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      title,
      style: theme.textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w700,
        color: theme.colorScheme.onSurface,
      ),
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
