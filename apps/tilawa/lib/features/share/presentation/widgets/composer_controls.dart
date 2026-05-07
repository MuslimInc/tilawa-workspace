import 'package:flutter/material.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/features/share/presentation/utils/video_reel_composer_presets.dart';
import 'package:tilawa/features/share/presentation/widgets/share_composer_widgets.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

class ComposerControls extends StatelessWidget {
  const ComposerControls({
    super.key,
    required this.durationPreset,
    required this.fromAyah,
    required this.toAyah,
    required this.minAyah,
    required this.maxAyah,
    required this.isBusy,
    required this.isGeneratingVideo,
    required this.rangeIsValid,
    this.isError = false,
    required this.reciterName,
    required this.isLoadingReciters,
    required this.canSelectReciter,
    required this.arabicSurahName,
    this.errorMessage,
    this.rangeIssue,
    this.progressLabel,
    this.progressPercent,
    required this.onReciterTap,
    required this.onDurationChanged,
    required this.onFromChanged,
    required this.onToChanged,
    required this.onPrimaryAction,
    required this.onCancel,
  });

  final ShareDurationPreset durationPreset;
  final int fromAyah, toAyah, minAyah, maxAyah;
  final bool isBusy,
      isGeneratingVideo,
      rangeIsValid,
      isError,
      isLoadingReciters,
      canSelectReciter;
  final String reciterName, arabicSurahName;
  final String? errorMessage, rangeIssue, progressLabel;
  final double? progressPercent;
  final VoidCallback onReciterTap, onPrimaryAction, onCancel;
  final ValueChanged<ShareDurationPreset> onDurationChanged;
  final ValueChanged<int> onFromChanged, onToChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final bottomPadding = context.floatingBottomPadding;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(tokens.radiusLarge),
        ),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: tokens.spaceMedium,
        vertical: tokens.spaceMedium + bottomPadding,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          IgnorePointer(
            ignoring: isBusy,
            child: ShareControlsCard(
              children: [
                ReciterTile(
                  reciterName: reciterName,
                  isLoading: isLoadingReciters,
                  enabled: canSelectReciter && !isBusy,
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
          ] else if (rangeIssue != null && !isBusy) ...[
            SizedBox(height: tokens.spaceSmall),
            Text(
              rangeIssue!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          if (isGeneratingVideo && progressLabel != null) ...[
            SizedBox(height: tokens.spaceSmall),
            Text(
              progressPercent != null && progressPercent! > 0
                  ? '$progressLabel (${(progressPercent! * 100).toStringAsFixed(0)}%)'
                  : progressLabel!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          SizedBox(height: tokens.spaceMedium),
          FilledButton.icon(
            onPressed: (!isBusy && rangeIsValid) ? onPrimaryAction : null,
            icon: isGeneratingVideo
                ? SizedBox(
                    width: tokens.iconSizeMedium,
                    height: tokens.iconSizeMedium,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: theme.colorScheme.onPrimary,
                    ),
                  )
                : Icon(
                    isError
                        ? Icons.refresh_rounded
                        : Icons.movie_creation_rounded,
                  ),
            label: Text(
              isGeneratingVideo
                  ? context.l10n.preparingReelStatus
                  : isError
                  ? context.l10n.retry
                  : context.l10n.generateReel,
            ),
          ),
          if (isGeneratingVideo) ...[
            SizedBox(height: tokens.spaceSmall),
            OutlinedButton.icon(
              onPressed: onCancel,
              icon: const Icon(Icons.close_rounded),
              label: Text(context.l10n.cancel),
            ),
          ],
        ],
      ),
    );
  }
}
