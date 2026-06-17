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
    return context.l10n.homeContinueQuranTitle;
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
    final colorScheme = theme.colorScheme;

    return Semantics(
      button: true,
      label: title,
      value: subtitle,
      child: HomeDashboardCard(
        surface: TilawaCardSurface.raised,
        onTap: () => const QuranLastReadRoute().push(context),
        child: Row(
          spacing: tokens.spaceMedium,
          children: [
            _HomeQuranLeadingIcon(progress: showProgress ? progress : null),
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
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (showProgress && progress != null)
                    Text(
                      context.l10n.homeQuranResumeProgress(
                        (progress! * 100).round(),
                      ),
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: colorScheme.primary,
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
              color: colorScheme.onSurfaceVariant,
              size: tokens.iconSizeSmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeQuranLeadingIcon extends StatelessWidget {
  const _HomeQuranLeadingIcon({required this.progress});

  final double? progress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final colorScheme = theme.colorScheme;
    final double ringSize = tokens.spaceExtraLarge + tokens.spaceMedium;

    if (progress == null) {
      return TilawaIconBox(
        icon: Icons.menu_book_rounded,
        variant: TilawaIconBoxVariant.tinted,
        semanticTint: TilawaSemanticTint.ink,
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
            backgroundColor: colorScheme.surfaceContainerHighest,
            color: colorScheme.primary,
          ),
          TilawaIconBox(
            icon: Icons.menu_book_rounded,
            size: tokens.iconSizeSmall,
            padding: tokens.spaceExtraSmall,
            variant: TilawaIconBoxVariant.tinted,
            semanticTint: TilawaSemanticTint.ink,
          ),
        ],
      ),
    );
  }
}
