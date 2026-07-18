import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/features/audio_player/presentation/bloc/audio_player_bloc.dart';
import 'package:tilawa/helpers/show_slider_dialog.dart';
import 'package:tilawa_core/entities/audio.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../domain/entities/radio_station.dart';
import '../cubit/radio_cubit.dart';
import '../cubit/radio_state.dart';
import '../widgets/radio_live_badge.dart';
import '../widgets/radio_playback_actions.dart';
import '../widgets/radio_station_artwork.dart';

class RadioPlayerPage extends StatelessWidget {
  const RadioPlayerPage({super.key, required this.stationId});

  final String stationId;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RadioCubit, RadioState>(
      builder: (context, radioState) {
        RadioStation? station;
        for (final RadioStation candidate in [
          ...radioState.stations,
          ...radioState.favorites,
          ...radioState.recent,
        ]) {
          if (candidate.id == stationId) {
            station = candidate;
            break;
          }
        }
        station ??= radioState.featured;

        if (station == null) {
          return TilawaShellChildScaffold(
            appBar: TilawaAppBar(title: context.l10n.radioTitle),
            body: TilawaErrorState(
              icon: Icons.radio_rounded,
              title: context.l10n.radioErrorTitle,
              subtitle: context.l10n.radioErrorGeneric,
              retryLabel: context.l10n.retry,
              onRetry: () => Navigator.of(context).maybePop(),
            ),
          );
        }

        return _RadioPlayerBody(station: station);
      },
    );
  }
}

class _RadioPlayerBody extends StatelessWidget {
  const _RadioPlayerBody({required this.station});

  final RadioStation station;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return TilawaShellChildScaffold(
      appBar: TilawaAppBar(
        title: l10n.radioNowPlaying,
        actions: [
          IconButton(
            tooltip: l10n.radioShare,
            onPressed: () => RadioPlaybackActions.share(context, station),
            icon: const Icon(Icons.share_rounded),
          ),
        ],
      ),
      body: BlocBuilder<AudioPlayerBloc, AudioPlayerState>(
        builder: (context, audioState) {
          final AudioEntity? current = audioState.currentAudio;
          final bool isThisStation =
              current?.id == station.audioId ||
              current?.id == 'radio:${station.id}';
          final bool isPlaying = isThisStation && audioState.isPlaying;
          final bool isBuffering =
              isThisStation && audioState.isPlaybackStalled;

          return SafeArea(
            child: Padding(
              padding: EdgeInsets.all(tokens.spaceLarge),
              child: Column(
                children: [
                  const Spacer(),
                  RadioStationArtwork(
                    stationId: station.id,
                    size: MediaQuery.sizeOf(context).shortestSide * 0.55,
                  ),
                  SizedBox(height: tokens.spaceLarge),
                  Text(
                    station.name,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: tokens.spaceMedium),
                  RadioLiveBadge(isBuffering: isBuffering),
                  SizedBox(height: tokens.spaceExtraLarge),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        tooltip: station.isFavorite
                            ? l10n.radioRemoveFavorite
                            : l10n.radioAddFavorite,
                        iconSize: tokens.iconSizeLarge,
                        onPressed: () => context
                            .read<RadioCubit>()
                            .toggleFavorite(station.id),
                        icon: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: Icon(
                            station.isFavorite
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            key: ValueKey<bool>(station.isFavorite),
                            color: station.isFavorite
                                ? theme.colorScheme.error
                                : null,
                          ),
                        ),
                      ),
                      SizedBox(width: tokens.spaceMedium),
                      IconButton.filled(
                        tooltip: isPlaying ? l10n.pause : l10n.play,
                        iconSize: tokens.iconSizeLarge,
                        onPressed: () async {
                          if (isPlaying) {
                            context.read<AudioPlayerBloc>().add(
                              const AudioPlayerEvent.pauseAudio(),
                            );
                          } else {
                            await RadioPlaybackActions.play(context, station);
                          }
                        },
                        icon: Icon(
                          isPlaying
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                        ),
                      ),
                      SizedBox(width: tokens.spaceMedium),
                      IconButton(
                        tooltip: l10n.radioStop,
                        iconSize: tokens.iconSizeLarge,
                        onPressed: () => RadioPlaybackActions.stop(context),
                        icon: const Icon(Icons.stop_rounded),
                      ),
                    ],
                  ),
                  SizedBox(height: tokens.spaceLarge),
                  Wrap(
                    spacing: tokens.spaceSmall,
                    runSpacing: tokens.spaceSmall,
                    alignment: WrapAlignment.center,
                    children: [
                      TilawaButton(
                        text: l10n.radioSleepTimer,
                        variant: TilawaButtonVariant.outline,
                        leadingIcon: const Icon(Icons.bedtime_outlined),
                        onPressed: () =>
                            RadioPlaybackActions.showSleepTimer(context),
                      ),
                      TilawaButton(
                        text: l10n.radioVolume,
                        variant: TilawaButtonVariant.outline,
                        leadingIcon: const Icon(Icons.volume_up_rounded),
                        onPressed: () {
                          final AudioPlayerBloc bloc = context
                              .read<AudioPlayerBloc>();
                          showSliderDialog(
                            context: context,
                            title: l10n.radioVolume,
                            divisions: 20,
                            min: 0,
                            max: 1,
                            value: bloc.state.volume,
                            onChanged: (double volume) {
                              bloc.add(AudioPlayerEvent.setVolume(volume));
                            },
                          );
                        },
                      ),
                      TilawaButton(
                        text: l10n.radioShare,
                        variant: TilawaButtonVariant.outline,
                        leadingIcon: const Icon(Icons.share_rounded),
                        onPressed: () =>
                            RadioPlaybackActions.share(context, station),
                      ),
                    ],
                  ),
                  const Spacer(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
