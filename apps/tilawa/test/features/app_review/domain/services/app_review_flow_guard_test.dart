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

  test('syncMainShellTab leaves home tab without tab-owned flows', () {
    guard.syncMainShellTab(0);
    expect(guard.isSacredFlowActive, isFalse);
  });

  test('syncMainShellTab leaves reciters tab without tab-owned flows', () {
    guard.syncMainShellTab(1);
    expect(guard.isSacredFlowActive, isFalse);
  });

  test('syncMainShellTab leaves settings tab without tab-owned flows', () {
    guard.syncMainShellTab(2);
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
    'nested scope exit does not unblock while another scope remains active',
    () {
      guard
        ..enter(AppReviewBlockedFlow.athkar)
        ..enter(AppReviewBlockedFlow.quranReading);
      expect(guard.isSacredFlowActive, isTrue);
      guard.exit(AppReviewBlockedFlow.quranReading);
      expect(guard.isSacredFlowActive, isTrue);
      guard.exit(AppReviewBlockedFlow.athkar);
      expect(guard.isSacredFlowActive, isFalse);
    },
  );
}
