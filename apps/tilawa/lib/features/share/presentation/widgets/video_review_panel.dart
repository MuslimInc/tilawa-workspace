import 'package:flutter/material.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/features/share/domain/entities/share_content.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

class VideoReviewPanel extends StatelessWidget {
  const VideoReviewPanel({
    super.key,
    required this.content,
    required this.onEdit,
    required this.onShare,
  });

  final ShareContent content;
  final VoidCallback onEdit;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final bottomPadding = MediaQuery.paddingOf(context).bottom;
    final headerButtonSize =
        theme.componentTokens.immersiveComposer.headerButtonSize;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: tokens.spaceMedium,
        vertical: tokens.spaceMedium,
      ).copyWith(bottom: tokens.spaceMedium + bottomPadding),
      child: Row(
        spacing: tokens.spaceSmall,
        children: [
          Expanded(
            child: SizedBox(
              height: headerButtonSize,
              child: OutlinedButton(
                onPressed: onEdit,
                child: Text(context.l10n.edit),
              ),
            ),
          ),
          Expanded(
            child: SizedBox(
              height: headerButtonSize,
              child: FilledButton.icon(
                onPressed: onShare,
                icon: Icon(Icons.share_rounded, size: tokens.iconSizeSmall),
                label: Text(context.l10n.shareReel),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
