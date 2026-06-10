import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/athkar/domain/entities/tasbeeh_dhikr.dart';
import 'package:tilawa/features/athkar/domain/policies/tasbeeh_target_reached_policy.dart';

void main() {
  const policy = TasbeehTargetReachedPolicy();
  final before = TasbeehDhikr(
    id: '1',
    text: 'Subhan Allah',
    count: 32,
    targetCount: 33,
    targetReachedNotified: false,
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  );

  test('notifies when count first crosses target', () {
    expect(
      policy.shouldNotifyOnIncrement(
        before: before,
        after: before.copyWith(count: 33),
      ),
      isTrue,
    );
  });

  test('does not notify when already at or above target', () {
    final atTarget = before.copyWith(count: 33, targetReachedNotified: true);
    expect(
      policy.shouldNotifyOnIncrement(
        before: atTarget,
        after: atTarget.copyWith(count: 34),
      ),
      isFalse,
    );
  });

  test('does not notify below target', () {
    expect(
      policy.shouldNotifyOnIncrement(
        before: before,
        after: before.copyWith(count: 31),
      ),
      isFalse,
    );
  });

  test('does not notify when target is zero', () {
    final zeroTarget = before.copyWith(targetCount: 0);
    expect(
      policy.shouldNotifyOnIncrement(
        before: zeroTarget,
        after: zeroTarget.copyWith(count: 5),
      ),
      isFalse,
    );
  });
}
