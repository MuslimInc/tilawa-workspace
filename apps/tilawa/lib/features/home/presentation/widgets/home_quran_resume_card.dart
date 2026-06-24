import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/features/home/domain/constants/quran_mushaf_constants.dart';
import 'package:tilawa/features/home/presentation/cubit/home_quran_resume_cubit.dart';
import 'package:tilawa/features/home/presentation/cubit/home_quran_resume_state.dart';
import 'package:tilawa/l10n/generated/app_localizations.dart';
import 'package:tilawa/router/app_router_config.dart';
import 'package:tilawa_core/utils/surah_names.dart';
import 'package:tilawa/features/home/presentation/widgets/home_dashboard_card.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

/// Featured Mushaf resume card with streak and goal context.
class HomeQuranResumeCard extends StatelessWidget {
  const HomeQuranResumeCard({super.key, this.featured = false});

  final bool featured;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeQuranResumeCubit, HomeQuranResumeState>(
      builder: (context, state) {
        return switch (state.status) {
          HomeQuranResumeStatus.loading ||
          HomeQuranResumeStatus.initial => _HomeQuranResumeLoadingCard(
            featured: featured,
          ),
          HomeQuranResumeStatus.failure ||
          HomeQuranResumeStatus.ready => _HomeQuranResumeReadyCard(
            state: state,
            featured: featured,
          ),
        };
      },
    );
  }
}

class _HomeQuranResumeLoadingCard extends StatelessWidget {
  const _HomeQuranResumeLoadingCard({required this.featured});

  final bool featured;

  @override
  Widget build(BuildContext context) {
    return HomeDashboardCard(
      surface: TilawaCardSurface.raised,
      useFeaturedGradient: featured,
      child: const TilawaLoadingIndicator(centered: false),
    );
  }
}

class _HomeQuranResumeReadyCard extends StatelessWidget {
  const _HomeQuranResumeReadyCard({
    required this.state,
    required this.featured,
  });

  final HomeQuranResumeState state;
  final bool featured;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final cardTokens = theme.componentTokens.homeDashboardCard;
    final Color foreground = cardTokens.foregroundColor;
    final double radius = tokens.resolveRadius(family: TilawaRadiusFamily.hero);
    final bool freshStart = _isFreshStart(state);
    final String title = freshStart
        ? context.l10n.homeStartQuranTitle
        : context.l10n.homeContinueQuranTitle;
    final String subtitle = _resumeSubtitle(context, state);
    final double? progress = _shouldShowProgress(state)
        ? state.progressFraction(QuranMushafConstants.pageCount)
        : null;

    return HomeDashboardCard(
      surface: TilawaCardSurface.raised,
      useFeaturedGradient: featured,
      padding: EdgeInsets.zero,
      borderRadius: radius,
      onTap: () => const QuranLastReadRoute().push(context),
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
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (progress != null)
                _ProgressRing(progress: progress, foreground: foreground)
              else
                TilawaIcons.quran.svg(
                  color: foreground,
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
                        color: foreground,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: tokens.spaceExtraSmall),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: foreground.withValues(alpha: 0.82),
                      ),
                    ),
                    if (state.streakDays != null) ...[
                      SizedBox(height: tokens.spaceSmall),
                      Text(
                        context.l10n.homeQuranStreakDays(state.streakDays!),
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: foreground.withValues(alpha: 0.9),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                    if (state.goalProgress != null) ...[
                      SizedBox(height: tokens.spaceSmall),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(tokens.radiusSmall),
                        child: LinearProgressIndicator(
                          value: state.goalProgress,
                          backgroundColor: foreground.withValues(alpha: 0.20),
                          valueColor: AlwaysStoppedAnimation<Color>(foreground),
                          minHeight: 4,
                        ),
                      ),
                      SizedBox(height: tokens.spaceExtraSmall),
                      Text(
                        context.l10n.homeQuranGoalProgress(
                          (state.goalProgress! * 100).round(),
                        ),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: foreground.withValues(alpha: 0.78),
                        ),
                      ),
                    ],
                    if (state.hasActiveKhatmaPlan) ...[
                      SizedBox(height: tokens.spaceExtraSmall),
                      Text(
                        context.l10n.khatmaProgressTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: foreground.withValues(alpha: 0.72),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: foreground.withValues(alpha: 0.82),
              ),
            ],
          ),
        ),
      ),
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

class _ProgressRing extends StatelessWidget {
  const _ProgressRing({required this.progress, required this.foreground});

  final double progress;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return SizedBox(
      width: tokens.iconSizeLarge + tokens.spaceSmall,
      height: tokens.iconSizeLarge + tokens.spaceSmall,
      child: CircularProgressIndicator(
        value: progress,
        strokeWidth: 3,
        backgroundColor: foreground.withValues(alpha: 0.20),
        valueColor: AlwaysStoppedAnimation<Color>(foreground),
      ),
    );
  }
}
