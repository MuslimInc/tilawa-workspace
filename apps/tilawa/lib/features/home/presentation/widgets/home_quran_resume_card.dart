import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tilawa/core/di/injection.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/features/audio_player/presentation/bloc/audio_player_bloc.dart';
import 'package:tilawa/features/audio_player/presentation/player_presentation_controller.dart';
import 'package:tilawa/features/audio_player/presentation/quran_player_presentation_entry.dart';
import 'package:tilawa/features/home/domain/constants/quran_mushaf_constants.dart';
import 'package:tilawa/features/home/presentation/cubit/home_quran_resume_cubit.dart';
import 'package:tilawa/features/home/presentation/cubit/home_quran_resume_state.dart';
import 'package:tilawa/l10n/generated/app_localizations.dart';
import 'package:tilawa/router/app_router_config.dart';
import 'package:tilawa_core/entities/entities.dart';
import 'package:tilawa_core/utils/surah_names.dart';
import 'package:tilawa/features/home/presentation/widgets/home_dashboard_card.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

/// Featured Mushaf resume entry with optional page progress ring.
class HomeQuranResumeCard extends StatelessWidget {
  const HomeQuranResumeCard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeQuranResumeCubit, HomeQuranResumeState>(
      builder: (context, state) {
        return switch (state.status) {
          HomeQuranResumeStatus.loading ||
          HomeQuranResumeStatus.initial => const _HomeQuranResumeLoadingCard(),
          HomeQuranResumeStatus.failure => _HomeQuranResumeAudioScope(
            readingSubtitle: context.l10n.homeContinueQuranSubtitle,
            progress: null,
            showProgress: false,
          ),
          HomeQuranResumeStatus.ready => _HomeQuranResumeAudioScope(
            readingSubtitle: _resumeSubtitle(context, state),
            progress: state.progressFraction(QuranMushafConstants.pageCount),
            showProgress: _shouldShowProgress(state),
          ),
        };
      },
    );
  }

  bool _isFreshStart(HomeQuranResumeState state) {
    if (!state.hasResumePosition) {
      return true;
    }
    final int? page = state.page;
    return page == null || page <= 1;
  }

  bool _shouldShowProgress(HomeQuranResumeState state) {
    if (_isFreshStart(state)) {
      return false;
    }
    final double? progress = state.progressFraction(
      QuranMushafConstants.pageCount,
    );
    return progress != null && progress > 0;
  }

  String _resumeSubtitle(BuildContext context, HomeQuranResumeState state) {
    final AppLocalizations l10n = context.l10n;
    if (!state.hasResumePosition || _isFreshStart(state)) {
      return l10n.homeStartQuranSubtitle;
    }

    final int? page = state.page;
    final int? surahNumber = state.surahNumber;
    if (surahNumber != null) {
      final String surahName = context.isArabic
          ? SurahNames.getArabicSurahName(surahNumber)
          : SurahNames.getEnglishSurahName(surahNumber);
      if (page != null) {
        return l10n.homeQuranResumeSurahPage(surahName, page);
      }
      return surahName;
    }
    if (page != null) {
      return l10n.homeQuranResumePage(page);
    }
    return l10n.homeContinueQuranSubtitle;
  }
}

class _HomeQuranResumeAudioScope extends StatelessWidget {
  const _HomeQuranResumeAudioScope({
    required this.readingSubtitle,
    required this.progress,
    required this.showProgress,
  });

  final String readingSubtitle;
  final double? progress;
  final bool showProgress;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AudioPlayerBloc, AudioPlayerState>(
      buildWhen: (previous, current) =>
          previous.currentAudio != current.currentAudio ||
          previous.status != current.status ||
          previous.dismissedAudioId != current.dismissedAudioId,
      builder: (context, audioState) {
        return _HomeQuranResumeReadyCard(
          readingSubtitle: readingSubtitle,
          listeningSubtitle: _listeningSubtitle(context, audioState),
          progress: progress,
          showProgress: showProgress,
          hasActiveAudio: audioState.hasAudio,
        );
      },
    );
  }

  String _listeningSubtitle(BuildContext context, AudioPlayerState state) {
    final AudioEntity? audio = state.currentAudio;
    if (audio == null) {
      return context.l10n.todayPlanChooseReciter;
    }
    final String? reciterName = audio.artist;
    if (reciterName == null || reciterName.isEmpty) {
      return audio.title;
    }
    return context.l10n.todayPlanListeningSubtitle(audio.title, reciterName);
  }
}

class _HomeQuranResumeLoadingCard extends StatelessWidget {
  const _HomeQuranResumeLoadingCard();

  @override
  Widget build(BuildContext context) {
    return const HomeDashboardCard(
      surface: TilawaCardSurface.raised,
      child: TilawaLoadingIndicator(centered: false),
    );
  }
}

class _HomeQuranResumeReadyCard extends StatelessWidget {
  const _HomeQuranResumeReadyCard({
    required this.readingSubtitle,
    required this.listeningSubtitle,
    required this.progress,
    required this.showProgress,
    required this.hasActiveAudio,
  });

  final String readingSubtitle;
  final String listeningSubtitle;
  final double? progress;
  final bool showProgress;
  final bool hasActiveAudio;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final cardTokens = theme.componentTokens.homeDashboardCard;
    final Color foreground = cardTokens.foregroundColor;
    final double radius = tokens.resolveRadius(family: TilawaRadiusFamily.hero);

    return HomeDashboardCard(
      surface: TilawaCardSurface.raised,
      padding: EdgeInsets.zero,
      borderRadius: radius,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: AlignmentDirectional.topStart,
            end: AlignmentDirectional.bottomEnd,
            colors: [cardTokens.gradientStart, cardTokens.gradientEnd],
          ),
          borderRadius: BorderRadius.circular(radius),
        ),
        child: Padding(
          padding: EdgeInsets.all(tokens.spaceMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: tokens.spaceSmall,
            children: [
              Text(
                context.l10n.homeQuickQuran,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: foreground.withValues(alpha: 0.62),
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                ),
              ),
              Row(
                spacing: tokens.spaceSmall,
                children: [
                  Expanded(
                    child: _QuranResumeActionTile(
                      icon: Icons.menu_book_rounded,
                      title: context.l10n.continueReading,
                      subtitle: readingSubtitle,
                      foreground: foreground,
                      progress: showProgress ? progress : null,
                      onTap: () => const QuranLastReadRoute().push(context),
                    ),
                  ),
                  Expanded(
                    child: _QuranResumeActionTile(
                      icon: Icons.graphic_eq_rounded,
                      title: context.l10n.continueListening,
                      subtitle: listeningSubtitle,
                      foreground: foreground,
                      onTap: hasActiveAudio
                          ? () => QuranPlayerPresentationEntry.openExpanded(
                              presentation:
                                  getIt<PlayerPresentationController>(),
                              hasActiveAudio: hasActiveAudio,
                            )
                          : null,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuranResumeActionTile extends StatelessWidget {
  const _QuranResumeActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.foreground,
    this.progress,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color foreground;
  final double? progress;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final bool enabled = onTap != null;
    final Color effectiveForeground = foreground.withValues(
      alpha: enabled ? 1 : 0.48,
    );
    final double radius = tokens.resolveRadius(family: TilawaRadiusFamily.card);

    return Semantics(
      button: true,
      enabled: enabled,
      label: title,
      value: subtitle,
      child: Material(
        color: foreground.withValues(alpha: enabled ? 0.12 : 0.06),
        borderRadius: BorderRadius.circular(radius),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(radius),
          splashColor: foreground.withValues(alpha: 0.10),
          highlightColor: foreground.withValues(alpha: 0.06),
          child: Padding(
            padding: EdgeInsets.all(tokens.spaceSmall),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: tokens.spaceExtraSmall,
              children: [
                Row(
                  spacing: tokens.spaceSmall,
                  children: [
                    Icon(
                      icon,
                      color: effectiveForeground,
                      size: tokens.iconSizeSmall,
                    ),
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: effectiveForeground,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: effectiveForeground.withValues(alpha: 0.82),
                    height: 1.2,
                  ),
                ),
                if (progress != null)
                  _ProgressBar(
                    progress: progress!,
                    foreground: effectiveForeground,
                    label: context.l10n.homeQuranResumeProgress(
                      (progress! * 100).round(),
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

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({
    required this.progress,
    required this.foreground,
    required this.label,
  });

  final double progress;
  final Color foreground;
  final String label;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).tokens;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: tokens.spaceExtraSmall,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(tokens.radiusSmall),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: foreground.withValues(alpha: 0.20),
            valueColor: AlwaysStoppedAnimation<Color>(foreground),
            minHeight: 4,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: foreground.withValues(alpha: 0.78),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
