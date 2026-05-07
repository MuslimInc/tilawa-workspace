import 'package:flutter/material.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/features/share/domain/entities/share_content.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

class VideoReviewPanel extends StatelessWidget {
  const VideoReviewPanel({
    super.key,
    required this.content,
    required this.onEdit,
    required this.onSave,
    required this.onShare,
    this.isSaving = false,
  });

  final ShareContent content;
  final VoidCallback onEdit;
  final VoidCallback onSave;
  final VoidCallback onShare;
  final bool isSaving;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final bottomPadding = context.floatingBottomPadding;
    final shareLabel = switch (content) {
      ShareScreenshot() => context.l10n.shareScreenshot,
      ShareVideo() => context.l10n.shareReel,
      ShareAudioClip() => context.l10n.shareAudio,
      ShareText() => context.l10n.share,
    };

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: tokens.spaceMedium,
        vertical: tokens.spaceMedium,
      ).copyWith(bottom: tokens.spaceMedium + bottomPadding),
      child: Row(
        spacing: tokens.spaceSmall,
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: onEdit,
              child: Text(context.l10n.edit),
            ),
          ),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: isSaving ? null : onSave,
              icon: isSaving
                  ? SizedBox(
                      width: tokens.iconSizeSmall,
                      height: tokens.iconSizeSmall,
                      child: const CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(Icons.download_rounded, size: tokens.iconSizeSmall),
              label: Text(context.l10n.save),
            ),
          ),
          Expanded(
            child: FilledButton.icon(
              onPressed: onShare,
              icon: Icon(Icons.share_rounded, size: tokens.iconSizeSmall),
              label: Text(shareLabel),
            ),
          ),
        ],
      ),
    );
  }
}
