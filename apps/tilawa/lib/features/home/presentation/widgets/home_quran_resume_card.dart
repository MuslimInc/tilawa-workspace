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
          HomeQuranResumeStatus.failure => _HomeQuranResumeReadyCard(
            title: context.l10n.homeContinueQuranTitle,
            subtitle: context.l10n.homeContinueQuranSubtitle,
            progress: null,
            showProgress: false,
          ),
          HomeQuranResumeStatus.ready => _HomeQuranResumeReadyCard(
            title: _resumeTitle(context, state),
            subtitle: _resumeSubtitle(context, state),
            progress: state.progressFraction(QuranMushafConstants.pageCount),
            showProgress: _shouldShowProgress(state),
          ),
        };
      },
    );
  }

  String _resumeTitle(BuildContext context, HomeQuranResumeState state) {
    if (_isFreshStart(state)) {
      return context.l10n.homeStartQuranTitle;
    }
    return context.l10n.lastRead;
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
    required this.title,
    required this.subtitle,
    required this.progress,
    required this.showProgress,
  });

  final String title;
  final String subtitle;
  final double? progress;
  final bool showProgress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final cardTokens = theme.componentTokens.homeDashboardCard;
    final Color foreground = cardTokens.foregroundColor;
    final Color mutedForeground = foreground.withValues(alpha: 0.78);
    final Color dimForeground = foreground.withValues(alpha: 0.45);
    final double radius = tokens.resolveRadius(family: TilawaRadiusFamily.hero);

    return Semantics(
      button: true,
      label: title,
      value: subtitle,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(radius),
        child: InkWell(
          onTap: () => const QuranLastReadRoute().push(context),
          borderRadius: BorderRadius.circular(radius),
          splashColor: foreground.withValues(alpha: 0.10),
          highlightColor: foreground.withValues(alpha: 0.06),
          child: Ink(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: AlignmentDirectional.topStart,
                end: AlignmentDirectional.bottomEnd,
                colors: [cardTokens.gradientStart, cardTokens.gradientEnd],
              ),
              borderRadius: BorderRadius.circular(radius),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: tokens.spaceExtraLarge,
                vertical: tokens.spaceLarge,
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Decorative mosque silhouette — large, clipped by the card
                  PositionedDirectional(
                    end: -tokens.spaceExtraLarge * 0.5,
                    top: 0,
                    bottom: 0,
                    child: IgnorePointer(
                      child: Opacity(
                        opacity: 0.13,
                        child: Icon(
                          Icons.mosque_rounded,
                          size: tokens.spaceExtraLarge * 3,
                          color: foreground,
                        ),
                      ),
                    ),
                  ),
                  Row(
                    spacing: tokens.spaceMedium,
                    children: [
                      _HomeQuranLeadingIcon(
                        progress: showProgress ? progress : null,
                        foreground: foreground,
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          spacing: tokens.spaceExtraSmall,
                          children: [
                            Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: dimForeground,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                            Text(
                              subtitle,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: foreground,
                                fontWeight: FontWeight.w800,
                                height: 1.25,
                              ),
                            ),
                            if (showProgress && progress != null)
                              _ProgressBar(
                                progress: progress!,
                                foreground: foreground,
                                label: context.l10n.homeQuranResumeProgress(
                                  (progress! * 100).round(),
                                ),
                              ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: mutedForeground,
                        size: tokens.iconSizeMedium,
                      ),
                    ],
                  ),
                ],
              ),
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

class _HomeQuranLeadingIcon extends StatelessWidget {
  const _HomeQuranLeadingIcon({
    required this.progress,
    required this.foreground,
  });

  final double? progress;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final double ringSize = tokens.spaceExtraLarge + tokens.spaceLarge;

    if (progress == null) {
      return TilawaIconBox(
        icon: Icons.menu_book_rounded,
        size: tokens.iconSizeLarge,
        padding: tokens.spaceMedium,
        variant: TilawaIconBoxVariant.tinted,
        semanticTint: TilawaSemanticTint.ink,
        iconColor: foreground,
      );
    }

    return SizedBox(
      width: ringSize,
      height: ringSize,
      child: Stack(
        alignment: Alignment.center,
        children: [
          TilawaLoadingIndicator(
            centered: false,
            value: progress,
            backgroundColor: foreground.withValues(alpha: 0.20),
            color: foreground,
          ),
          TilawaIconBox(
            icon: Icons.menu_book_rounded,
            size: tokens.iconSizeMedium,
            padding: tokens.spaceSmall,
            variant: TilawaIconBoxVariant.tinted,
            semanticTint: TilawaSemanticTint.ink,
            iconColor: foreground,
          ),
        ],
      ),
    );
  }
}
