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

  /// Tolerant decode at the widget-render boundary.
  ///
  /// Returns `null` when the payload cannot be trusted — an unknown
  /// [schemaVersion] major or any malformed field — so the caller shows the
  /// setup/no-data state instead of crashing (FR-041A1.9; Contract B invariant
  /// "Unknown schemaVersion major → render the setup/no-data state, never
  /// crash"). Well-formed current-version payloads round-trip [toJson].
  static WirdProgressWidgetPayload? tryParse(Map<String, Object?> json) {
    try {
      return WirdProgressWidgetPayload.fromJson(json);
    } on Object {
      return null;
    }
  }

  /// Strict decode of a current-schema payload. Throws [FormatException] on an
  /// unsupported [schemaVersion]; prefer [tryParse] at render boundaries.
  factory WirdProgressWidgetPayload.fromJson(Map<String, Object?> json) {
    final Object? version = json['schemaVersion'];
    if (version != currentSchemaVersion) {
      throw FormatException(
        'Unsupported wird widget schemaVersion: $version '
        '(expected $currentSchemaVersion)',
      );
    }
    return WirdProgressWidgetPayload(
      locale: json['locale']! as String,
      textDirection: WirdWidgetTextDirection.values.byName(
        json['textDirection']! as String,
      ),
      localizedTitle: json['localizedTitle']! as String,
      localizedSubtitle: json['localizedSubtitle']! as String,
      formattedAssignedAmount: json['formattedAssignedAmount']! as String,
      formattedCompletedAmount: json['formattedCompletedAmount']! as String,
      formattedRemainingAmount: json['formattedRemainingAmount']! as String,
      progressValue: (json['progressValue']! as num).toDouble(),
      accessibilityLabel: json['accessibilityLabel']! as String,
      action: WirdWidgetAction.values.byName(json['action']! as String),
      generatedAt: DateTime.parse(json['generatedAt']! as String),
      expiresAt: DateTime.parse(json['expiresAt']! as String),
      isStale: json['isStale']! as bool,
    );
  }
}
