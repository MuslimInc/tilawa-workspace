import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/app_review/domain/entities/app_review_blocked_flow.dart';
import 'package:tilawa/features/app_review/domain/services/app_review_flow_guard.dart';

void main() {
  late AppReviewFlowGuard guard;

  setUp(() {
    guard = AppReviewFlowGuard();
  });

  test('enter and exit toggle sacred flow', () {
    expect(guard.isSacredFlowActive, isFalse);
    guard.enter(AppReviewBlockedFlow.quranReading);
    expect(guard.isSacredFlowActive, isTrue);
    expect(guard.activeFlows, contains(AppReviewBlockedFlow.quranReading));
    guard.exit(AppReviewBlockedFlow.quranReading);
    expect(guard.isSacredFlowActive, isFalse);
  });

  test('clear removes all active flows', () {
    guard
      ..enter(AppReviewBlockedFlow.athkar)
      ..enter(AppReviewBlockedFlow.prayer)
      ..clear();
    expect(guard.isSacredFlowActive, isFalse);
  });

  test('syncMainShellTab enters athkar tab flow', () {
    guard.syncMainShellTab(3);
    expect(guard.activeFlows, contains(AppReviewBlockedFlow.athkar));
    expect(guard.activeFlows, isNot(contains(AppReviewBlockedFlow.prayer)));
  });

  test('syncMainShellTab does not block qibla tab', () {
    guard.syncMainShellTab(2);
    expect(guard.isSacredFlowActive, isFalse);
  });

  test('syncMainShellTab clears tab flows for home tab', () {
    guard
      ..syncMainShellTab(3)
      ..syncMainShellTab(0);
    expect(guard.isSacredFlowActive, isFalse);
  });

  test('syncMainShellTab clears tab flows for settings tab', () {
    guard
      ..syncMainShellTab(3)
      ..syncMainShellTab(4);
    expect(guard.isSacredFlowActive, isFalse);
  });

  test('nested enter requires matching exits before flow clears', () {
    guard
      ..enter(AppReviewBlockedFlow.quranReading)
      ..enter(AppReviewBlockedFlow.quranReading);
    guard.exit(AppReviewBlockedFlow.quranReading);
    expect(guard.isSacredFlowActive, isTrue);
    guard.exit(AppReviewBlockedFlow.quranReading);
    expect(guard.isSacredFlowActive, isFalse);
  });

  test(
    'nested scope exit does not unblock while tab sacred flow is active',
    () {
      guard.syncMainShellTab(3);
      guard.enter(AppReviewBlockedFlow.athkar);
      expect(guard.isSacredFlowActive, isTrue);
      guard.exit(AppReviewBlockedFlow.athkar);
      expect(guard.isSacredFlowActive, isTrue);
      guard.syncMainShellTab(0);
      expect(guard.isSacredFlowActive, isFalse);
    },
  );
}
