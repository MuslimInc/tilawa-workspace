import 'package:checks/checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_sessions/quran_sessions.dart';

void main() {
  group('ConfigurableCompensationPolicy', () {
    const policy = ConfigurableCompensationPolicy();

    test('T-P01 teacher cancel restores session credit', () {
      final result = policy.evaluate(
        triggerStatus: SessionLifecycleStatus.cancelledByTeacher,
        pricingType: SessionPricingType.fixedPerSession,
      );
      check(result.actions.single.type).equals(
        CompensationActionType.restoreSessionCredit,
      );
    });

    test('T-P02 teacher no-show adds wallet credit', () {
      final result = policy.evaluate(
        triggerStatus: SessionLifecycleStatus.teacherNoShow,
        pricingType: SessionPricingType.fixedPerSession,
      );
      check(result.actions).has((it) => it.length, 'length').equals(2);
      check(result.actions.last.type).equals(
        CompensationActionType.issueWalletCredit,
      );
    });

    test('T-P03 admin manual picks refund action', () {
      final result = policy.evaluate(
        triggerStatus: SessionLifecycleStatus.disputed,
        pricingType: SessionPricingType.fixedPerSession,
        adminManualRefund: true,
      );
      check(result.actions.single.type).equals(
        CompensationActionType.processPaymentRefund,
      );
    });

    test('T-P05 subscription pricing extends subscription', () {
      final result = policy.evaluate(
        triggerStatus: SessionLifecycleStatus.cancelledByTeacher,
        pricingType: SessionPricingType.subscription,
      );
      check(result.actions.single.type).equals(
        CompensationActionType.extendSubscriptionPeriod,
      );
    });
  });
}
