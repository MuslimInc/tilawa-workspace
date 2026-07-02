import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/features/audio_player/presentation/bloc/audio_player_bloc.dart';
import 'package:tilawa/features/history/domain/entities/history_entity.dart';
import 'package:tilawa/features/reciters/presentation/widgets/reciter_catalog_chrome.dart';
import 'package:tilawa/shared/widgets/quran_player_chrome.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

/// Inline horizontal carousel of recently listened surahs for
/// quick resume playback. Uses chip-style cards to minimize
/// vertical space.
class ReciterHistorySection extends StatelessWidget {
  const ReciterHistorySection({
    super.key,
    required this.historyList,
    required this.onPlay,
  });

  final List<HistoryEntity> historyList;
  final Function(HistoryEntity) onPlay;

  @override
  Widget build(BuildContext context) {
    if (historyList.isEmpty) return const SizedBox.shrink();

    context.watch<QuranPlayerChromeNotifier>();
    context.select(
      (AudioPlayerBloc bloc) => (
        bloc.state.shouldShowBottomPlayer,
        bloc.state.currentAudio?.id,
      ),
    );

    final displayList = historyList.take(5).toList();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final tokens = theme.tokens;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: tokens.spaceLarge),
          child: Row(
            spacing: tokens.spaceSmall,
            children: [
              Icon(
                Icons.history_rounded,
                size: tokens.iconSizeMedium,
                color: colorScheme.onSurfaceVariant,
              ),
              Text(
                context.l10n.continueListening,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: tokens.spaceSmall),
        SizedBox(
          height: 40,
          child: ListView.separated(
            padding: EdgeInsets.symmetric(horizontal: tokens.spaceLarge),
            scrollDirection: Axis.horizontal,
            itemCount: displayList.length,
            separatorBuilder: (_, _) => SizedBox(width: tokens.spaceSmall),
            itemBuilder: (context, index) {
              final history = displayList[index];
              return _HistoryChip(
                history: history,
                onTap: () => onPlay(history),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Inline chip-style card showing surah name with a play/check
/// icon and progress percentage.
class _HistoryChip extends StatelessWidget {
  const _HistoryChip({required this.history, required this.onTap});

  final HistoryEntity history;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final tokens = theme.tokens;
    final chipTokens = theme.componentTokens.chip;
    final bool isComplete = history.progress >= 1.0;
    final int percent = (history.progress * 100).clamp(0, 100).toInt();
    final String displayName = context.isArabic
        ? history.surahName
        : history.surahNameEn;

    final double chipHeight =
        tokens.spaceSmall * 2 + (theme.textTheme.labelSmall?.fontSize ?? 12);
    final BorderRadius borderRadius = BorderRadius.circular(
      tokens.resolveRadius(
        family: TilawaRadiusFamily.pill,
        height: chipHeight,
      ),
    );

    final Color fill = isComplete
        ? ReciterCatalogChrome.activeFill(colorScheme)
        : ReciterCatalogChrome.controlIdleFill(context, colorScheme);
    final Color hairline = ReciterCatalogChrome.controlBorder(
      context,
      colorScheme,
      tokens,
    );
    final RoundedRectangleBorder chipShape = RoundedRectangleBorder(
      borderRadius: borderRadius,
      side: isComplete
          ? BorderSide.none
          : BorderSide(
              color: hairline,
              width: chipTokens.borderWidth,
            ),
    );

    return TilawaInteractiveSurface(
      onTap: onTap,
      haptic: TilawaHaptic.lightImpact,
      borderRadius: borderRadius,
      materialColor: fill,
      materialShape: chipShape,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: tokens.spaceMedium,
          vertical: tokens.spaceSmall,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isComplete
                  ? Icons.check_circle_rounded
                  : Icons.play_circle_fill_rounded,
              color: isComplete
                  ? ReciterCatalogChrome.activeOnFill(colorScheme)
                  : colorScheme.onSurface,
              size: tokens.iconSizeMedium,
            ),
            SizedBox(width: tokens.spaceSmall),
            Text(
              displayName,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: isComplete
                    ? ReciterCatalogChrome.activeOnFill(colorScheme)
                    : colorScheme.onSurface,
              ),
            ),
            if (!isComplete && percent >= 5) ...[
              SizedBox(width: tokens.spaceSmall),
              Text(
                '$percent%',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
