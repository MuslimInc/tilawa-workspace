import 'dart:math' as math;

enum WirdProgressPlanStatus { none, active, completed }

enum WirdProgressTargetType { pages }

enum WirdProgressAdjustment { none, automaticCatchUp, catchUp, extended }

enum WirdProgressAction { createPlan, openTodayWird, viewCompletedPlan }

final class WirdProgressSummary {
  const WirdProgressSummary._({
    required this.planStatus,
    required this.localPlanDate,
    required this.assignedAmount,
    required this.completedAmount,
    required this.remainingAmount,
    required this.completionRatio,
    required this.adjustment,
    required this.action,
    this.planId,
  });

  factory WirdProgressSummary.noPlan({required String localPlanDate}) {
    return WirdProgressSummary._(
      planStatus: WirdProgressPlanStatus.none,
      localPlanDate: localPlanDate,
      assignedAmount: 0,
      completedAmount: 0,
      remainingAmount: 0,
      completionRatio: 0,
      adjustment: WirdProgressAdjustment.none,
      action: WirdProgressAction.createPlan,
    );
  }

  factory WirdProgressSummary.active({
    required String planId,
    required String localPlanDate,
    required int assignedAmount,
    required int completedAmount,
    required WirdProgressAdjustment adjustment,
  }) {
    final int assigned = math.max(0, assignedAmount);
    final int completed = completedAmount.clamp(0, assigned);
    final int remaining = math.max(0, assigned - completed);
    return WirdProgressSummary._(
      planId: planId,
      planStatus: WirdProgressPlanStatus.active,
      localPlanDate: localPlanDate,
      assignedAmount: assigned,
      completedAmount: completed,
      remainingAmount: remaining,
      completionRatio: assigned == 0
          ? 0
          : (completed / assigned).clamp(0.0, 1.0),
      adjustment: adjustment,
      action: WirdProgressAction.openTodayWird,
    );
  }

  factory WirdProgressSummary.completed({
    required String planId,
    required String localPlanDate,
  }) {
    return WirdProgressSummary._(
      planId: planId,
      planStatus: WirdProgressPlanStatus.completed,
      localPlanDate: localPlanDate,
      assignedAmount: 0,
      completedAmount: 0,
      remainingAmount: 0,
      completionRatio: 1,
      adjustment: WirdProgressAdjustment.none,
      action: WirdProgressAction.viewCompletedPlan,
    );
  }

  static const int currentSchemaVersion = 1;

  int get schemaVersion => currentSchemaVersion;
  final String? planId;
  final WirdProgressPlanStatus planStatus;
  final String localPlanDate;
  WirdProgressTargetType get targetType => WirdProgressTargetType.pages;
  final int assignedAmount;
  final int completedAmount;
  final int remainingAmount;
  final double completionRatio;
  final WirdProgressAdjustment adjustment;
  final WirdProgressAction action;
}
