import 'package:test/test.dart';
import 'package:tilawa/features/athkar/domain/entities/athkar_category.dart';
import 'package:tilawa/features/athkar/domain/pinned_athkar_display_order.dart';

void main() {
  const morning = AthkarCategory(
    id: 1,
    nameAr: 'أذكار الصباح',
    nameEn: 'Morning Athkar',
    icon: 'wb_sunny_rounded',
  );
  const evening = AthkarCategory(
    id: 2,
    nameAr: 'أذكار المساء',
    nameEn: 'Evening Athkar',
    icon: 'nights_stay_rounded',
  );
  const neutral = AthkarCategory(
    id: 3,
    nameAr: 'أذكار النوم',
    nameEn: 'Sleep Athkar',
    icon: 'mosque_rounded',
  );

  test('surfaces morning athkar first before 17:00', () {
    final ordered = orderPinnedAthkarForTime(
      pinned: const [evening, neutral, morning],
      now: DateTime(2026, 6, 18, 10),
    );

    expect(ordered.first.id, morning.id);
  });

  test('surfaces evening athkar first from 17:00 onward', () {
    final ordered = orderPinnedAthkarForTime(
      pinned: const [morning, neutral, evening],
      now: DateTime(2026, 6, 18, 19),
    );

    expect(ordered.first.id, evening.id);
  });
}
