import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/features/home/presentation/cubit/home_quran_resume_cubit.dart';
import 'package:tilawa/features/home/presentation/cubit/home_quran_resume_state.dart';
import 'package:tilawa/features/home/presentation/widgets/home_feature_pastel.dart';
import 'package:tilawa/features/home/presentation/widgets/home_primary_action_tile.dart';
import 'package:tilawa/router/app_router_config.dart';
import 'package:tilawa_core/utils/surah_names.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

/// Two primary daily-action tiles under the Sliver Prayer Hero.
///
/// No visible section title — tiles self-label. Quran subtitle shows last-read
/// position when available.
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
              child: HomePrimaryActionTile(
                accent: athkarAccent,
                icon: Icon(
                  Icons.brightness_5_outlined,
                  size: iconSize,
                  color: athkarAccent,
                ),
                label: context.l10n.homeQuickAthkar,
                onTap: () => const AthkarCategoriesRoute().push<void>(context),
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
    final HomeQuranResumeCubit? cubit = _maybeResumeCubit(context);
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
          onTap: () => const QuranLastReadRoute().push<void>(context),
        );
      },
    );
  }

  HomeQuranResumeCubit? _maybeResumeCubit(BuildContext context) {
    try {
      return context.read<HomeQuranResumeCubit>();
    } on ProviderNotFoundException {
      return null;
    }
  }
}

/// Factual last-read line; null when there is nothing useful to show.
String? _quranResumeSubtitle(BuildContext context, HomeQuranResumeState state) {
  if (!state.hasResumePosition) {
    return null;
  }
  final int? page = state.page;
  if (page == null || page <= 1) {
    return null;
  }

  final l10n = context.l10n;
  final int? surahNumber = state.surahNumber;
  if (surahNumber != null) {
    final String surahName = context.isArabic
        ? SurahNames.getArabicSurahName(surahNumber)
        : SurahNames.getEnglishSurahName(surahNumber);
    return l10n.homeQuranResumeSurahPage(surahName, page);
  }
  return l10n.homeQuranResumePage(page);
}
