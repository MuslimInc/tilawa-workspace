import 'package:flutter/material.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../domain/entities/share_content.dart';
import '../cubit/share_state.dart';
import '../utils/video_reel_composer_presets.dart';
import 'share_composer_widgets.dart';

class VideoStepIndicator extends StatelessWidget {
  const VideoStepIndicator({super.key, required this.status});
  final ShareStatus status;

  @override
  Widget build(BuildContext context) {
    final isBusy =
        status == ShareStatus.capturing ||
        status == ShareStatus.generating ||
        status == ShareStatus.sharing;
    if (!isBusy) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final tokens = theme.tokens;

    return RepaintBoundary(
      child: SizedBox(
        height: tokens.progressHeight,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(tokens.radiusSmall),
          child: LinearProgressIndicator(
            // Use a fixed value or very slow update to avoid constant raster pressure
            value: status == ShareStatus.sharing ? null : 0.7,
            backgroundColor: theme.colorScheme.surface.withValues(
              alpha: tokens.opacitySubtle,
            ),
            valueColor: AlwaysStoppedAnimation(theme.colorScheme.primary),
          ),
        ),
      ),
    );
  }
}

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
    final headerButtonSize =
        theme.componentTokens.immersiveComposer.headerButtonSize;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: tokens.spaceMedium,
        vertical: tokens.spaceMedium,
      ),
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

class ComposerControls extends StatelessWidget {
  const ComposerControls({
    super.key,
    required this.durationPreset,
    required this.fromAyah,
    required this.toAyah,
    required this.minAyah,
    required this.maxAyah,
    required this.isBusy,
    required this.rangeIsValid,
    required this.reciterName,
    required this.isLoadingReciters,
    required this.canSelectReciter,
    required this.arabicSurahName,
    this.errorMessage,
    this.progressLabel,
    required this.onReciterTap,
    required this.onDurationChanged,
    required this.onFromChanged,
    required this.onToChanged,
    required this.onPrimaryAction,
    required this.onCancel,
  });

  final ShareDurationPreset durationPreset;
  final int fromAyah, toAyah, minAyah, maxAyah;
  final bool isBusy, rangeIsValid, isLoadingReciters, canSelectReciter;
  final String reciterName, arabicSurahName;
  final String? errorMessage, progressLabel;
  final VoidCallback onReciterTap, onPrimaryAction, onCancel;
  final ValueChanged<ShareDurationPreset> onDurationChanged;
  final ValueChanged<int> onFromChanged, onToChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;

    if (isBusy) {
      return Padding(
        padding: EdgeInsets.all(tokens.spaceLarge),
        child: Text(
          progressLabel ?? '',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: tokens.spaceMedium,
        vertical: tokens.spaceMedium,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ShareControlsCard(
            children: [
              ReciterTile(
                reciterName: reciterName,
                isLoading: isLoadingReciters,
                enabled: canSelectReciter,
                onTap: onReciterTap,
              ),
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
            onPressed: rangeIsValid ? onPrimaryAction : null,
            icon: const Icon(Icons.movie_creation_rounded),
            label: Text(context.l10n.generateReel),
          ),
        ],
      ),
    );
  }
}
