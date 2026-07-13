import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/features/audio_player/presentation/bloc/audio_player_bloc.dart';
import 'package:tilawa/features/home/presentation/widgets/home_dashboard_elevated_surface.dart';
import 'package:tilawa/features/home/presentation/cubit/home_listening_resume_cubit.dart';
import 'package:tilawa/features/home/presentation/cubit/home_listening_resume_state.dart';
import 'package:tilawa_core/entities/entities.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

/// Conditional continue-listening row for the YOURS layer.
class HomeListeningResumeRow extends StatelessWidget {
  const HomeListeningResumeRow({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeListeningResumeCubit, HomeListeningResumeState>(
      builder: (context, state) {
        if (!state.isVisible) {
          return const SizedBox.shrink();
        }

        final tokens = context.tokens;
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;
        // Match the corner radius of the surrounding dashboard cards.
        final double radius = tokens.resolveRadius(
          family: TilawaRadiusFamily.hero,
        );

        final BorderRadius borderRadius = BorderRadius.circular(radius);

        return Semantics(
          button: true,
          label: context.l10n.continueListening,
          value: context.l10n.homeListeningResumeSubtitle(
            state.reciterName!,
            state.surahName!,
          ),
          child: HomeDashboardElevatedSurface.interactive(
            context: context,
            borderRadius: borderRadius,
            onTap: () => _resumePlayback(context, state),
            button: false,
            stateLayerColor: colorScheme.primary,
            color: colorScheme.surfaceContainerLow,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: tokens.spaceMedium,
                vertical: tokens.spaceSmall,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.headphones_rounded,
                    color: colorScheme.primary,
                    size: tokens.iconSizeSmall,
                  ),
                  SizedBox(width: tokens.spaceSmall),
                  Expanded(
                    child: Text(
                      context.l10n.homeListeningResumeSubtitle(
                        state.reciterName!,
                        state.surahName!,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _resumePlayback(
    BuildContext context,
    HomeListeningResumeState state,
  ) {
    final audio = AudioEntity(
      id: state.audioUrl!,
      title: state.surahName!,
      url: state.audioUrl!,
      duration: Duration(milliseconds: state.durationMs),
      artist: state.reciterName,
      album: state.moshafName,
      artUri: state.artworkUrl,
      extras: {
        'surahId': state.surahId,
        'reciterId': state.reciterId,
        'moshafId': state.moshafId,
      },
    );

    context.read<AudioPlayerBloc>().add(
      AudioPlayerEvent.playFromQueue(
        [audio],
        0,
        initialPosition: Duration(milliseconds: state.lastPositionMs),
      ),
    );
  }
}
