import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/islamic_widgets/domain/entities/wird_progress_widget_payload.dart';
import 'package:tilawa/features/islamic_widgets/presentation/adapters/wird_progress_widget_adapter.dart';
import 'package:tilawa/features/smart_khatma/domain/entities/wird_progress_summary.dart';
import 'package:tilawa/l10n/generated/app_localizations.dart';

void main() {
  final DateTime generatedAt = DateTime(2026, 7, 12, 9, 30);

  test('maps no-plan semantics to localized English setup copy', () {
    final payload = _adapter(generatedAt).adapt(
      summary: WirdProgressSummary.noPlan(localPlanDate: '2026-07-12'),
      localizations: lookupAppLocalizations(const Locale('en')),
      numeralSystem: WirdWidgetNumeralSystem.latin,
    );

    expect(payload.schemaVersion, 1);
    expect(payload.locale, 'en');
    expect(payload.textDirection, WirdWidgetTextDirection.ltr);
    expect(payload.localizedTitle, "Today's Wird");
    expect(payload.localizedSubtitle, 'Start a calm Quran reading plan');
    expect(payload.action, WirdWidgetAction.createPlan);
    expect(payload.progressValue, 0);
  });

  test('formats Arabic active progress with requested Arabic-Indic digits', () {
    final payload = _adapter(generatedAt).adapt(
      summary: WirdProgressSummary.active(
        planId: 'local-plan',
        localPlanDate: '2026-07-12',
        assignedAmount: 20,
        completedAmount: 12,
        adjustment: WirdProgressAdjustment.none,
      ),
      localizations: lookupAppLocalizations(const Locale('ar')),
      numeralSystem: WirdWidgetNumeralSystem.arabicIndic,
    );

    expect(payload.textDirection, WirdWidgetTextDirection.rtl);
    expect(payload.formattedAssignedAmount, '٢٠');
    expect(payload.formattedCompletedAmount, '١٢');
    expect(payload.formattedRemainingAmount, '٨');
    expect(payload.localizedSubtitle, contains('١٢'));
    expect(payload.progressValue, 0.6);
    expect(payload.action, WirdWidgetAction.openTodayWird);
  });

  test('numeral preference is independent from text direction', () {
    final payload = _adapter(generatedAt).adapt(
      summary: _activeSummary(completedAmount: 3),
      localizations: lookupAppLocalizations(const Locale('ar')),
      numeralSystem: WirdWidgetNumeralSystem.latin,
    );

    expect(payload.textDirection, WirdWidgetTextDirection.rtl);
    expect(payload.formattedCompletedAmount, '3');
  });

  test('distinguishes completed day from completed plan', () {
    final localizations = lookupAppLocalizations(const Locale('en'));
    final adapter = _adapter(generatedAt);

    final completedDay = adapter.adapt(
      summary: _activeSummary(completedAmount: 20),
      localizations: localizations,
      numeralSystem: WirdWidgetNumeralSystem.latin,
    );
    final completedPlan = adapter.adapt(
      summary: WirdProgressSummary.completed(
        planId: 'local-plan',
        localPlanDate: '2026-07-12',
      ),
      localizations: localizations,
      numeralSystem: WirdWidgetNumeralSystem.latin,
    );

    expect(completedDay.localizedSubtitle, "Today's Wird is complete");
    expect(completedDay.action, WirdWidgetAction.openTodayWird);
    expect(completedPlan.localizedSubtitle, 'Khatma complete');
    expect(completedPlan.action, WirdWidgetAction.viewCompletedPlan);
  });

  test('serializes a versioned display-only payload with local expiry', () {
    final payload = _adapter(generatedAt).adapt(
      summary: _activeSummary(completedAmount: 5),
      localizations: lookupAppLocalizations(const Locale('en')),
      numeralSystem: WirdWidgetNumeralSystem.latin,
    );

    expect(payload.generatedAt, generatedAt);
    expect(payload.expiresAt, DateTime(2026, 7, 13));
    expect(payload.isStale, isFalse);
    expect(payload.accessibilityLabel, contains(payload.localizedSubtitle));
    expect(payload.toJson(), <String, Object>{
      'schemaVersion': 1,
      'locale': 'en',
      'textDirection': 'ltr',
      'localizedTitle': "Today's Wird",
      'localizedSubtitle': '5 of 20 pages completed · 15 remaining',
      'formattedAssignedAmount': '20',
      'formattedCompletedAmount': '5',
      'formattedRemainingAmount': '15',
      'progressValue': 0.25,
      'accessibilityLabel':
          "Today's Wird. 5 of 20 pages completed · 15 remaining",
      'action': 'openTodayWird',
      'generatedAt': '2026-07-12T09:30:00.000',
      'expiresAt': '2026-07-13T00:00:00.000',
      'isStale': false,
    });
  });
}

WirdProgressWidgetAdapter _adapter(DateTime now) =>
    WirdProgressWidgetAdapter(now: () => now);

WirdProgressSummary _activeSummary({required int completedAmount}) {
  return WirdProgressSummary.active(
    planId: 'local-plan',
    localPlanDate: '2026-07-12',
    assignedAmount: 20,
    completedAmount: completedAmount,
    adjustment: WirdProgressAdjustment.none,
  );
}
