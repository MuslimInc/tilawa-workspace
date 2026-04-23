import 'package:flutter/material.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../cubit/share_state.dart';
import 'share_composer_widgets.dart';

class ScreenshotComposerControls extends StatelessWidget {
  const ScreenshotComposerControls({
    super.key,
    required this.layout,
    required this.fromAyah,
    required this.toAyah,
    required this.minAyah,
    required this.maxAyah,
    required this.isBusy,
    required this.onLayoutChanged,
    required this.onFromChanged,
    required this.onToChanged,
    required this.onPrimaryAction,
  });

  final ShareScreenshotLayout layout;
  final int fromAyah, toAyah, minAyah, maxAyah;
  final bool isBusy;
  final ValueChanged<ShareScreenshotLayout> onLayoutChanged;
  final ValueChanged<int> onFromChanged, onToChanged;
  final VoidCallback onPrimaryAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;

    return Padding(
      padding: EdgeInsets.all(tokens.spaceMedium),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ShareControlsCard(
            children: [
              LayoutSelectionTile(
                layout: layout,
                onLayoutChanged: onLayoutChanged,
              ),
              if (layout == ShareScreenshotLayout.passageCard) ...[
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
            ],
          ),
          SizedBox(height: tokens.spaceMedium),
          FilledButton.icon(
            onPressed: isBusy ? null : onPrimaryAction,
            icon: const Icon(Icons.screenshot_rounded),
            label: Text(context.l10n.shareScreenshot),
          ),
        ],
      ),
    );
  }
}

class LayoutSelectionTile extends StatelessWidget {
  const LayoutSelectionTile({
    super.key,
    required this.layout,
    required this.onLayoutChanged,
  });

  final ShareScreenshotLayout layout;
  final ValueChanged<ShareScreenshotLayout> onLayoutChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ShareControlTileShell(
      icon: Icons.layers_rounded,
      label: context.l10n.shareMode,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          DropdownButton<ShareScreenshotLayout>(
            value: layout,
            underline: const SizedBox(),
            onChanged: (l) =>
                onLayoutChanged(l ?? ShareScreenshotLayout.readerPage),
            items: [
              DropdownMenuItem(
                value: ShareScreenshotLayout.readerPage,
                child: Text(context.l10n.shareLayoutReaderPage),
              ),
              DropdownMenuItem(
                value: ShareScreenshotLayout.passageCard,
                child: Text(context.l10n.shareLayoutPassageCard),
              ),
            ],
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
