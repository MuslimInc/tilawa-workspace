import 'package:tilawa/features/smart_khatma/domain/entities/wird_progress_summary.dart';
import 'package:tilawa/l10n/generated/app_localizations.dart';

import '../../domain/entities/wird_progress_widget_payload.dart';

enum WirdWidgetNumeralSystem { latin, arabicIndic }

final class WirdProgressWidgetAdapter {
  WirdProgressWidgetAdapter({DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final DateTime Function() _now;

  WirdProgressWidgetPayload adapt({
    required WirdProgressSummary summary,
    required AppLocalizations localizations,
    required WirdWidgetNumeralSystem numeralSystem,
  }) {
    final DateTime generatedAt = _now();
    final amounts = _amounts(summary, numeralSystem);
    return _payload(summary, localizations, amounts, generatedAt);
  }

  WirdProgressWidgetPayload _payload(
    WirdProgressSummary summary,
    AppLocalizations localizations,
    ({String assigned, String completed, String remaining}) amounts,
    DateTime generatedAt,
  ) {
    final String subtitle = _subtitle(summary, localizations, amounts);
    return WirdProgressWidgetPayload(
      locale: localizations.localeName,
      textDirection: localizations.localeName.startsWith('ar')
          ? WirdWidgetTextDirection.rtl
          : WirdWidgetTextDirection.ltr,
      localizedTitle: localizations.wirdWidgetTitle,
      localizedSubtitle: subtitle,
      formattedAssignedAmount: amounts.assigned,
      formattedCompletedAmount: amounts.completed,
      formattedRemainingAmount: amounts.remaining,
      progressValue: summary.completionRatio,
      accessibilityLabel: '${localizations.wirdWidgetTitle}. $subtitle',
      action: _action(summary.action),
      generatedAt: generatedAt,
      expiresAt: DateTime(
        generatedAt.year,
        generatedAt.month,
        generatedAt.day + 1,
      ),
      isStale: false,
    );
  }

  ({String assigned, String completed, String remaining}) _amounts(
    WirdProgressSummary summary,
    WirdWidgetNumeralSystem numeralSystem,
  ) {
    return (
      assigned: _format(summary.assignedAmount, numeralSystem),
      completed: _format(summary.completedAmount, numeralSystem),
      remaining: _format(summary.remainingAmount, numeralSystem),
    );
  }

  String _subtitle(
    WirdProgressSummary summary,
    AppLocalizations localizations,
    ({String assigned, String completed, String remaining}) amounts,
  ) {
    return switch (summary.planStatus) {
      WirdProgressPlanStatus.none => localizations.wirdWidgetNoPlanSubtitle,
      WirdProgressPlanStatus.completed =>
        localizations.wirdWidgetPlanCompletedSubtitle,
      WirdProgressPlanStatus.active when summary.remainingAmount == 0 =>
        localizations.wirdWidgetDayCompletedSubtitle,
      WirdProgressPlanStatus.active => localizations.wirdWidgetProgressSubtitle(
        amounts.completed,
        amounts.assigned,
        amounts.remaining,
      ),
    };
  }

  String _format(int value, WirdWidgetNumeralSystem numeralSystem) {
    final String latin = value.toString();
    if (numeralSystem == WirdWidgetNumeralSystem.latin) {
      return latin;
    }
    const String arabicIndic = '٠١٢٣٤٥٦٧٨٩';
    return latin.split('').map((digit) => arabicIndic[int.parse(digit)]).join();
  }

  WirdWidgetAction _action(WirdProgressAction action) => switch (action) {
    WirdProgressAction.createPlan => WirdWidgetAction.createPlan,
    WirdProgressAction.openTodayWird => WirdWidgetAction.openTodayWird,
    WirdProgressAction.viewCompletedPlan => WirdWidgetAction.viewCompletedPlan,
  };
}
