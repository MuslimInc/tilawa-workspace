enum WirdWidgetTextDirection { ltr, rtl }

enum WirdWidgetAction { createPlan, openTodayWird, viewCompletedPlan }

final class WirdProgressWidgetPayload {
  WirdProgressWidgetPayload({
    required this.locale,
    required this.textDirection,
    required this.localizedTitle,
    required this.localizedSubtitle,
    required this.formattedAssignedAmount,
    required this.formattedCompletedAmount,
    required this.formattedRemainingAmount,
    required this.progressValue,
    required this.accessibilityLabel,
    required this.action,
    required this.generatedAt,
    required this.expiresAt,
    required this.isStale,
  }) : assert(
         progressValue >= 0 && progressValue <= 1,
         'progressValue must be between 0 and 1',
       ),
       assert(
         !expiresAt.isBefore(generatedAt),
         'expiresAt must not precede generatedAt',
       );

  static const int currentSchemaVersion = 1;

  int get schemaVersion => currentSchemaVersion;
  final String locale;
  final WirdWidgetTextDirection textDirection;
  final String localizedTitle;
  final String localizedSubtitle;
  final String formattedAssignedAmount;
  final String formattedCompletedAmount;
  final String formattedRemainingAmount;
  final double progressValue;
  final String accessibilityLabel;
  final WirdWidgetAction action;
  final DateTime generatedAt;
  final DateTime expiresAt;
  final bool isStale;

  Map<String, Object> toJson() => <String, Object>{
    'schemaVersion': schemaVersion,
    'locale': locale,
    'textDirection': textDirection.name,
    'localizedTitle': localizedTitle,
    'localizedSubtitle': localizedSubtitle,
    'formattedAssignedAmount': formattedAssignedAmount,
    'formattedCompletedAmount': formattedCompletedAmount,
    'formattedRemainingAmount': formattedRemainingAmount,
    'progressValue': progressValue,
    'accessibilityLabel': accessibilityLabel,
    'action': action.name,
    'generatedAt': generatedAt.toIso8601String(),
    'expiresAt': expiresAt.toIso8601String(),
    'isStale': isStale,
  };
}
