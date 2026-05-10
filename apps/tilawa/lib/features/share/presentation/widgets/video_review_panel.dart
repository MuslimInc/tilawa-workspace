import 'package:flutter/material.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/features/share/domain/entities/share_content.dart';
import 'package:tilawa/features/share/domain/entities/share_mode.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

class VideoReviewPanel extends StatelessWidget {
  const VideoReviewPanel({
    super.key,
    required this.content,
    required this.onEdit,
    required this.onSave,
    required this.onShare,
    this.isSaving = false,
    this.mode = ShareMode.video,
  });

  final ShareContent content;
  final VoidCallback onEdit;
  final VoidCallback onSave;
  final VoidCallback onShare;
  final bool isSaving;

  /// Drives Save/Share emphasis: on [ShareMode.screenshot], Save is the
  /// filled primary; on [ShareMode.video], Share keeps that role.
  final ShareMode mode;

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
    final isScreenshotMode = mode == ShareMode.screenshot;

    final Widget saveIcon = isSaving
        ? SizedBox(
            width: tokens.iconSizeSmall,
            height: tokens.iconSizeSmall,
            child: const TilawaLoadingIndicator(
              centered: false,
              strokeWidth: 2,
            ),
          )
        : Icon(Icons.download_rounded, size: tokens.iconSizeSmall);
    final Text saveLabel = Text(context.l10n.save);
    final VoidCallback? savePressed = isSaving ? null : onSave;

    final Widget saveButton = isScreenshotMode
        ? FilledButton.icon(
            onPressed: savePressed,
            icon: saveIcon,
            label: saveLabel,
          )
        : OutlinedButton.icon(
            onPressed: savePressed,
            icon: saveIcon,
            label: saveLabel,
          );

    final Icon shareIcon = Icon(
      Icons.share_rounded,
      size: tokens.iconSizeSmall,
    );
    final Text shareText = Text(
      shareLabel,
      maxLines: 1,
      overflow: TextOverflow.fade,
    );

    final Widget shareButton = isScreenshotMode
        ? FilledButton.tonalIcon(
            onPressed: onShare,
            icon: shareIcon,
            label: shareText,
          )
        : FilledButton.icon(
            onPressed: onShare,
            icon: shareIcon,
            label: shareText,
          );

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: tokens.spaceMedium,
        vertical: tokens.spaceMedium,
      ).copyWith(bottom: tokens.spaceMedium + bottomPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onEdit,
                  child: Text(context.l10n.edit),
                ),
              ),
              SizedBox(width: tokens.spaceSmall),
              Expanded(child: saveButton),
            ],
          ),
          SizedBox(height: tokens.spaceSmall),
          shareButton,
        ],
      ),
    );
  }
}
