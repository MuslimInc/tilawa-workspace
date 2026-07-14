import 'package:flutter/material.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

/// Non-dismissible full-screen gate requiring a store update.
class ForcedUpdateGatePage extends StatelessWidget {
  const ForcedUpdateGatePage({
    super.key,
    required this.onUpdatePressed,
  });

  final VoidCallback onUpdatePressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final l10n = context.l10n;
    final colorScheme = theme.colorScheme;

    return PopScope(
      canPop: false,
      child: Material(
        color: theme.scaffoldBackgroundColor,
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(tokens.spaceLarge),
            child: Column(
              children: [
                const Spacer(),
                Icon(
                  Icons.system_update_alt_rounded,
                  size: tokens.spaceExtraLarge * 2,
                  color: colorScheme.primary,
                ),
                SizedBox(height: tokens.spaceLarge),
                Text(
                  l10n.forcedUpdateTitle,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: colorScheme.onSurface,
                  ),
                ),
                SizedBox(height: tokens.spaceMedium),
                Text(
                  l10n.forcedUpdateMessage,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                TilawaButton(
                  onPressed: onUpdatePressed,
                  text: l10n.forcedUpdateAction,
                  isFullWidth: true,
                  size: TilawaButtonSize.large,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
