import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../rtl_test_matrix.dart';

typedef TimePair = (TimeOfDay start, TimeOfDay end);

Future<void> _openDualSheet(
  WidgetTester tester, {
  required Locale locale,
  required TextDirection direction,
  required bool Function(TimeOfDay start, TimeOfDay end) canConfirm,
  String? Function(BuildContext, TimeOfDay, TimeOfDay)? errorText,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('ar')],
      theme: AppTheme.getLightTheme(primaryColor: AppColors.defaultPrimary),
      home: Directionality(
        textDirection: direction,
        child: Builder(
          builder: (context) {
            return Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () {
                    showTilawaDualCupertinoPickerSheet<TimeOfDay>(
                      context: context,
                      title: locale.languageCode == 'ar'
                          ? 'تعديل الفترة'
                          : 'Edit range',
                      start: TilawaPickerSegment(
                        label: locale.languageCode == 'ar'
                            ? 'وقت البدء'
                            : 'Start time',
                        value: const TimeOfDay(hour: 9, minute: 0),
                      ),
                      end: TilawaPickerSegment(
                        label: locale.languageCode == 'ar'
                            ? 'وقت الانتهاء'
                            : 'End time',
                        value: const TimeOfDay(hour: 17, minute: 0),
                      ),
                      formatValue: (ctx, value) {
                        return MaterialLocalizations.of(ctx).formatTimeOfDay(
                          value,
                          alwaysUse24HourFormat: false,
                        );
                      },
                      toDateTime: (value) =>
                          DateTime(2020, 1, 1, value.hour, value.minute),
                      fromDateTime: (dateTime) => TimeOfDay(
                        hour: dateTime.hour,
                        minute: dateTime.minute,
                      ),
                      primaryLabel: locale.languageCode == 'ar'
                          ? 'استخدام هذه الأوقات'
                          : 'Use these times',
                      canConfirm: canConfirm,
                      errorText: errorText,
                      minuteInterval: 15,
                    );
                  },
                  child: const Text('Open'),
                ),
              ),
            );
          },
        ),
      ),
    ),
  );

  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
}

void main() {
  group('showTilawaDualCupertinoPickerSheet', () {
    testWidgets('disables primary action when canConfirm is false', (
      tester,
    ) async {
      await _openDualSheet(
        tester,
        locale: const Locale('en'),
        direction: TextDirection.ltr,
        canConfirm: (_, _) => false,
        errorText: (_, _, _) => 'Invalid range',
      );

      final button = tester.widget<TilawaButton>(find.byType(TilawaButton));
      expect(button.onPressed, isNull);
      expect(find.text('Invalid range'), findsOneWidget);
    });

    testWidgets('selecting end segment keeps both segment values visible', (
      tester,
    ) async {
      await _openDualSheet(
        tester,
        locale: const Locale('en'),
        direction: TextDirection.ltr,
        canConfirm: (_, _) => true,
      );

      final endCard = find.ancestor(
        of: find.text('End time'),
        matching: find.byType(TilawaPickerSegmentCard),
      );
      await tester.tap(endCard);
      await tester.pumpAndSettle();

      expect(find.text('Start time'), findsOneWidget);
      expect(find.text('End time'), findsOneWidget);
      expect(find.byType(CupertinoDatePicker), findsOneWidget);
    });

    testInBothDirections('renders dual segment cards in sheet', (
      tester,
      direction,
    ) async {
      await _openDualSheet(
        tester,
        locale: const Locale('en'),
        direction: direction,
        canConfirm: (_, _) => true,
      );

      expect(find.byType(TilawaPickerSegmentCard), findsNWidgets(2));
      expect(find.text('Use these times'), findsOneWidget);
      expect(find.byIcon(TilawaIcons.dismiss), findsNothing);
    });

    testWidgets('formats segment values with Arabic locale markers', (
      tester,
    ) async {
      await _openDualSheet(
        tester,
        locale: const Locale('ar'),
        direction: TextDirection.rtl,
        canConfirm: (_, _) => true,
      );

      final segmentCards = tester.widgetList<TilawaPickerSegmentCard>(
        find.byType(TilawaPickerSegmentCard),
      );
      final formattedValues = segmentCards
          .map((card) => card.value)
          .where((value) => value.contains('ص') || value.contains('م'))
          .toList();

      expect(formattedValues, isNotEmpty);
    });
  });
}
