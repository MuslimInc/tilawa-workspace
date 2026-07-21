import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/features/athkar/presentation/athkar_category_presentation.dart';
import 'package:tilawa/features/home/domain/constants/quran_mushaf_constants.dart';
import 'package:tilawa/features/home/presentation/cubit/home_athkar_compact_cubit.dart';
import 'package:tilawa/features/home/presentation/cubit/home_athkar_compact_state.dart';
import 'package:tilawa/features/home/presentation/cubit/home_quran_resume_cubit.dart';
import 'package:tilawa/features/home/presentation/cubit/home_quran_resume_state.dart';
import 'package:tilawa/features/home/presentation/widgets/home_feature_pastel.dart';
import 'package:tilawa/features/home/presentation/widgets/home_primary_action_tile.dart';
import 'package:tilawa/router/app_router_config.dart';
import 'package:tilawa_core/utils/surah_names.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

/// Two primary daily-action tiles under the Sliver Prayer Hero.
///
/// No visible section title — tiles self-label. Subtitles show resume /
/// athkar progress when available (goal-gradient cue; never a cold blank
/// when the user already has a position).
class HomePrimaryActionsSection extends StatelessWidget {
  const HomePrimaryActionsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final product = Theme.of(context).productColors;
    final Color quranAccent = HomeFeaturePastel.accentFor(
      HomeExploreFeature.quran,
      product,
    );
    final Color athkarAccent = HomeFeaturePastel.accentFor(
      HomeExploreFeature.athkar,
      product,
    );
    final double iconSize = tokens.iconSizeLarge;

    return Semantics(
      header: true,
      label: context.l10n.homeMainActionsTitle,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: tokens.spaceMedium,
          children: [
            Expanded(
              child: _QuranPrimaryTile(
                accent: quranAccent,
                iconSize: iconSize,
              ),
            ),
            Expanded(
              child: _AthkarPrimaryTile(
                accent: athkarAccent,
                iconSize: iconSize,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuranPrimaryTile extends StatelessWidget {
  const _QuranPrimaryTile({
    required this.accent,
    required this.iconSize,
  });

  final Color accent;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final HomeQuranResumeCubit? cubit = _maybeCubit(context);
    final Widget icon = TilawaIcons.quran.svg(
      size: iconSize,
      color: accent,
    );
    final String label = context.l10n.homeQuickQuranReader;

    if (cubit == null) {
      return HomePrimaryActionTile(
        accent: accent,
        icon: icon,
        label: label,
        onTap: () => const QuranLastReadRoute().push<void>(context),
      );
    }

    return BlocBuilder<HomeQuranResumeCubit, HomeQuranResumeState>(
      bloc: cubit,
      buildWhen: (previous, current) =>
          previous.surahNumber != current.surahNumber ||
          previous.page != current.page ||
          previous.status != current.status,
      builder: (context, state) {
        return HomePrimaryActionTile(
          accent: accent,
          icon: icon,
          label: label,
          subtitle: _quranResumeSubtitle(context, state),
          progress: state.progressFraction(QuranMushafConstants.pageCount),
          onTap: () => const QuranLastReadRoute().push<void>(context),
        );
      },
    );
  }

  HomeQuranResumeCubit? _maybeCubit(BuildContext context) {
    try {
      return context.read<HomeQuranResumeCubit>();
    } on ProviderNotFoundException {
      return null;
    }
  }
}

class _AthkarPrimaryTile extends StatelessWidget {
  const _AthkarPrimaryTile({
    required this.accent,
    required this.iconSize,
  });

  final Color accent;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final HomeAthkarCompactCubit? cubit = _maybeCubit(context);
    final Widget icon = Icon(
      Icons.brightness_5_outlined,
      size: iconSize,
      color: accent,
    );
    final String label = context.l10n.homeQuickAthkar;

    if (cubit == null) {
      return HomePrimaryActionTile(
        accent: accent,
        icon: icon,
        label: label,
        onTap: () => const AthkarCategoriesRoute().push<void>(context),
      );
    }

    return BlocBuilder<HomeAthkarCompactCubit, HomeAthkarCompactState>(
      bloc: cubit,
      buildWhen: (previous, current) =>
          previous.status != current.status || previous.rows != current.rows,
      builder: (context, state) {
        final HomeAthkarRowState? row = urgentHomeAthkarRow(state);
        return HomePrimaryActionTile(
          accent: accent,
          icon: icon,
          label: label,
          subtitle: _athkarSubtitle(context, row),
          onTap: () => _openAthkar(context, row),
        );
      },
    );
  }

  void _openAthkar(BuildContext context, HomeAthkarRowState? row) {
    if (row == null) {
      unawaited(const AthkarCategoriesRoute().push<void>(context));
      return;
    }
    final String title = localizedAthkarCategoryTitle(context, row.category);
    unawaited(
      AthkarDetailsRoute(
        categoryId: row.category.id,
        categoryName: title,
        source: 'home_primary',
      ).push<void>(context),
    );
  }

  HomeAthkarCompactCubit? _maybeCubit(BuildContext context) {
    try {
      return context.read<HomeAthkarCompactCubit>();
    } on ProviderNotFoundException {
      return null;
    }
  }
}

/// Factual last-read line; null when there is nothing useful to show.
///
/// Page 1 still counts as underway progress (goal gradient) when a resume
/// position exists — never blank the tile for a cold “start at zero” feel.
String? _quranResumeSubtitle(BuildContext context, HomeQuranResumeState state) {
  if (!state.hasResumePosition) {
    return null;
  }

  final l10n = context.l10n;
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

String? _athkarSubtitle(BuildContext context, HomeAthkarRowState? row) {
  if (row == null) {
    return null;
  }
  final String title = localizedAthkarCategoryTitle(context, row.category);
  final l10n = context.l10n;
  return switch (row.completion) {
    HomeAthkarCompletionState.done => '$title · ${l10n.homeAthkarDone}',
    HomeAthkarCompletionState.inProgress =>
      '$title · ${l10n.homeAthkarRemaining(row.remainingCount)}',
    HomeAthkarCompletionState.notStarted => title,
  };
}
