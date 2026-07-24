import 'package:flutter/material.dart';
import 'package:tilawa/features/athkar/domain/athkar_context_recommendation.dart';
import 'package:tilawa/features/athkar/presentation/athkar_category_presentation.dart';
import 'package:tilawa/features/home/presentation/cubit/home_athkar_compact_state.dart';
import 'package:tilawa/l10n/generated/app_localizations.dart';

/// Localized title + subtitle for the Home Athkar contextual tile.
///
/// Destination-first: category name is the title when known. Soft invites and
/// progress counts stay off the primary line so the tile matches Mushaf weight.
({String title, String? subtitle}) homeAthkarContextCopy({
  required AppLocalizations l10n,
  required AthkarContextRecommendation recommendation,
  required HomeAthkarRowState? row,
  required BuildContext context,
}) {
  if (recommendation.intent == AthkarContextIntent.explore &&
      recommendation.categoryId == null) {
    if (recommendation.confidence == AthkarContextConfidence.soft &&
        recommendation.window != AthkarContextWindow.neutral) {
      return (
        title: l10n.homeAthkarAllDoneTitle,
        subtitle: l10n.homeAthkarAllDoneSubtitle,
      );
    }
    return (
      title: l10n.homeAthkarExploreTitle,
      subtitle: l10n.homeAthkarExploreSubtitle,
    );
  }

  if (recommendation.intent == AthkarContextIntent.completedWindow) {
    return (
      title: _windowDoneTitle(l10n, recommendation.window),
      subtitle: l10n.homeAthkarBrowseRestSubtitle,
    );
  }

  final String? categoryTitle = row == null
      ? null
      : localizedAthkarCategoryTitle(context, row.category);
  if (categoryTitle != null) {
    return (title: categoryTitle, subtitle: null);
  }

  return (
    title: _startTitleForTarget(
      l10n: l10n,
      categoryId: recommendation.categoryId,
      window: recommendation.window,
    ),
    subtitle: null,
  );
}

String _startTitleForTarget({
  required AppLocalizations l10n,
  required int? categoryId,
  required AthkarContextWindow window,
}) {
  final int? id = categoryId ?? _preferredIdForWindow(window);

  return switch (id) {
    AthkarContextCategoryIds.morning => l10n.homeAthkarMorningStart,
    AthkarContextCategoryIds.evening => l10n.homeAthkarEveningStart,
    AthkarContextCategoryIds.sleep => l10n.homeAthkarSleepStart,
    _ => l10n.homeAthkarExploreTitle,
  };
}

int? _preferredIdForWindow(AthkarContextWindow window) {
  return switch (window) {
    AthkarContextWindow.morning => AthkarContextCategoryIds.morning,
    AthkarContextWindow.evening => AthkarContextCategoryIds.evening,
    AthkarContextWindow.sleep => AthkarContextCategoryIds.sleep,
    AthkarContextWindow.neutral => null,
  };
}

String _windowDoneTitle(AppLocalizations l10n, AthkarContextWindow window) {
  return switch (window) {
    AthkarContextWindow.morning => l10n.homeAthkarMorningDone,
    AthkarContextWindow.evening => l10n.homeAthkarEveningDone,
    AthkarContextWindow.sleep => l10n.homeAthkarSleepDone,
    AthkarContextWindow.neutral => l10n.homeAthkarExploreTitle,
  };
}

IconData homeAthkarContextIcon(AthkarContextRecommendation recommendation) {
  final int? id = recommendation.categoryId;
  if (id == AthkarContextCategoryIds.morning) {
    return Icons.wb_sunny_rounded;
  }
  if (id == AthkarContextCategoryIds.evening) {
    return Icons.nights_stay_rounded;
  }
  if (id == AthkarContextCategoryIds.sleep) {
    return Icons.bedtime_rounded;
  }
  return switch (recommendation.window) {
    AthkarContextWindow.morning => Icons.wb_sunny_rounded,
    AthkarContextWindow.evening => Icons.nights_stay_rounded,
    AthkarContextWindow.sleep => Icons.bedtime_rounded,
    AthkarContextWindow.neutral => Icons.brightness_5_outlined,
  };
}
