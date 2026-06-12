part of 'quran_player_widget.dart';
// ---------------------------------------------------------------------------
// Molecules
// ---------------------------------------------------------------------------

class _YtMusicPlayerHeader extends StatelessWidget {
  const _YtMusicPlayerHeader({
    required this.state,
    required this.onCollapse,
  });

  final AudioPlayerState state;
  final VoidCallback onCollapse;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).tokens;
    final palette = _ExpandedPlayerPalette.of(context);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: tokens.spaceSmall),
      child: Row(
        children: [
          Semantics(
            identifier: QuranPlayerSemanticsIds.expandedCollapseButton,
            button: true,
            child: IconButton(
              icon: Icon(
                FluentIcons.chevron_down_24_regular,
                color: palette.foreground,
                size: tokens.iconSizeLarge,
              ),
              onPressed: onCollapse,
              tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            ),
          ),
          const Spacer(),
          Semantics(
            identifier: QuranPlayerSemanticsIds.expandedMoreMenu,
            button: true,
            child: IconButton(
              icon: Icon(
                FluentIcons.more_vertical_24_regular,
                color: palette.foreground,
              ),
              onPressed: () => _showExpandedPlayerMenu(context, state),
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> _showExpandedPlayerMenu(
  BuildContext context,
  AudioPlayerState state,
) async {
  await showTilawaModalBottomSheet<void>(
    context: context,
    builder: (sheetContext) {
      final bool sleepEnabled = context
          .read<SettingsCubit>()
          .state
          .isSleepTimerEnabled;
      return Padding(
        padding: EdgeInsets.only(bottom: sheetContext.floatingBottomPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const TilawaSheetHandle(),
            if (sleepEnabled)
              Semantics(
                identifier: QuranPlayerSemanticsIds.menuSheetSleepTimer,
                button: true,
                child: ListTile(
                  leading: Icon(
                    state.isSleepTimerActive
                        ? FluentIcons.timer_24_filled
                        : FluentIcons.timer_24_regular,
                  ),
                  title: Text(sheetContext.l10n.recitationDuration),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    showDialog(
                      context: context,
                      builder: (_) => const SleepTimerDialog(),
                    );
                  },
                ),
              ),
            Semantics(
              identifier: QuranPlayerSemanticsIds.menuSheetBackground,
              button: true,
              child: ListTile(
                leading: const Icon(FluentIcons.image_24_regular),
                title: Text(sheetContext.l10n.chooseBackgroundSource),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  showDialog(
                    context: context,
                    builder: (dialogContext) => BackgroundSourceDialog(
                      onSourceSelected: (source) {
                        context.read<PlayerBackgroundCubit>().pickImage(source);
                      },
                    ),
                  );
                },
              ),
            ),
            Semantics(
              identifier: QuranPlayerSemanticsIds.menuSheetStop,
              button: true,
              child: ListTile(
                leading: const Icon(FluentIcons.stop_24_regular),
                title: Text(sheetContext.l10n.stopPlayback),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  if (getIt<PlayerPresentationController>().routeOpen) {
                    getIt<PlayerPresentationController>().collapse();
                  }
                  context.read<AudioPlayerBloc>().add(
                    const AudioPlayerEvent.stopAudio(),
                  );
                },
              ),
            ),
          ],
        ),
      );
    },
  );
}

/// Progress, transport, and adjustment pills pinned as one control band.
class _PlayerPlaybackCluster extends StatelessWidget {
  const _PlayerPlaybackCluster({
    required this.state,
    this.queueReveal = 0,
  });

  final AudioPlayerState state;
  final double queueReveal;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).tokens;
    final double queueInset = tokens.spaceMedium * queueReveal.clamp(0.0, 1.0);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _ExpandedProgressBar(),
        SizedBox(height: tokens.spaceSmall),
        _PlayerTransportRow(
          state: state,
          isPlaying: state.isPlaying,
        ),
        SizedBox(height: tokens.spaceMedium),
        _PlayerActionPillsMolecule(state: state),
        SizedBox(height: tokens.spaceSmall + queueInset),
      ],
    );
  }
}

class _PlayerMetadataMolecule extends StatelessWidget {
  const _PlayerMetadataMolecule({
    required this.title,
    this.artist,
    this.centerAlign = false,
    this.audioId,
    this.useHeroMetadata = false,
  });

  final String title;
  final String? artist;
  final bool centerAlign;
  final String? audioId;
  final bool useHeroMetadata;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).tokens;
    final palette = _ExpandedPlayerPalette.of(context);
    final TextStyle? titleStyle = context
        .responsiveStyle((t) => t.titleLarge)
        ?.copyWith(color: palette.foreground, fontWeight: FontWeight.w600);
    final TextStyle? subtitleStyle = context
        .responsiveStyle((t) => t.bodyMedium)
        ?.copyWith(color: palette.secondary);
    final String subtitle = artist ?? context.l10n.unknownReciter;

    if (useHeroMetadata && audioId != null && titleStyle != null) {
      return QuranPlayerHeroMetadata(
        audioId: audioId!,
        title: title,
        subtitle: subtitle,
        titleStyle: titleStyle,
        subtitleStyle: subtitleStyle ?? const TextStyle(),
        centerAlign: centerAlign,
        semanticDestination: true,
      );
    }

    final TextAlign textAlign = centerAlign
        ? TextAlign.center
        : TextAlign.start;
    final CrossAxisAlignment crossAlign = centerAlign
        ? CrossAxisAlignment.center
        : CrossAxisAlignment.stretch;
    return Column(
      crossAxisAlignment: crossAlign,
      spacing: tokens.spaceExtraSmall,
      children: [
        Semantics(
          identifier: QuranPlayerSemanticsIds.expandedTrackTitle,
          child: Text(
            title,
            style: titleStyle,
            textAlign: textAlign,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Semantics(
          identifier: QuranPlayerSemanticsIds.expandedTrackArtist,
          child: Text(
            subtitle,
            style: subtitleStyle,
            textAlign: textAlign,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _PlayerTransportRow extends StatelessWidget {
  const _PlayerTransportRow({
    required this.state,
    required this.isPlaying,
  });

  final AudioPlayerState state;
  final bool isPlaying;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).tokens;
    final palette = _ExpandedPlayerPalette.of(context);
    final bool shuffleOn = QuranPlayerTransportControls.shuffleActive(
      state.shuffleMode,
    );
    final Color enabled = palette.foreground;
    final Color disabled = palette.disabled;
    final IconData repeatIcon = QuranPlayerTransportControls.repeatIcon(
      state.repeatMode,
    );
    final bool repeatActive = QuranPlayerTransportControls.repeatActive(
      state.repeatMode,
    );
    final IconData shuffleIcon = QuranPlayerTransportControls.shuffleIcon(
      state.shuffleMode,
    );
    final bool swapSkipSidesForArabic = context.isArabic;

    final Widget previousControl = Semantics(
      identifier: QuranPlayerSemanticsIds.transportPrevious,
      button: true,
      child: IconButton(
        icon: Icon(
          swapSkipSidesForArabic ? Icons.skip_next : Icons.skip_previous,
          color: state.canGoPrevious ? enabled : disabled,
          size: tokens.iconSizeLarge,
        ),
        onPressed: state.canGoPrevious
            ? () => context.read<AudioPlayerBloc>().add(
                const AudioPlayerEvent.skipToPrevious(),
              )
            : null,
      ),
    );
    final Widget nextControl = Semantics(
      identifier: QuranPlayerSemanticsIds.transportNext,
      button: true,
      child: IconButton(
        icon: Icon(
          swapSkipSidesForArabic ? Icons.skip_previous : Icons.skip_next,
          color: state.canGoNext ? enabled : disabled,
          size: tokens.iconSizeLarge,
        ),
        onPressed: state.canGoNext
            ? () => context.read<AudioPlayerBloc>().add(
                const AudioPlayerEvent.skipToNext(),
              )
            : null,
      ),
    );

    // App locale is RTL for Arabic; keep transport LTR so skip sides do not
    // mirror twice (Row flip would undo the Arabic-only swap).
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Semantics(
            identifier: QuranPlayerSemanticsIds.transportShuffle,
            button: true,
            child: IconButton(
              icon: Icon(
                shuffleIcon,
                color: shuffleOn ? enabled : disabled,
                size: tokens.iconSizeLarge,
              ),
              onPressed: () {
                context.read<AudioPlayerBloc>().add(
                  AudioPlayerEvent.setShuffleMode(
                    QuranPlayerTransportControls.nextShuffleMode(
                      state.shuffleMode,
                    ),
                  ),
                );
              },
              tooltip: context.l10n.shufflePlaylist,
            ),
          ),
          if (swapSkipSidesForArabic) nextControl else previousControl,
          Semantics(
            identifier: QuranPlayerSemanticsIds.transportPlayPause,
            button: true,
            child: _PlayerPlayPauseAtom(
              isPlaying: isPlaying,
              onTap: () {
                context.read<AudioPlayerBloc>().add(
                  isPlaying
                      ? const AudioPlayerEvent.pauseAudio()
                      : const AudioPlayerEvent.playAudio(),
                );
              },
            ),
          ),
          if (swapSkipSidesForArabic) previousControl else nextControl,
          Semantics(
            identifier: QuranPlayerSemanticsIds.transportRepeat,
            button: true,
            child: IconButton(
              icon: Icon(
                repeatIcon,
                color: repeatActive ? enabled : disabled,
                size: tokens.iconSizeLarge,
              ),
              onPressed: () {
                context.read<AudioPlayerBloc>().add(
                  AudioPlayerEvent.setRepeatMode(
                    QuranPlayerTransportControls.nextRepeatMode(
                      state.repeatMode,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PlayerActionPillsMolecule extends StatelessWidget {
  const _PlayerActionPillsMolecule({required this.state});

  final AudioPlayerState state;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).tokens;
    final bool sleepEnabled = context
        .watch<SettingsCubit>()
        .state
        .isSleepTimerEnabled;
    // Match [_PlayerTransportRow]: fixed LTR band so pills do not mirror twice
    // under an RTL app locale during collapse/expand drag.
    return SizedBox(
      height: tokens.minInteractiveDimension,
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Row(
          mainAxisAlignment: .center,
          spacing: tokens.spaceSmall,
          children: [
            Semantics(
              identifier: QuranPlayerSemanticsIds.actionPillSpeed,
              button: true,
              child: _YtMusicActionPill(
                label: '${state.speed.toStringAsFixed(1)}x',
                icon: FluentIcons.gauge_24_regular,
                onTap: () {
                  final AudioPlayerBloc bloc = context.read<AudioPlayerBloc>();
                  showSliderDialog(
                    context: context,
                    title: context.l10n.playbackSpeed,
                    divisions: 8,
                    min: 0.5,
                    max: 2.5,
                    value: state.speed,
                    onChanged: (double speed) {
                      bloc.add(AudioPlayerEvent.setSpeed(speed));
                    },
                  );
                },
              ),
            ),
            Semantics(
              identifier: QuranPlayerSemanticsIds.actionPillVolume,
              button: true,
              child: _YtMusicActionPill(
                icon: FluentIcons.speaker_2_24_regular,
                onTap: () {
                  final AudioPlayerBloc bloc = context.read<AudioPlayerBloc>();
                  showSliderDialog(
                    context: context,
                    title: context.l10n.adjustVolume,
                    divisions: 10,
                    min: 0.0,
                    max: 1.0,
                    value: state.volume,
                    onChanged: (double volume) {
                      bloc.add(AudioPlayerEvent.setVolume(volume));
                    },
                  );
                },
              ),
            ),
            if (sleepEnabled) ...[
              Semantics(
                identifier: QuranPlayerSemanticsIds.actionPillSleepTimer,
                button: true,
                child: _YtMusicActionPill(
                  icon: state.isSleepTimerActive
                      ? FluentIcons.timer_24_filled
                      : FluentIcons.timer_24_regular,
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (_) => const SleepTimerDialog(),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _YtMusicActionPill extends StatelessWidget {
  const _YtMusicActionPill({
    this.label,
    required this.icon,
    required this.onTap,
  });

  final String? label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).tokens;
    final palette = _ExpandedPlayerPalette.of(context);
    final double radius = tokens.resolveRadius(
      family: TilawaRadiusFamily.pill,
      height: tokens.minInteractiveDimension,
    );
    return ConstrainedBox(
      constraints: BoxConstraints(
        minWidth: tokens.minInteractiveDimension,
        minHeight: tokens.minInteractiveDimension,
      ),
      child: Material(
        color: palette.pillBackground,
        borderRadius: BorderRadius.circular(radius),
        child: InkWell(
          borderRadius: BorderRadius.circular(radius),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: tokens.spaceMedium,
              vertical: tokens.spaceSmall,
            ),
            child: Row(
              mainAxisSize: .min,
              mainAxisAlignment: .center,
              spacing: tokens.spaceExtraSmall,
              children: [
                Icon(
                  icon,
                  color: palette.foreground,
                  size: tokens.iconSizeMedium,
                ),
                if (label != null)
                  Text(
                    label!,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: palette.foreground,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
