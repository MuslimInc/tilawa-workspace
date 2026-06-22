import 'package:dartz_plus/dartz_plus.dart';

import '../entities/session_pricing_type.dart';
import '../failures/quran_sessions_failure.dart';
import '../value_objects/actor_role.dart';

class CancellationPolicyConfig {
  const CancellationPolicyConfig({
    this.blockStudentCancellationWithinMinNotice = true,
    this.studentCancellationMinNotice = const Duration(hours: 1),
    this.fullRefundWindow = const Duration(hours: 24),
    this.defaultLateRefundFraction = 0,
    this.marketLateRefundFraction,
  });

  final bool blockStudentCancellationWithinMinNotice;
  final Duration studentCancellationMinNotice;
  final Duration fullRefundWindow;
  final double defaultLateRefundFraction;
  final double? marketLateRefundFraction;
}

class CancellationPolicyDecision {
  const CancellationPolicyDecision({
    required this.refundFraction,
    required this.shouldCountTeacherCancellation,
    required this.policyRuleId,
  });

  final double refundFraction;
  final bool shouldCountTeacherCancellation;
  final String policyRuleId;
}

class ConfigurableCancellationPolicy {
  const ConfigurableCancellationPolicy({
    this.config = const CancellationPolicyConfig(),
    this.now = _nowUtc,
  });

  final CancellationPolicyConfig config;
  final DateTime Function() now;

  Either<QuranSessionsFailure, CancellationPolicyDecision> evaluate({
    required ActorRole actor,
    required DateTime sessionStartsAt,
    required SessionPricingType pricingType,
  }) {
    final remaining = sessionStartsAt.difference(now());
    if (actor == ActorRole.student) {
      if (config.blockStudentCancellationWithinMinNotice &&
          remaining < config.studentCancellationMinNotice) {
        return const Left(
          PolicyViolationFailure(
            policyName: 'student_cancel_notice',
            detail: 'blocked_within_min_notice',
          ),
        );
      }

      if (pricingType == SessionPricingType.free) {
        return const Right(
          CancellationPolicyDecision(
            refundFraction: 0,
            shouldCountTeacherCancellation: false,
            policyRuleId: 'student_cancel_free',
          ),
        );
      }

      final isFullRefund = remaining >= config.fullRefundWindow;
      return Right(
        CancellationPolicyDecision(
          refundFraction: isFullRefund
              ? 1
              : (config.marketLateRefundFraction ??
                    config.defaultLateRefundFraction),
          shouldCountTeacherCancellation: false,
          policyRuleId: isFullRefund
              ? 'student_cancel_early_full_refund'
              : 'student_cancel_late_partial_refund',
        ),
      );
    }

    if (actor == ActorRole.teacher) {
      return const Right(
        CancellationPolicyDecision(
          refundFraction: 1,
          shouldCountTeacherCancellation: true,
          policyRuleId: 'teacher_cancel_full_refund',
        ),
      );
    }

    return const Right(
      CancellationPolicyDecision(
        refundFraction: 1,
        shouldCountTeacherCancellation: false,
        policyRuleId: 'admin_cancel_manual_resolution',
      ),
    );
  }

  /// Human-readable policy summary for cancellation UI.
  String describe({
    required ActorRole actor,
    required DateTime sessionStartsAt,
    required SessionPricingType pricingType,
  }) {
    final decision = evaluate(
      actor: actor,
      sessionStartsAt: sessionStartsAt,
      pricingType: pricingType,
    );
    if (decision.isLeft()) {
      return 'cancellation_blocked_within_notice';
    }
    final d = decision.fold((_) => throw StateError('noop'), (r) => r);
    if (pricingType == SessionPricingType.free) {
      return 'cancellation_free_no_refund';
    }
    if (d.refundFraction >= 1) {
      return 'cancellation_full_refund';
    }
    if (d.refundFraction > 0) {
      return 'cancellation_partial_refund';
    }
    return 'cancellation_no_refund';
  }
}

DateTime _nowUtc() => DateTime.now().toUtc();
