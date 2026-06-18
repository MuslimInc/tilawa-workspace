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
    final Color mutedForeground = foreground.withValues(alpha: 0.72);

    return Semantics(
      button: true,
      label: title,
      value: subtitle,
      child: HomeDashboardCard(
        useFeaturedGradient: true,
        surface: TilawaCardSurface.raised,
        onTap: () => const QuranLastReadRoute().push(context),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
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
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: foreground,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: mutedForeground,
                        ),
                      ),
                      if (showProgress && progress != null)
                        Text(
                          context.l10n.homeQuranResumeProgress(
                            (progress! * 100).round(),
                          ),
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: foreground,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                ),
                Icon(
                  Directionality.of(context) == TextDirection.rtl
                      ? Icons.chevron_left_rounded
                      : Icons.chevron_right_rounded,
                  color: mutedForeground,
                  size: tokens.iconSizeSmall,
                ),
              ],
            ),
            PositionedDirectional(
              end: -tokens.spaceSmall,
              top: -tokens.spaceSmall,
              bottom: -tokens.spaceSmall,
              child: IgnorePointer(
                child: Opacity(
                  opacity: 0.22,
                  child: Icon(
                    Icons.mosque_rounded,
                    size: tokens.spaceExtraLarge * 2,
                    color: foreground,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
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
    final double ringSize = tokens.spaceExtraLarge + tokens.spaceMedium;

    if (progress == null) {
      return TilawaIconBox(
        icon: Icons.menu_book_rounded,
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
            backgroundColor: foreground.withValues(alpha: 0.16),
            color: foreground,
          ),
          TilawaIconBox(
            icon: Icons.menu_book_rounded,
            size: tokens.iconSizeSmall,
            padding: tokens.spaceExtraSmall,
            variant: TilawaIconBoxVariant.tinted,
            semanticTint: TilawaSemanticTint.ink,
            iconColor: foreground,
          ),
        ],
      ),
    );
  }
}
