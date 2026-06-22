import 'package:flutter/material.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

/// Compact premium empty state for sections inside [TeacherDashboardScreen].
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
  final TilawaStateVisualTone iconTone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final scheme = theme.colorScheme;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        tokens.spaceLarge,
        0,
        tokens.spaceLarge,
        tokens.spaceMedium,
      ),
      child: TilawaCard(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: tokens.spaceLarge,
            vertical: tokens.spaceExtraLarge,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TilawaStateVisual(
                icon: icon,
                tone: iconTone,
                size: tokens.iconSizeExtraLarge + tokens.spaceLarge * 2,
              ),
              SizedBox(height: tokens.spaceMedium),
              Text(
                title,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: scheme.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (subtitle != null) ...[
                SizedBox(height: tokens.spaceSmall),
                Text(
                  subtitle!,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    height: 1.45,
                  ),
                ),
              ],
              if (actionLabel != null && onAction != null) ...[
                SizedBox(height: tokens.spaceMedium),
                TilawaButton(
                  text: actionLabel!,
                  leadingIcon: const Icon(Icons.edit_calendar_outlined),
                  variant: TilawaButtonVariant.secondary,
                  isFullWidth: true,
                  onPressed: onAction,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
