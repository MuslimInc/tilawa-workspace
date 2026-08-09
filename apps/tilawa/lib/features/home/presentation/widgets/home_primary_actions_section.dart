import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tilawa/core/di/injection.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/features/athkar/domain/athkar_context_recommendation.dart';
import 'package:tilawa/features/athkar/presentation/athkar_category_presentation.dart';
import 'package:tilawa/features/home/domain/constants/quran_mushaf_constants.dart';
import 'package:tilawa/features/home/domain/entities/home_prayer_day_boundaries.dart';
import 'package:tilawa/features/home/domain/entities/home_prayer_slot.dart';
import 'package:tilawa/features/home/presentation/bloc/home_dashboard_bloc.dart';
import 'package:tilawa/features/home/presentation/bloc/home_dashboard_state.dart';
import 'package:tilawa/features/home/presentation/cubit/home_athkar_compact_cubit.dart';
import 'package:tilawa/features/home/presentation/cubit/home_athkar_compact_state.dart';
import 'package:tilawa/features/home/presentation/cubit/home_quran_resume_cubit.dart';
import 'package:tilawa/features/home/presentation/cubit/home_quran_resume_state.dart';
import 'package:tilawa/features/home/presentation/home_athkar_context_copy.dart';
import 'package:tilawa/features/home/presentation/widgets/home_feature_pastel.dart';
import 'package:tilawa/features/home/presentation/widgets/home_primary_action_tile.dart';
import 'package:tilawa/features/prayer_times/domain/entities/prayer_time_entity.dart';
import 'package:tilawa/router/app_router_config.dart';
import 'package:tilawa_core/constants/analytics_constants.dart';
import 'package:tilawa_core/services/analytics_service.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

/// Two primary daily-action tiles under the Sliver Prayer Hero.
///
/// No visible section title — tiles self-label. Mushaf shows a quiet Surah
/// Index secondary; Athkar is destination-first (category + window icon) with
/// a quiet library secondary pinned to the card bottom. Khatma lives in its
/// own featured Home section — do not duplicate it on the Mushaf tile.
class HomePrimaryActionsSection extends StatelessWidget {
  const HomePrimaryActionsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    // Ngajii ladder: white card bodies; solid primary wells + onPrimary glyphs.
    final Color surface = HomeFeaturePastel.cardSurface(colorScheme);
    final Color chrome = colorScheme.onPrimary;
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
                accent: colorScheme.primary,
                iconSize: iconSize,
                surface: surface,
                chrome: chrome,
              ),
            ),
            Expanded(
              child: _AthkarPrimaryTile(
                accent: colorScheme.primary,
                iconSize: iconSize,
                surface: surface,
                chrome: chrome,
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
    required this.surface,
    required this.chrome,
  });

  final Color accent;
  final double iconSize;
  final Color surface;
  final Color chrome;

  @override
  Widget build(BuildContext context) {
    final HomeQuranResumeCubit? cubit = _maybeCubit(context);
    final Widget icon = TilawaIcons.quran.svg(
      size: iconSize,
      color: chrome,
    );
    final String label = context.l10n.homeQuickQuranReader;
    final String indexSecondaryLabel = context.l10n.surahIndex;
    void openIndex() => const QuranIndexRoute().push<void>(context);
    void openResume() => const QuranLastReadRoute().push<void>(context);

    if (cubit == null) {
      return HomePrimaryActionTile(
        accent: accent,
        surfaceColor: surface,
        icon: icon,
        label: label,
        secondaryLabel: indexSecondaryLabel,
        onSecondaryTap: openIndex,
        onTap: openResume,
        semanticsIdentifier: 'home_last_read',
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
          surfaceColor: surface,
          icon: icon,
          label: label,
          progress: _quranTileProgress(state),
          secondaryLabel: indexSecondaryLabel,
          onSecondaryTap: openIndex,
          onTap: openResume,
          semanticsIdentifier: 'home_last_read',
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
    required this.surface,
    required this.chrome,
  });

  final Color accent;
  final double iconSize;
  final Color surface;
  final Color chrome;

  @override
  State<_AthkarPrimaryTile> createState() => _AthkarPrimaryTileState();
}

class _AthkarPrimaryTileState extends State<_AthkarPrimaryTile> {
  String? _loggedImpressionKey;

  @override
  Widget build(BuildContext context) {
    final HomeAthkarCompactCubit? cubit = _maybeAthkarCubit(context);
    final AthkarPrayerAnchors? prayerAnchors = _athkarPrayerAnchorsOrNull(
      context,
    );
    final bool hasPrayerBounds = prayerAnchors != null;

    if (cubit == null) {
      return HomePrimaryActionTile(
        accent: widget.accent,
        surfaceColor: widget.surface,
        icon: Icon(
          Icons.brightness_5_outlined,
          size: widget.iconSize,
          color: widget.chrome,
        ),
        label: context.l10n.homeQuickAthkar,
        secondaryLabel: context.l10n.homeAthkarAll,
        onSecondaryTap: () => _openLibrary(context),
        onTap: () => _openLibrary(context),
        semanticsIdentifier: 'home_athkar',
      );
    }

    return BlocBuilder<HomeAthkarCompactCubit, HomeAthkarCompactState>(
      bloc: cubit,
      buildWhen: (previous, current) =>
          previous.status != current.status || previous.rows != current.rows,
      builder: (context, state) {
        final AthkarContextRecommendation recommendation =
            resolveAthkarContextRecommendation(
              now: DateTime.now(),
              prayerAnchors: prayerAnchors,
              completions: homeAthkarCompletions(state),
            );
        _logImpressionOnce(recommendation, hasPrayerBounds);

        final HomeAthkarRowState? row = state.rowForCategoryId(
          recommendation.categoryId,
        );
        final copy = homeAthkarContextCopy(
          l10n: context.l10n,
          recommendation: recommendation,
          row: row,
          context: context,
        );

        return HomePrimaryActionTile(
          accent: widget.accent,
          surfaceColor: widget.surface,
          icon: Icon(
            homeAthkarContextIcon(recommendation),
            size: widget.iconSize,
            color: widget.chrome,
          ),
          label: copy.title,
          subtitle: copy.subtitle,
          secondaryLabel: context.l10n.homeAthkarAll,
          onSecondaryTap: () => _openLibrary(
            context,
            recommendation: recommendation,
            hasPrayerBounds: hasPrayerBounds,
          ),
          onTap: () => _openPrimary(
            context,
            recommendation: recommendation,
            row: row,
            hasPrayerBounds: hasPrayerBounds,
          ),
          semanticsIdentifier: 'home_athkar',
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
        restoreProgress:
            recommendation.intent == AthkarContextIntent.continueSession,
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

  /// Prayer anchors only — avoids rebuilding on countdown ticks in
  /// [HomeDashboard.nextPrayer.timeUntil].
  AthkarPrayerAnchors? _athkarPrayerAnchorsOrNull(BuildContext context) {
    try {
      final ({HomePrayerDayBoundaries? boundaries, DateTime? asr}) selected =
          context.select<
            HomeDashboardBloc,
            ({HomePrayerDayBoundaries? boundaries, DateTime? asr})
          >((HomeDashboardBloc bloc) {
            final HomeDashboardState state = bloc.state;
            if (state is! HomeDashboardLoaded) {
              return (boundaries: null, asr: null);
            }
            final List<HomePrayerSlot> todayPrayers =
                state.dashboard.todayPrayers;
            DateTime? asr;
            for (final HomePrayerSlot slot in todayPrayers) {
              if (slot.type == PrayerType.asr) {
                asr = slot.time;
                break;
              }
            }
            return (
              boundaries: state.dashboard.prayerBoundaries,
              asr: asr,
            );
          });
      final HomePrayerDayBoundaries? boundaries = selected.boundaries;
      if (boundaries == null) {
        return null;
      }
      return AthkarPrayerAnchors(
        fajr: boundaries.fajr,
        asr: selected.asr,
        maghrib: boundaries.maghrib,
        isha: boundaries.isha,
      );
    } on ProviderNotFoundException {
      return null;
    }
  }

  HomeAthkarCompactCubit? _maybeAthkarCubit(BuildContext context) {
    try {
      return context.read<HomeAthkarCompactCubit>();
    } on ProviderNotFoundException {
      return null;
    }
  }
}

/// Mushaf progress only when reading is underway past a cold start.
double? _quranTileProgress(HomeQuranResumeState state) {
  final int? page = state.page;
  if (page == null || page <= 1) {
    return null;
  }
  return state.progressFraction(QuranMushafConstants.pageCount);
}
