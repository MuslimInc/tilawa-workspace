import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:tilawa/features/home/presentation/formatters/home_prayer_time_format.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('en');
  });

  final DateTime time = DateTime(2026, 7, 22, 19, 54);

  test('formats 12-hour clocks when config is off', () {
    final String label = HomePrayerTimeFormat.formatClock(
      time,
      use24HourFormat: false,
      isArabic: false,
    );
    expect(label.contains('7:54'), isTrue);
    expect(label.toUpperCase().contains('PM'), isTrue);
    expect(label.contains('19:54'), isFalse);
  });

  test('formats 24-hour clocks when config is on', () {
    expect(
      HomePrayerTimeFormat.formatClock(
        time,
        use24HourFormat: true,
        isArabic: false,
      ),
      '19:54',
    );
  });
}
