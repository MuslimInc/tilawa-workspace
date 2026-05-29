import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/athkar/domain/entities/tasbeeh_dhikr.dart';
import 'package:tilawa/features/athkar/domain/policies/tasbeeh_target_reached_policy.dart';

void main() {
  const policy = TasbeehTargetReachedPolicy();
  final dhikr = TasbeehDhikr(
    id: '1',
    text: 'Subhan Allah',
    count: 33,
    targetCount: 33,
    targetReachedNotified: false,
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  );

  test('notifies when count meets target', () {
    expect(policy.shouldNotify(dhikr), isTrue);
  });

  test('does not notify below target', () {
    expect(policy.shouldNotify(dhikr.copyWith(count: 32)), isFalse);
  });

  test('does not notify when target is zero', () {
    expect(
      policy.shouldNotify(dhikr.copyWith(targetCount: 0, count: 5)),
      isFalse,
    );
  });
}
