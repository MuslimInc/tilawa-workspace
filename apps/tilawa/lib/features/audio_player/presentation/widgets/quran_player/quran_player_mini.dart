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
  const _PlayerPlayPauseAtom({required this.isPlaying, required this.onTap});

  final bool isPlaying;
  final VoidCallback onTap;

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
        icon: Icon(
          isPlaying ? FluentIcons.pause_48_filled : FluentIcons.play_48_filled,
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
  });

  final double progress;
  final bool isPlaying;
  final bool canGoPrevious;
  final bool canGoNext;
  final bool isSleepTimerActive;

  static _MiniPlayerSnapshot fromState(AudioPlayerState state) {
    final PositionData? data = state.positionData;
    final double progress = data == null || data.duration.inMilliseconds == 0
        ? 0.0
        : data.position.inMilliseconds / data.duration.inMilliseconds;
    return _MiniPlayerSnapshot(
      progress: progress.clamp(0.0, 1.0),
      isPlaying: state.isPlaying,
      canGoPrevious: state.canGoPrevious,
      canGoNext: state.canGoNext,
      isSleepTimerActive: state.isSleepTimerActive,
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
          isSleepTimerActive == other.isSleepTimerActive;

  @override
  int get hashCode => Object.hash(
    progress,
    isPlaying,
    canGoPrevious,
    canGoNext,
    isSleepTimerActive,
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
  });

  final AudioEntity audio;
  final bool useHeroArtwork;
  final double identityChromeOpacity;
  final VoidCallback onTap;
  final VoidCallback? onSubtitleTap;
  final VoidCallback onClose;
  final bool shellPillLayout;

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
  });

  final AudioEntity audio;
  final bool useHeroArtwork;
  final _MiniPlayerSnapshot snapshot;
  final double identityChromeOpacity;
  final VoidCallback onTap;
  final VoidCallback? onSubtitleTap;
  final VoidCallback onClose;
  final bool shellPillLayout;

  @override
  Widget build(BuildContext context) {
    final barTokens = Theme.of(context).componentTokens.mediaPlayerBar;
    final shellTokens = Theme.of(context).componentTokens.adaptiveShell;
    final theme = Theme.of(context);
    final designTokens = theme.tokens;
    final bool sleepTimerEnabled = shellPillLayout
        ? false
        : context.watch<SettingsCubit>().state.isSleepTimerEnabled;
    final String subtitle = audio.artist ?? context.l10n.unknownReciter;
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
            isPlaying: snapshot.isPlaying,
            canGoPrevious: snapshot.canGoPrevious,
            canGoNext: snapshot.canGoNext,
            isSleepTimerActive: snapshot.isSleepTimerActive,
            isSleepTimerEnabled: sleepTimerEnabled,
            shellPillLayout: shellPillLayout,
            pillBorderRadius: shellPillLayout
                ? designTokens.radiusPill(constraints.maxHeight)
                : null,
            backgroundColorOverride: shellPillLayout
                ? shellTokens.bottomNavBackgroundColor
                : null,
            contentPaddingOverride: shellPillLayout
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
