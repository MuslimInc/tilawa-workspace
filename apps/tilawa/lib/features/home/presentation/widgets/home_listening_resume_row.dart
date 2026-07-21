import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/features/audio_player/presentation/bloc/audio_player_bloc.dart';
import 'package:tilawa/features/home/presentation/cubit/home_listening_resume_cubit.dart';
import 'package:tilawa/features/home/presentation/cubit/home_listening_resume_state.dart';
import 'package:tilawa/features/home/presentation/widgets/home_dashboard_elevated_surface.dart';
import 'package:tilawa/features/home/presentation/widgets/home_dashboard_icon_well.dart';
import 'package:tilawa/features/home/presentation/widgets/home_dashboard_section.dart';
import 'package:tilawa/features/home/presentation/widgets/home_feature_pastel.dart';
import 'package:tilawa_core/entities/entities.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

/// Conditional continue-listening row for the YOURS layer.
///
/// White elevated card + accent icon well — same surface language as More /
/// primary tiles (no gray body wash).
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
        final Color accent = colorScheme.primary;
        final double radius = tokens.resolveRadius(
          family: TilawaRadiusFamily.hero,
        );
        final BorderRadius borderRadius = BorderRadius.circular(radius);
        final String resumeLabel = context.l10n.continueListening;
        final String baseSubtitle = context.l10n.homeListeningResumeSubtitle(
          state.reciterName!,
          state.surahName!,
        );
        final double? progressFraction = _listeningProgressFraction(state);
        final String subtitle = progressFraction == null
            ? baseSubtitle
            : '$baseSubtitle · ${context.l10n.homeListeningResumePercent(
                (progressFraction * 100).round(),
              )}';

        return Semantics(
          button: true,
          label: resumeLabel,
          value: subtitle,
          child: HomeDashboardElevatedSurface.interactive(
            context: context,
            borderRadius: borderRadius,
            onTap: () => _resumePlayback(context, state),
            button: false,
            stateLayerColor: accent,
            color: HomeFeaturePastel.cardSurface(colorScheme),
            tier: HomeDashboardElevationTier.inspiration,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: tokens.spaceMedium,
                vertical: tokens.spaceSmall,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: tokens.spaceSmall,
                children: [
                  Row(
                    spacing: tokens.spaceSmall,
                    children: [
                      HomeDashboardIconWell(
                        accent: accent,
                        fillAlpha: HomeFeaturePastel.iconWellFillAlpha,
                        extent: tokens.iconBoxSize,
                        child: Icon(
                          Icons.headphones_rounded,
                          color: accent,
                          size: tokens.iconSizeSmall,
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          spacing: tokens.spaceExtraSmall,
                          children: [
                            TilawaStatusChip(
                              label: resumeLabel,
                              backgroundColor:
                                  HomeFeaturePastel.statusChipBackground(
                                    accent: accent,
                                    colorScheme: colorScheme,
                                  ),
                              foregroundColor: accent,
                            ),
                            Text(
                              subtitle,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: HomeDashboardSection.secondaryTextColor(context),
                      ),
                    ],
                  ),
                  if (progressFraction != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(tokens.radiusSmall),
                      child: LinearProgressIndicator(
                        value: progressFraction,
                        minHeight: tokens.progressHeight,
                        backgroundColor: accent.withValues(alpha: 0.12),
                        color: accent,
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Goal-gradient fraction when duration is known; null otherwise.
  static double? _listeningProgressFraction(HomeListeningResumeState state) {
    if (state.completed) {
      return 1.0;
    }
    if (state.durationMs <= 0) {
      return null;
    }
    return (state.lastPositionMs / state.durationMs).clamp(0.0, 1.0);
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
        initialPosition: state.resumeInitialPosition,
      ),
    );
  }
}
