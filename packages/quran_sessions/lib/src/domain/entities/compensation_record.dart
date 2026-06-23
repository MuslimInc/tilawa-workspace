import 'package:equatable/equatable.dart';

enum CompensationActionType {
  restoreSessionCredit,
  issueWalletCredit,
  processPaymentRefund,
  extendSubscriptionPeriod,
}

class CompensationAction extends Equatable {
  const CompensationAction({
    required this.type,
    this.amountUsd,
    this.reasonCode,
  });

  final CompensationActionType type;
  final double? amountUsd;
  final String? reasonCode;

  @override
  List<Object?> get props => [type, amountUsd, reasonCode];
}

class CompensationRecord extends Equatable {
  const CompensationRecord({
    required this.sessionId,
    required this.actions,
    required this.policyRuleId,
    required this.createdAt,
    this.retryCount = 0,
    this.lastFailureCode,
  });

  final String sessionId;
  final List<CompensationAction> actions;
  final String policyRuleId;
  final DateTime createdAt;
  final int retryCount;
  final String? lastFailureCode;

  @override
  List<Object?> get props => [
    sessionId,
    actions,
    policyRuleId,
    createdAt,
    retryCount,
    lastFailureCode,
  ];
}
