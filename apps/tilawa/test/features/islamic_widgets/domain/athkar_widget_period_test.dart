import 'package:checks/checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/islamic_widgets/domain/services/athkar_widget_period_resolver.dart';

void main() {
  const resolver = AthkarWidgetPeriodResolver();

  group('AthkarWidgetPeriodResolver', () {
    test('mid-morning resolves to the morning window', () {
      final state = resolver.resolve(DateTime(2026, 7, 11, 8, 30));
      check(state.period).equals(AthkarWidgetPeriod.morning);
      check(state.periodKey).equals('M-2026-07-11');
      check(state.nextTransition).equals(DateTime(2026, 7, 11, 15));
    });

    test('morning starts exactly at 04:00', () {
      final state = resolver.resolve(DateTime(2026, 7, 11, 4));
      check(state.period).equals(AthkarWidgetPeriod.morning);
      check(state.periodKey).equals('M-2026-07-11');
    });

    test('evening starts exactly at 15:00', () {
      final state = resolver.resolve(DateTime(2026, 7, 11, 15));
      check(state.period).equals(AthkarWidgetPeriod.evening);
      check(state.periodKey).equals('E-2026-07-11');
      check(state.nextTransition).equals(DateTime(2026, 7, 12, 4));
    });

    test('after midnight still belongs to the previous evening', () {
      final state = resolver.resolve(DateTime(2026, 7, 12, 2, 59));
      check(state.period).equals(AthkarWidgetPeriod.evening);
      check(state.periodKey).equals('E-2026-07-11');
      check(state.nextTransition).equals(DateTime(2026, 7, 12, 4));
    });

    test('period keys differ across days (progress reset rule)', () {
      final day1 = resolver.resolve(DateTime(2026, 7, 11, 9));
      final day2 = resolver.resolve(DateTime(2026, 7, 12, 9));
      check(day1.periodKey).not((k) => k.equals(day2.periodKey));
    });

    test('morning and evening of the same day have distinct keys', () {
      final morning = resolver.resolve(DateTime(2026, 7, 11, 9));
      final evening = resolver.resolve(DateTime(2026, 7, 11, 20));
      check(morning.periodKey).not((k) => k.equals(evening.periodKey));
    });
  });
}
