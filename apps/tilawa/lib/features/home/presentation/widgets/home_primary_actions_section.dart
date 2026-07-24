import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tilawa/core/di/injection.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/features/athkar/domain/athkar_context_recommendation.dart';
import 'package:tilawa/features/athkar/presentation/athkar_category_presentation.dart';
import 'package:tilawa/features/home/domain/constants/quran_mushaf_constants.dart';
import 'package:tilawa/features/home/domain/entities/home_dashboard.dart';
import 'package:tilawa/features/home/presentation/bloc/home_dashboard_bloc.dart';
import 'package:tilawa/features/home/presentation/bloc/home_dashboard_state.dart';
import 'package:tilawa/features/home/presentation/cubit/home_athkar_compact_cubit.dart';
import 'package:tilawa/features/home/presentation/cubit/home_athkar_compact_state.dart';
import 'package:tilawa/features/home/presentation/cubit/home_quran_resume_cubit.dart';
import 'package:tilawa/features/home/presentation/cubit/home_quran_resume_state.dart';
import 'package:tilawa/features/home/presentation/home_athkar_context.dart';
import 'package:tilawa/features/home/presentation/home_athkar_context_copy.dart';
import 'package:tilawa/features/home/presentation/widgets/home_feature_pastel.dart';
import 'package:tilawa/features/home/presentation/widgets/home_primary_action_tile.dart';
import 'package:tilawa/router/app_router_config.dart';
import 'package:tilawa_core/constants/analytics_constants.dart';
import 'package:tilawa_core/services/analytics_service.dart';
import 'package:tilawa_core/utils/surah_names.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

/// Two primary daily-action tiles under the Sliver Prayer Hero.
///
/// No visible section title — tiles self-label. Mushaf shows resume when
/// available; Athkar is destination-first (category + window icon) with a
/// quiet library secondary pinned to the card bottom.
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
          spacing: tokens.spaceLarge,
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
    final Color wash = HomeFeaturePastel.ceremonialWash(
      accent: accent,
      colorScheme: Theme.of(context).colorScheme,
    );

    if (cubit == null) {
      return HomePrimaryActionTile(
        accent: accent,
        surfaceColor: wash,
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
          surfaceColor: wash,
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

class _AthkarPrimaryTile extends StatefulWidget {
  const _AthkarPrimaryTile({
    required this.accent,
    required this.iconSize,
  });

  final Color accent;
  final double iconSize;

  @override
  State<_AthkarPrimaryTile> createState() => _AthkarPrimaryTileState();
}

class _AthkarPrimaryTileState extends State<_AthkarPrimaryTile> {
  String? _loggedImpressionKey;

  @override
  Widget build(BuildContext context) {
    final HomeAthkarCompactCubit? cubit = _maybeAthkarCubit(context);
    final HomeDashboard? dashboard = _dashboardOrNull(context);

    if (cubit == null) {
      return HomePrimaryActionTile(
        accent: widget.accent,
        icon: Icon(
          Icons.brightness_5_outlined,
          size: widget.iconSize,
          color: widget.accent,
        ),
        label: context.l10n.homeQuickAthkar,
        secondaryLabel: context.l10n.homeAthkarAll,
        onSecondaryTap: () => _openLibrary(context),
        onTap: () => _openLibrary(context),
      );
    }

    return BlocBuilder<HomeAthkarCompactCubit, HomeAthkarCompactState>(
      bloc: cubit,
      buildWhen: (previous, current) =>
          previous.status != current.status || previous.rows != current.rows,
      builder: (context, state) {
        final AthkarContextRecommendation recommendation =
            resolveHomeAthkarRecommendation(
              athkarState: state,
              now: DateTime.now(),
              dashboard: dashboard,
            );
        _logImpressionOnce(recommendation, dashboard != null);

        final HomeAthkarRowState? row = state.rowForCategoryId(
          recommendation.categoryId,
        );
        final copy = homeAthkarContextCopy(
          l10n: context.l10n,
          recommendation: recommendation,
          row: row,
          context: context,
        );
        final Color wash = athkarCategorySurfaceWash(
          accent: widget.accent,
          colorScheme: Theme.of(context).colorScheme,
          tintAlpha: athkarCategorySurfaceTintAlpha(
            row?.category.icon ?? _iconKeyForWindow(recommendation.window),
          ),
        );

        return HomePrimaryActionTile(
          accent: widget.accent,
          surfaceColor: wash,
          icon: Icon(
            homeAthkarContextIcon(recommendation),
            size: widget.iconSize,
            color: widget.accent,
          ),
          label: copy.title,
          subtitle: copy.subtitle,
          secondaryLabel: context.l10n.homeAthkarAll,
          onSecondaryTap: () => _openLibrary(
            context,
            recommendation: recommendation,
            hasPrayerBounds: dashboard?.prayerBoundaries != null,
          ),
          onTap: () => _openPrimary(
            context,
            recommendation: recommendation,
            row: row,
            hasPrayerBounds: dashboard?.prayerBoundaries != null,
          ),
        );
      },
    );
  }

  void _logImpressionOnce(
    AthkarContextRecommendation recommendation,
    bool hasPrayerBounds,
  ) {
    final String key =
        '${recommendation.window.name}|${recommendation.intent.name}|'
        '${recommendation.categoryId}|$hasPrayerBounds';
    if (_loggedImpressionKey == key) {
      return;
    }
    _loggedImpressionKey = key;
    final AnalyticsService? analytics = _analyticsOrNull;
    if (analytics == null) {
      return;
    }
    unawaited(
      analytics.logEvent(
        AnalyticsEvents.athkarContextImpression,
        parameters: _contextParams(
          recommendation: recommendation,
          hasPrayerBounds: hasPrayerBounds,
        ),
      ),
    );
  }

  void _openPrimary(
    BuildContext context, {
    required AthkarContextRecommendation recommendation,
    required HomeAthkarRowState? row,
    required bool hasPrayerBounds,
  }) {
    final AnalyticsService? analytics = _analyticsOrNull;
    if (analytics != null) {
      unawaited(
        analytics.logEvent(
          AnalyticsEvents.athkarContextPrimaryTap,
          parameters: _contextParams(
            recommendation: recommendation,
            hasPrayerBounds: hasPrayerBounds,
            source: 'home_primary',
          ),
        ),
      );
    }

    if (recommendation.opensLibrary || row == null) {
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

  void _openLibrary(
    BuildContext context, {
    AthkarContextRecommendation? recommendation,
    bool hasPrayerBounds = false,
  }) {
    final AnalyticsService? analytics = _analyticsOrNull;
    if (analytics != null && recommendation != null) {
      unawaited(
        analytics.logEvent(
          AnalyticsEvents.athkarContextLibraryTap,
          parameters: _contextParams(
            recommendation: recommendation,
            hasPrayerBounds: hasPrayerBounds,
            source: 'home_primary_library',
          ),
        ),
      );
    }
    unawaited(const AthkarCategoriesRoute().push<void>(context));
  }

  Map<String, Object> _contextParams({
    required AthkarContextRecommendation recommendation,
    required bool hasPrayerBounds,
    String? source,
  }) {
    return <String, Object>{
      AnalyticsParams.athkarWindow: recommendation.window.name,
      AnalyticsParams.athkarIntent: recommendation.intent.name,
      AnalyticsParams.hasPrayerBounds: hasPrayerBounds ? 1 : 0,
      if (recommendation.categoryId != null)
        AnalyticsParams.categoryId: recommendation.categoryId!,
      AnalyticsParams.source: ?source,
    };
  }

  AnalyticsService? get _analyticsOrNull {
    if (!getIt.isRegistered<AnalyticsService>()) {
      return null;
    }
    return getIt<AnalyticsService>();
  }

  HomeDashboard? _dashboardOrNull(BuildContext context) {
    try {
      final HomeDashboardState state = context.watch<HomeDashboardBloc>().state;
      if (state is HomeDashboardLoaded) {
        return state.dashboard;
      }
    } on ProviderNotFoundException {
      return null;
    }
    return null;
  }

  HomeAthkarCompactCubit? _maybeAthkarCubit(BuildContext context) {
    try {
      return context.read<HomeAthkarCompactCubit>();
    } on ProviderNotFoundException {
      return null;
    }
  }

  String _iconKeyForWindow(AthkarContextWindow window) {
    return switch (window) {
      AthkarContextWindow.morning => 'wb_sunny_rounded',
      AthkarContextWindow.evening => 'nights_stay_rounded',
      AthkarContextWindow.sleep => 'bedtime_rounded',
      AthkarContextWindow.neutral => 'wb_sunny_rounded',
    };
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
