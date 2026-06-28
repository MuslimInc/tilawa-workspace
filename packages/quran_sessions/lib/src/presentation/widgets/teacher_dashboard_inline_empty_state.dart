import 'package:flutter/material.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

/// Compact empty state for sections inside [TeacherDashboardScreen].
///
/// Uses [TilawaCard], [TilawaCompactListRow], and [TilawaIconBox] so inline
/// empties match the shared Tilawa atom system (no clipped [TilawaStateVisual]).
class TeacherDashboardInlineEmptyState extends StatelessWidget {
  const TeacherDashboardInlineEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
    this.iconTone = TilawaStateVisualTone.neutral,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  /// Maps to [TilawaIconBox] [TilawaSemanticTint] via [_semanticTintForTone].
  final TilawaStateVisualTone iconTone;

  static TilawaSemanticTint _semanticTintForTone(TilawaStateVisualTone tone) {
    return switch (tone) {
      TilawaStateVisualTone.primary => TilawaSemanticTint.ink,
      TilawaStateVisualTone.secondary => TilawaSemanticTint.scholar,
      TilawaStateVisualTone.tertiary => TilawaSemanticTint.gilding,
      TilawaStateVisualTone.neutral => TilawaSemanticTint.parchment,
      TilawaStateVisualTone.error => TilawaSemanticTint.caution,
    };
  }

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).tokens;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        tokens.spaceLarge,
        0,
        tokens.spaceLarge,
        tokens.spaceSmall,
      ),
      child: TilawaCard(
        surface: TilawaCardSurface.flat,
        padding: EdgeInsets.symmetric(
          horizontal: tokens.spaceExtraSmall,
          vertical: tokens.spaceExtraSmall,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TilawaCompactListRow(
              leading: TilawaIconBox(
                icon: icon,
                variant: TilawaIconBoxVariant.tinted,
                semanticTint: _semanticTintForTone(iconTone),
              ),
              title: title,
              subtitle: subtitle,
            ),
            if (actionLabel != null && onAction != null)
              Padding(
                padding: EdgeInsetsDirectional.only(
                  start: tokens.spaceSmall,
                  end: tokens.spaceSmall,
                  bottom: tokens.spaceExtraSmall,
                ),
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: TilawaButton(
                    text: actionLabel!,
                    leadingIcon: const Icon(Icons.edit_calendar_outlined),
                    variant: TilawaButtonVariant.secondary,
                    size: TilawaButtonSize.small,
                    onPressed: onAction,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
