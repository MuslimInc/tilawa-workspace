import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/auth/application/account_deletion_flow_tracker.dart';

void main() {
  late AccountDeletionFlowTracker tracker;

  setUp(() {
    tracker = AccountDeletionFlowTracker();
  });

  test('markDeletionStarted suppresses login auto sign-in', () {
    tracker.markDeletionStarted();

    expect(tracker.deletionInProgress, isTrue);
    expect(tracker.suppressLoginAutoSignIn, isTrue);
    expect(tracker.pendingLoginNavigationAfterDeletion, isFalse);
  });

  test('markDeletionSucceeded requests login navigation', () {
    tracker.markDeletionStarted();
    tracker.markDeletionSucceeded();

    expect(tracker.deletionInProgress, isFalse);
    expect(tracker.suppressLoginAutoSignIn, isTrue);
    expect(tracker.pendingLoginNavigationAfterDeletion, isTrue);
  });

  test('markDeletionEndedWithoutSuccess clears pending navigation', () {
    tracker.markDeletionStarted();
    tracker.markDeletionEndedWithoutSuccess();

    expect(tracker.deletionInProgress, isFalse);
    expect(tracker.suppressLoginAutoSignIn, isFalse);
    expect(tracker.pendingLoginNavigationAfterDeletion, isFalse);
  });

  test('clearPendingLoginNavigation clears the navigation flag', () {
    tracker.markDeletionStarted();
    tracker.markDeletionSucceeded();
    tracker.clearPendingLoginNavigation();

    expect(tracker.pendingLoginNavigationAfterDeletion, isFalse);
  });

  test('clearLoginAutoSignInSuppression allows auto sign-in again', () {
    tracker.markDeletionStarted();
    tracker.markDeletionSucceeded();
    tracker.clearLoginAutoSignInSuppression();

    expect(tracker.suppressLoginAutoSignIn, isFalse);
  });

  test('notifies listeners when deletion ends without success', () {
    var notifications = 0;
    tracker.addListener(() => notifications++);

    tracker.markDeletionStarted();
    tracker.markDeletionEndedWithoutSuccess();

    expect(notifications, 2);
    expect(tracker.deletionInProgress, isFalse);
  });
}
