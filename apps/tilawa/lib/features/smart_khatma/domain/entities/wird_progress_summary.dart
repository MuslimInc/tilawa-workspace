enum WirdProgressPlanStatus { none, active, paused, completed }

enum WirdProgressTargetType { pages, minutes }

enum WirdProgressAdjustment { none, automaticCatchUp, catchUp, extended }

enum WirdProgressAction {
  createPlan,
  openTodayWird,
  resumePlan,
  viewCompletedPlan,
}

final class WirdProgressSummary {
  const WirdProgressSummary({
    required this.schemaVersion,
    required this.planStatus,
    required this.localPlanDate,
    required this.targetType,
    required this.assignedAmount,
    required this.completedAmount,
    required this.remainingAmount,
    required this.completionRatio,
    required this.adjustment,
    required this.action,
    this.planId,
  });

  static const int currentSchemaVersion = 1;

  final int schemaVersion;
  final String? planId;
  final WirdProgressPlanStatus planStatus;
  final String localPlanDate;
  final WirdProgressTargetType targetType;
  final int assignedAmount;
  final int completedAmount;
  final int remainingAmount;
  final double completionRatio;
  final WirdProgressAdjustment adjustment;
  final WirdProgressAction action;
}
