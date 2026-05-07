import 'package:flutter/material.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import 'share_composer_widgets.dart';

class ScreenshotComposerControls extends StatelessWidget {
  const ScreenshotComposerControls({
    super.key,
    required this.fromAyah,
    required this.toAyah,
    required this.minAyah,
    required this.maxAyah,
    required this.isBusy,
    this.errorMessage,
    this.primaryLabel,
    required this.onFromChanged,
    required this.onToChanged,
    required this.onPrimaryAction,
  });

  final int fromAyah;
  final int toAyah;
  final int minAyah;
  final int maxAyah;
  final bool isBusy;
  final String? errorMessage;
  final String? primaryLabel;
  final ValueChanged<int> onFromChanged;
  final ValueChanged<int> onToChanged;
  final VoidCallback onPrimaryAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final bottomPadding = context.floatingBottomPadding;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        tokens.spaceMedium,
        tokens.spaceMedium,
        tokens.spaceMedium,
        tokens.spaceMedium + bottomPadding,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ShareControlsCard(
            children: [
              const LayoutSelectionTile(),
              const ShareTileDivider(),
              AyahRangeTile(
                fromAyah: fromAyah,
                toAyah: toAyah,
                minAyah: minAyah,
                maxAyah: maxAyah,
                onFromChanged: onFromChanged,
                onToChanged: onToChanged,
              ),
            ],
          ),
          if (errorMessage != null) ...[
            SizedBox(height: tokens.spaceSmall),
            Text(
              errorMessage!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          SizedBox(height: tokens.spaceMedium),
          FilledButton.icon(
            onPressed: isBusy ? null : onPrimaryAction,
            icon: const Icon(Icons.screenshot_rounded),
            label: Text(primaryLabel ?? context.l10n.shareScreenshot),
          ),
        ],
      ),
    );
  }
}

class LayoutSelectionTile extends StatelessWidget {
  const LayoutSelectionTile({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ShareControlTileShell(
      icon: Icons.layers_rounded,
      label: context.l10n.shareMode,
      child: Text(
        context.l10n.shareLayoutReaderPage,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
