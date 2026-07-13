import 'dart:convert';

import 'package:checks/checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/islamic_widgets/domain/entities/wird_progress_widget_payload.dart';

void main() {
  WirdProgressWidgetPayload sample() => WirdProgressWidgetPayload(
    locale: 'ar',
    textDirection: WirdWidgetTextDirection.rtl,
    localizedTitle: 'وِرد اليوم',
    localizedSubtitle: 'أُنجز ١٢ من ٢٠ صفحة · المتبقي ٨',
    formattedAssignedAmount: '٢٠',
    formattedCompletedAmount: '١٢',
    formattedRemainingAmount: '٨',
    progressValue: 0.6,
    accessibilityLabel: 'وِرد اليوم. أُنجز ١٢ من ٢٠ صفحة · المتبقي ٨',
    action: WirdWidgetAction.openTodayWird,
    generatedAt: DateTime(2026, 7, 12, 9, 30),
    expiresAt: DateTime(2026, 7, 13),
    isStale: false,
  );

  group('WirdProgressWidgetPayload parsing', () {
    test('round-trips a current-schema payload through toJson/fromJson', () {
      final WirdProgressWidgetPayload original = sample();

      final WirdProgressWidgetPayload decoded =
          WirdProgressWidgetPayload.fromJson(original.toJson());

      check(jsonEncode(decoded.toJson())).equals(jsonEncode(original.toJson()));
    });

    test('tryParse returns the payload for a well-formed current schema', () {
      final WirdProgressWidgetPayload original = sample();

      final WirdProgressWidgetPayload? decoded =
          WirdProgressWidgetPayload.tryParse(original.toJson());

      check(decoded).isNotNull();
      check(decoded!.action).equals(WirdWidgetAction.openTodayWird);
      check(decoded.textDirection).equals(WirdWidgetTextDirection.rtl);
    });

    test(
      'tryParse yields the setup state (null) for an unknown schema major, '
      'never crashing',
      () {
        final Map<String, Object?> future = sample().toJson()
          ..['schemaVersion'] =
              WirdProgressWidgetPayload.currentSchemaVersion + 1;

        check(WirdProgressWidgetPayload.tryParse(future)).isNull();
      },
    );

    test('tryParse yields the setup state (null) for a malformed payload', () {
      final Map<String, Object?> malformed = sample().toJson()
        ..['action'] = 'notARealAction'
        ..remove('progressValue');

      check(WirdProgressWidgetPayload.tryParse(malformed)).isNull();
    });

    test(
      'fromJson throws FormatException on an unsupported schema version',
      () {
        final Map<String, Object?> future = sample().toJson()
          ..['schemaVersion'] = 99;

        check(
          () => WirdProgressWidgetPayload.fromJson(future),
        ).throws<FormatException>();
      },
    );
  });
}
