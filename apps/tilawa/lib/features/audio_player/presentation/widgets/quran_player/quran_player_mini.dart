part of 'quran_player_widget.dart';
// ---------------------------------------------------------------------------
// Atoms
// ---------------------------------------------------------------------------

class _PlayerArtAtom extends StatelessWidget {
  const _PlayerArtAtom({
    this.audioId,
    this.artUri,
    this.useHeroArtwork = false,
  }) : maxHeight = null;

  final String? audioId;
  final String? artUri;
  final double? maxHeight;
  final bool useHeroArtwork;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).tokens;
    final Widget artwork = useHeroArtwork && audioId != null
        ? LayoutBuilder(
            builder: (context, constraints) {
              final double width = constraints.maxWidth.isFinite
                  ? constraints.maxWidth
                  : MediaQuery.sizeOf(context).width - tokens.spaceLarge * 2;
              final double height = maxHeight ?? width * 9 / 16;
              return QuranPlayerHeroArtwork(
                audioId: audioId!,
                artUri: artUri,
                borderRadius: BorderRadius.circular(tokens.radiusLarge),
                size: Size(width, height),
                semanticDestination: true,
              );
            },
          )
        : ClipRRect(
            borderRadius: BorderRadius.circular(tokens.radiusLarge),
            child: artUri != null
                ? CachedNetworkImage(
                    imageUrl: artUri!,
                    fit: BoxFit.cover,
                    errorWidget: (context, url, error) =>
                        _buildDefaultArt(context),
                  )
                : _buildDefaultArt(context),
          );

    final Widget sizedArt = useHeroArtwork && audioId != null
        ? artwork
        : maxHeight != null
        ? SizedBox(
            height: maxHeight,
            width: double.infinity,
            child: artwork,
          )
        : AspectRatio(aspectRatio: 16 / 9, child: artwork);

    if (useHeroArtwork) {
      return sizedArt;
    }

    return Semantics(
      identifier: QuranPlayerSemanticsIds.expandedArtwork,
      image: true,
      child: sizedArt,
    );
  }

  Widget _buildDefaultArt(BuildContext context) {
    final tokens = Theme.of(context).tokens;
    final palette = _ExpandedPlayerPalette.of(context);
    return ColoredBox(
      color: palette.artworkBackground,
      child: Center(
        child: Icon(
          FluentIcons.music_note_2_24_filled,
          size: tokens.iconSizeLarge * 3.3, // approx 80
          color: palette.artworkIcon,
        ),
      ),
    );
  }
}

class _PlayerPlayPauseAtom extends StatelessWidget {
  const _PlayerPlayPauseAtom({
    required this.isPlaying,
    required this.onTap,
    this.isPlaybackStalled = false,
  });

  final bool isPlaying;
  final VoidCallback onTap;
  final bool isPlaybackStalled;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).tokens;
    final palette = _ExpandedPlayerPalette.of(context);
    final buttonSize = tokens.iconSizeLarge * 3.3; // approx 80
    return Container(
      width: buttonSize,
      height: buttonSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: palette.playButtonBackground,
        boxShadow: [
          BoxShadow(
            color: palette.playButtonGlow,
            blurRadius: tokens.spaceLarge,
            spreadRadius: tokens.spaceTiny,
          ),
        ],
      ),
      child: IconButton(
        icon: isPlaybackStalled
            ? SizedBox(
                width: tokens.iconSizeLarge * 1.6,
                height: tokens.iconSizeLarge * 1.6,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: palette.playButtonIcon,
                ),
              )
            : Icon(
                isPlaying
                    ? FluentIcons.pause_48_filled
                    : FluentIcons.play_48_filled,
                color: palette.playButtonIcon,
                size: tokens.iconSizeLarge * 1.6, // approx 40
              ),
        onPressed: onTap,
      ),
    );
  }
}

@immutable
class _MiniPlayerSnapshot {
  const _MiniPlayerSnapshot({
    required this.progress,
    required this.isPlaying,
    required this.canGoPrevious,
    required this.canGoNext,
    required this.isSleepTimerActive,
    required this.isPlaybackStalled,
  });

  final double progress;
  final bool isPlaying;
  final bool canGoPrevious;
  final bool canGoNext;
  final bool isSleepTimerActive;
  final bool isPlaybackStalled;

  static _MiniPlayerSnapshot fromState(AudioPlayerState state) {
    final bool isRadio = RadioPlaybackMapper.isRadioAudio(state.currentAudio);
    final PositionData? data = state.positionData;
    final double progress =
        isRadio || data == null || data.duration.inMilliseconds == 0
        ? 0.0
        : data.position.inMilliseconds / data.duration.inMilliseconds;
    return _MiniPlayerSnapshot(
      progress: progress.clamp(0.0, 1.0),
      isPlaying: state.isPlaying,
      canGoPrevious: !isRadio && state.canGoPrevious,
      canGoNext: !isRadio && state.canGoNext,
      isSleepTimerActive: state.isSleepTimerActive,
      isPlaybackStalled: state.isPlaybackStalled,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _MiniPlayerSnapshot &&
          progress == other.progress &&
          isPlaying == other.isPlaying &&
          canGoPrevious == other.canGoPrevious &&
          canGoNext == other.canGoNext &&
          isSleepTimerActive == other.isSleepTimerActive &&
          isPlaybackStalled == other.isPlaybackStalled;

  @override
  int get hashCode => Object.hash(
    progress,
    isPlaying,
    canGoPrevious,
    canGoNext,
    isSleepTimerActive,
    isPlaybackStalled,
  );
}

class _YtMusicMiniPlayer extends StatelessWidget {
  const _YtMusicMiniPlayer({
    required this.audio,
    this.useHeroArtwork = false,
    required this.identityChromeOpacity,
    required this.onTap,
    this.onSubtitleTap,
    required this.onClose,
    this.shellPillLayout = false,
    this.shellDockLayout = false,
  });

  final AudioEntity audio;
  final bool useHeroArtwork;
  final double identityChromeOpacity;
  final VoidCallback onTap;
  final VoidCallback? onSubtitleTap;
  final VoidCallback onClose;
  final bool shellPillLayout;
  final bool shellDockLayout;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<AudioPlayerBloc, AudioPlayerState, _MiniPlayerSnapshot>(
      selector: _MiniPlayerSnapshot.fromState,
      builder: (context, snapshot) {
        return _YtMusicMiniPlayerBody(
          audio: audio,
          useHeroArtwork: useHeroArtwork,
          snapshot: snapshot,
          identityChromeOpacity: identityChromeOpacity,
          onTap: onTap,
          onSubtitleTap: onSubtitleTap,
          onClose: onClose,
          shellPillLayout: shellPillLayout,
          shellDockLayout: shellDockLayout,
        );
      },
    );
  }
}

class _YtMusicMiniPlayerBody extends StatelessWidget {
  const _YtMusicMiniPlayerBody({
    required this.audio,
    this.useHeroArtwork = false,
    required this.snapshot,
    required this.identityChromeOpacity,
    required this.onTap,
    this.onSubtitleTap,
    required this.onClose,
    this.shellPillLayout = false,
    this.shellDockLayout = false,
  });

  final AudioEntity audio;
  final bool useHeroArtwork;
  final _MiniPlayerSnapshot snapshot;
  final double identityChromeOpacity;
  final VoidCallback onTap;
  final VoidCallback? onSubtitleTap;
  final VoidCallback onClose;
  final bool shellPillLayout;
  final bool shellDockLayout;

  @override
  Widget build(BuildContext context) {
    final barTokens = Theme.of(context).componentTokens.mediaPlayerBar;
    final shellTokens = Theme.of(context).componentTokens.adaptiveShell;
    final theme = Theme.of(context);
    final designTokens = theme.tokens;
    final bool sleepTimerEnabled =
        !(shellPillLayout || shellDockLayout) &&
        context.watch<SettingsCubit>().state.isSleepTimerEnabled;
    final bool isRadio = RadioPlaybackMapper.isRadioAudio(audio);
    final String subtitle = isRadio
        ? context.l10n.radioLive
        : (audio.artist ?? context.l10n.unknownReciter);
    final TextStyle titleStyle =
        (theme.textTheme.titleSmall ?? const TextStyle()).copyWith(
          fontWeight: barTokens.titleFontWeight,
          color: theme.colorScheme.onSurface,
        );
    final TextStyle subtitleStyle =
        (theme.textTheme.bodySmall ?? const TextStyle()).copyWith(
          color: theme.colorScheme.onSurfaceVariant.withValues(
            alpha: barTokens.subtitleOpacity,
          ),
        );
    final Widget? artwork = audio.artUri == null
        ? null
        : useHeroArtwork
        ? QuranPlayerHeroArtwork(
            audioId: audio.id,
            artUri: audio.artUri,
            borderRadius: BorderRadius.circular(barTokens.artworkRadius),
            size: Size.square(
              shellPillLayout
                  ? kTilawaMediaPlayerBarShellArtworkSize
                  : shellDockLayout
                  ? kTilawaMediaPlayerBarCompactArtworkSize
                  : barTokens.artworkSize,
            ),
          )
        : ClipRRect(
            borderRadius: BorderRadius.circular(barTokens.artworkRadius),
            child: CachedNetworkImage(
              imageUrl: audio.artUri!,
              fit: BoxFit.cover,
              errorWidget: (context, error, stackTrace) =>
                  const SizedBox.shrink(),
            ),
          );

    final Widget? titleSubtitle = useHeroArtwork
        ? QuranPlayerHeroMetadata(
            audioId: audio.id,
            title: audio.title,
            subtitle: subtitle,
            titleStyle: titleStyle,
            subtitleStyle: subtitleStyle,
          )
        : null;

    return Semantics(
      identifier: QuranPlayerSemanticsIds.miniPlayer,
      container: true,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return TilawaMediaPlayerBar(
            layoutWidth: constraints.maxWidth,
            title: audio.title,
            subtitle: subtitle,
            titleSubtitle: titleSubtitle,
            artwork: artwork,
            identityChromeOpacity: identityChromeOpacity,
            progress: snapshot.progress,
            progressBarOverride: isRadio
                ? _RadioLiveProgressBand(
                    isBuffering: snapshot.isPlaybackStalled,
                  )
                : null,
            isPlaying: snapshot.isPlaying,
            isPlaybackStalled: snapshot.isPlaybackStalled,
            canGoPrevious: snapshot.canGoPrevious,
            canGoNext: snapshot.canGoNext,
            isSleepTimerActive: snapshot.isSleepTimerActive,
            isSleepTimerEnabled: sleepTimerEnabled,
            shellPillLayout: shellPillLayout,
            shellDockLayout: shellDockLayout,
            pillBorderRadius: shellPillLayout
                ? designTokens.radiusPill(constraints.maxHeight)
                : null,
            backgroundColorOverride: shellPillLayout
                ? shellTokens.bottomNavBackgroundColor
                : null,
            contentPaddingOverride: shellDockLayout
                ? EdgeInsets.symmetric(
                    horizontal: designTokens.spaceMedium,
                  )
                : shellPillLayout
                ? EdgeInsets.symmetric(
                    horizontal: shellTokens.bottomNavInternalPadding,
                  )
                : null,
            onTap: onTap,
            onSubtitleTap: onSubtitleTap,
            onClose: onClose,
            playPauseSemanticIdentifier:
                QuranPlayerSemanticsIds.miniPlayerPlayPause,
            closeSemanticIdentifier: QuranPlayerSemanticsIds.miniPlayerClose,
            onPlayPause: () {
              context.read<AudioPlayerBloc>().add(
                snapshot.isPlaying
                    ? const AudioPlayerEvent.pauseAudio()
                    : const AudioPlayerEvent.playAudio(),
              );
            },
            onPrevious: snapshot.canGoPrevious
                ? () => context.read<AudioPlayerBloc>().add(
                    const AudioPlayerEvent.skipToPrevious(),
                  )
                : null,
            onNext: snapshot.canGoNext
                ? () => context.read<AudioPlayerBloc>().add(
                    const AudioPlayerEvent.skipToNext(),
                  )
                : null,
            onSleepTimerTap: sleepTimerEnabled
                ? () {
                    showDialog<void>(
                      context: context,
                      builder: (_) => const SleepTimerDialog(),
                    );
                  }
                : null,
            playTooltip: context.l10n.play,
            pauseTooltip: context.l10n.pause,
            previousTooltip: context.l10n.previous,
            nextTooltip: context.l10n.next,
            openPlayerSemanticLabel: audio.title,
          );
        },
      ),
    );
  }
}

class _MiniArtwork extends StatelessWidget {
  const _MiniArtwork({required this.artUri, required this.size});

  final String? artUri;
  final double size;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).tokens;
    final barTokens = Theme.of(context).componentTokens.mediaPlayerBar;
    final colorScheme = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(tokens.radiusSmall),
      child: SizedBox(
        width: size,
        height: size,
        child: artUri == null
            ? ColoredBox(
                color: barTokens.artworkPlaceholderColor,
                child: Icon(
                  FluentIcons.music_note_2_24_filled,
                  color: colorScheme.onSurfaceVariant,
                ),
              )
            : CachedNetworkImage(
                imageUrl: artUri!,
                fit: BoxFit.cover,
                errorWidget: (context, error, stackTrace) =>
                    const SizedBox.shrink(),
              ),
      ),
    );
  }
}

/// Slim top-band for live radio: indeterminate while buffering, solid when live.
class _RadioLiveProgressBand extends StatelessWidget {
  const _RadioLiveProgressBand({required this.isBuffering});

  final bool isBuffering;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).tokens;
    final barTokens = Theme.of(context).componentTokens.mediaPlayerBar;
    final colorScheme = Theme.of(context).colorScheme;
    return LinearProgressIndicator(
      value: isBuffering ? null : 1.0,
      backgroundColor: barTokens.progressTrackBackgroundColor,
      valueColor: AlwaysStoppedAnimation<Color>(
        isBuffering ? colorScheme.primary : colorScheme.error,
      ),
      minHeight: tokens.progressHeight,
    );
  }
}
