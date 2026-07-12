import 'package:flutter/material.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

/// Token-backed tooltip body shown beside a highlighted tour target.
class TourTooltipCard extends StatelessWidget {
  const TourTooltipCard({
    super.key,
    required this.title,
    required this.description,
    required this.stepSemanticsLabel,
    required this.primaryActionLabel,
    required this.onPrimaryAction,
    required this.skipLabel,
    required this.onSkip,
    required this.showSkip,
  });

  final String title;
  final String description;
  final String stepSemanticsLabel;
  final String primaryActionLabel;
  final VoidCallback onPrimaryAction;
  final String skipLabel;
  final VoidCallback onSkip;
  final bool showSkip;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final MeMuslimDesignTokens tokens = theme.tokens;
    final double maxWidth = MediaQuery.sizeOf(context).width * 0.88;

    return Semantics(
      label: stepSemanticsLabel,
      child: Material(
        color: theme.colorScheme.surfaceContainerHigh,
        elevation: 3,
        borderRadius: BorderRadius.circular(tokens.radiusLarge),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: EdgeInsets.all(tokens.spaceMedium),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: maxWidth.clamp(280, 400),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                SizedBox(height: tokens.spaceSmall),
                Text(
                  description,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.45,
                  ),
                ),
                SizedBox(height: tokens.spaceMedium),
                Row(
                  children: <Widget>[
                    if (showSkip) ...<Widget>[
                      TilawaButton(
                        text: skipLabel,
                        variant: TilawaButtonVariant.ghost,
                        onPressed: onSkip,
                      ),
                      const Spacer(),
                    ],
                    TilawaButton(
                      text: primaryActionLabel,
                      onPressed: onPrimaryAction,
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
