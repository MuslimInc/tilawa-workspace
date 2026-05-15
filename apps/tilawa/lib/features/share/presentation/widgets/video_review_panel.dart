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
    final tokens = Theme.of(context).tokens;
    final bottomPadding = context.floatingBottomPadding;
    final String shareLabelText = switch (content) {
      ShareScreenshot() => context.l10n.shareScreenshot,
      ShareVideo() => context.l10n.shareReel,
      ShareAudioClip() => context.l10n.shareAudio,
      ShareText() => context.l10n.share,
    };
    final isScreenshotMode = mode == ShareMode.screenshot;

    final Widget saveButton = TilawaButton(
      key: const ValueKey('video_review_save_button'),
      text: context.l10n.save,
      variant: isScreenshotMode
          ? TilawaButtonVariant.primary
          : TilawaButtonVariant.outline,
      isLoading: isSaving,
      leadingIcon: const Icon(Icons.download_rounded),
      onPressed: isSaving ? null : onSave,
      isFullWidth: true,
    );

    final Widget shareButton = isScreenshotMode
        ? TilawaButton(
            text: shareLabelText,
            variant: TilawaButtonVariant.secondary,
            leadingIcon: const Icon(Icons.share_rounded),
            onPressed: onShare,
            isFullWidth: true,
          )
        : TilawaButton(
            text: shareLabelText,
            variant: TilawaButtonVariant.primary,
            leadingIcon: const Icon(Icons.share_rounded),
            onPressed: onShare,
            isFullWidth: true,
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
                child: TilawaButton(
                  text: context.l10n.edit,
                  variant: TilawaButtonVariant.outline,
                  onPressed: onEdit,
                  isFullWidth: true,
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
