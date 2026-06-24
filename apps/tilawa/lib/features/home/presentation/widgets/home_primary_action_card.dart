import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/features/athkar/presentation/athkar_category_presentation.dart';
import 'package:tilawa/features/audio_player/presentation/bloc/audio_player_bloc.dart';
import 'package:tilawa/features/home/presentation/cubit/home_athkar_compact_state.dart';
import 'package:tilawa/features/home/presentation/cubit/home_listening_resume_cubit.dart';
import 'package:tilawa/features/home/presentation/cubit/home_listening_resume_state.dart';
import 'package:tilawa/features/home/presentation/cubit/home_primary_action_state.dart';
import 'package:tilawa/router/app_router_config.dart';
import 'package:tilawa_core/entities/entities.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import 'home_dashboard_card.dart';
import 'home_quran_resume_card.dart';

/// Featured primary action card — gradient only for Quran resume.
class HomePrimaryActionCard extends StatelessWidget {
  const HomePrimaryActionCard({super.key, required this.state});

  final HomePrimaryActionState state;

  @override
  Widget build(BuildContext context) {
    return switch (state.kind) {
      HomePrimaryActionKind.quran => const HomeQuranResumeCard(
        featured: true,
      ),
      HomePrimaryActionKind.listening => const _HomePrimaryListeningCard(),
      HomePrimaryActionKind.athkar => _HomePrimaryAthkarCard(
        row: state.urgentAthkarRow!,
      ),
    };
  }
}

class _HomePrimaryListeningCard extends StatelessWidget {
  const _HomePrimaryListeningCard();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeListeningResumeCubit, HomeListeningResumeState>(
      builder: (context, listeningState) {
        if (!listeningState.isVisible) {
          return const HomeQuranResumeCard(featured: true);
        }

        final tokens = context.tokens;
        final theme = Theme.of(context);
        final cardTokens = theme.componentTokens.homeDashboardCard;
        final Color foreground = theme.colorScheme.onSurface;

        return Semantics(
          button: true,
          label: context.l10n.continueListening,
          value: context.l10n.homeListeningResumeSubtitle(
            listeningState.reciterName!,
            listeningState.surahName!,
          ),
          child: HomeDashboardCard(
            surface: TilawaCardSurface.raised,
            onTap: () => _resumePlayback(context, listeningState),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.headphones_rounded,
                  color: theme.colorScheme.primary,
                  size: tokens.iconSizeLarge,
                ),
                SizedBox(width: tokens.spaceMedium),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l10n.continueListening,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: tokens.spaceExtraSmall),
                      Text(
                        context.l10n.homeListeningResumeSubtitle(
                          listeningState.reciterName!,
                          listeningState.surahName!,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: foreground.withValues(alpha: 0.82),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: cardTokens.foregroundColor.withValues(alpha: 0.82),
                ),
              ],
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

class _HomePrimaryAthkarCard extends StatelessWidget {
  const _HomePrimaryAthkarCard({required this.row});

  final HomeAthkarRowState row;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final String title = localizedAthkarCategoryTitle(context, row.category);
    final String statusText = switch (row.completion) {
      HomeAthkarCompletionState.done => context.l10n.homeAthkarDone,
      HomeAthkarCompletionState.inProgress => context.l10n.homeAthkarRemaining(
        row.remainingCount,
      ),
      HomeAthkarCompletionState.notStarted => context.l10n.homeAthkarNotStarted,
    };

    return Semantics(
      button: true,
      label: title,
      value: statusText,
      child: HomeDashboardCard(
        surface: TilawaCardSurface.raised,
        onTap: () => AthkarDetailsRoute(
          categoryId: row.category.id,
          categoryName: title,
          source: 'home_primary',
        ).push(context),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              athkarCategoryIcon(row.category.icon),
              color: colorScheme.primary,
              size: tokens.iconSizeLarge,
            ),
            SizedBox(width: tokens.spaceMedium),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: tokens.spaceExtraSmall),
                  Text(
                    statusText,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}
