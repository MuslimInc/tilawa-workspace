import 'package:flutter/material.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

/// Visual weight for [TutorDashboardSection] on [TeacherDashboardScreen].
enum TutorDashboardSectionVariant {
  /// Actionable session content (booking requests, upcoming sessions).
  primary,

  /// Supporting availability metadata (bookable slots).
  secondary,
}

/// Section title for [TeacherDashboardScreen].
///
/// Titles stay count-free — glance counts live only in the summary stats row
/// at the top of the dashboard so the same number never appears twice.
class TutorDashboardSection extends StatelessWidget {
  const TutorDashboardSection({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.variant = TutorDashboardSectionVariant.primary,
    this.showTopDivider = false,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final TutorDashboardSectionVariant variant;
  final bool showTopDivider;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final scheme = theme.colorScheme;
    final isSecondary = variant == TutorDashboardSectionVariant.secondary;

    final titleStyle = theme.textTheme.titleSmall?.copyWith(
      fontWeight: isSecondary ? FontWeight.w600 : FontWeight.w700,
      color: isSecondary ? scheme.onSurfaceVariant : scheme.onSurface,
      height: 1.3,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showTopDivider) ...[
          SizedBox(height: tokens.spaceLarge),
          Divider(
            height: 1,
            thickness: 1,
            color: scheme.outlineVariant.withValues(alpha: 0.6),
          ),
          SizedBox(height: tokens.spaceMedium),
        ],
        TilawaSectionHeader(
          title: title,
          subtitle: subtitle,
          trailing: trailing,
          titleTextStyle: titleStyle,
          padding: EdgeInsetsDirectional.fromSTEB(
            tokens.spaceLarge,
            isSecondary ? tokens.spaceMedium : tokens.spaceSmall,
            tokens.spaceLarge,
            tokens.spaceExtraSmall,
          ),
        ),
      ],
    );
  }
}
