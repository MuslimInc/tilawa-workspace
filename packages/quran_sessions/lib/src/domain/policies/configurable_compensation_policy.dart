import '../entities/compensation_record.dart';
import '../entities/session_lifecycle_status.dart';
import '../entities/session_pricing_type.dart';

class CompensationPolicyConfig {
  const CompensationPolicyConfig({
    this.teacherNoShowWalletCreditUsd = 5,
    this.subscriptionExtensionDays = 7,
  });

  final double teacherNoShowWalletCreditUsd;
  final int subscriptionExtensionDays;
}

class CompensationPolicyDecision {
  const CompensationPolicyDecision({
    required this.policyRuleId,
    required this.actions,
  });

  final String policyRuleId;
  final List<CompensationAction> actions;
}

class ConfigurableCompensationPolicy {
  const ConfigurableCompensationPolicy({
    this.config = const CompensationPolicyConfig(),
  });

  final CompensationPolicyConfig config;

  CompensationPolicyDecision evaluate({
    required SessionLifecycleStatus triggerStatus,
    required SessionPricingType pricingType,
    bool adminManualRefund = false,
  }) {
    if (adminManualRefund) {
      return const CompensationPolicyDecision(
        policyRuleId: 'admin_manual_refund',
        actions: [
          CompensationAction(type: CompensationActionType.processPaymentRefund),
        ],
      );
    }

    if (pricingType == SessionPricingType.subscription) {
      return CompensationPolicyDecision(
        policyRuleId: 'subscription_extension',
        actions: [
          CompensationAction(
            type: CompensationActionType.extendSubscriptionPeriod,
            reasonCode: 'days_${config.subscriptionExtensionDays}',
          ),
        ],
      );
    }

    return switch (triggerStatus) {
      SessionLifecycleStatus.cancelledByTeacher =>
        const CompensationPolicyDecision(
          policyRuleId: 'teacher_cancel_credit_restore',
          actions: [
            CompensationAction(
              type: CompensationActionType.restoreSessionCredit,
            ),
          ],
        ),
      SessionLifecycleStatus.teacherNoShow => CompensationPolicyDecision(
        policyRuleId: 'teacher_no_show_wallet_credit',
        actions: [
          const CompensationAction(
            type: CompensationActionType.restoreSessionCredit,
          ),
          CompensationAction(
            type: CompensationActionType.issueWalletCredit,
            amountUsd: config.teacherNoShowWalletCreditUsd,
          ),
        ],
      ),
      _ => const CompensationPolicyDecision(
        policyRuleId: 'no_compensation',
        actions: [],
      ),
    };
  }
}
