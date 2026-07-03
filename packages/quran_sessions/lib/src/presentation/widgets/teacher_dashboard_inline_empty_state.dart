import 'package:flutter/material.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

/// Empty placeholder for sections on [TeacherDashboardScreen].
///
/// Two calm weights, chosen by whether [icon] is provided:
///
/// * **Quiet line** (no [icon]) — a single start-aligned hint with no chrome.
///   Used for sections whose emptiness needs no explanation (booking
///   requests, upcoming sessions) so stacked empty sections stay light.
/// * **Guidance container** (with [icon]) — a soft rounded surface with a
///   muted icon box, title, and hint. Reserved for the bookable-times empty
///   state, where the teacher can act (adjust the weekly schedule) and the
///   explanation genuinely helps.
///
/// Start-aligned throughout for RTL.
class TeacherDashboardInlineEmptyState extends StatelessWidget {
  const TeacherDashboardInlineEmptyState({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
  });

  final String title;
  final String? subtitle;

  /// Leading glyph. When provided the state renders as a guidance container;
  /// when null it renders as a quiet single-line hint.
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final scheme = theme.colorScheme;

    final hintStyle = theme.textTheme.bodySmall?.copyWith(
      color: scheme.onSurfaceVariant,
      height: 1.4,
    );

    final outerPadding = EdgeInsetsDirectional.fromSTEB(
      tokens.spaceLarge,
      0,
      tokens.spaceLarge,
      tokens.spaceMedium,
    );

    if (icon == null) {
      return Padding(
        padding: outerPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          spacing: tokens.spaceTiny,
          children: [
            Text(
              title,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
                height: 1.4,
              ),
              textAlign: TextAlign.start,
            ),
            if (subtitle != null)
              Text(subtitle!, style: hintStyle, textAlign: TextAlign.start),
          ],
        ),
      );
    }

    final radius = tokens.resolveRadius(family: TilawaRadiusFamily.card);

    return Padding(
      padding: outerPadding,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(radius),
        ),
        child: Padding(
          padding: EdgeInsets.all(tokens.spaceMedium),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: tokens.spaceSmall + tokens.spaceExtraSmall,
            children: [
              TilawaIconBox(
                icon: icon!,
                variant: TilawaIconBoxVariant.tinted,
                semanticTint: TilawaSemanticTint.parchment,
                size: tokens.iconSizeSmall,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  spacing: tokens.spaceTiny,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurface,
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.start,
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        style: hintStyle,
                        textAlign: TextAlign.start,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
