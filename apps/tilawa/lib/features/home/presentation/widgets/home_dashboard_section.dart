import 'package:flutter/material.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

/// Shared title → subtitle → content rhythm for Home dashboard zones.
class HomeDashboardSection extends StatelessWidget {
  const HomeDashboardSection({
    super.key,
    this.title,
    this.subtitle,
    this.trailing,
    this.contentSpacing,
    @Deprecated('Spacing is unified across Home sections.')
    this.compact = false,
    required this.child,
  });

  /// When null, only [child] is shown (no header chrome).
  final String? title;
  final String? subtitle;
  final Widget? trailing;
  final double? contentSpacing;

  /// Deprecated — spacing is now unified; kept for call-site compatibility.
  final bool compact;

  final Widget child;

  /// WCAG-friendly secondary copy on dashboard cards and section subtitles.
  static Color secondaryTextColor(BuildContext context) =>
      Theme.of(context).componentTokens.homeScreen.homeHeaderSecondaryText;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final theme = Theme.of(context);
    final Color secondaryText = secondaryTextColor(context);
    final double subtitleGap = tokens.spaceSmall;
    final double afterHeaderGap = contentSpacing ?? tokens.spaceLarge;
    final TextStyle subtitleStyle = theme.textTheme.bodyLarge!.copyWith(
      color: secondaryText,
      height: 1.4,
      fontWeight: FontWeight.w400,
    );

    final String? titleText = title;
    final bool hasHeader = titleText != null || subtitle != null;

    if (!hasHeader) {
      return child;
    }

    final Widget? titleWidget = titleText == null
        ? null
        : Semantics(
            header: true,
            child: Text(
              titleText,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
                height: 1.25,
              ),
            ),
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (titleWidget != null)
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
          if (titleWidget != null) SizedBox(height: subtitleGap),
          Text(
            subtitle!,
            style: subtitleStyle,
          ),
        ],
        SizedBox(height: afterHeaderGap),
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
          child: trailing,
        ),
      ],
    );
  }
}
