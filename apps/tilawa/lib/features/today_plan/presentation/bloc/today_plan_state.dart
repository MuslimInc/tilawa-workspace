import '../../domain/entities/today_plan.dart';

sealed class TodayPlanState {
  const TodayPlanState();
}

final class TodayPlanInitial extends TodayPlanState {
  const TodayPlanInitial();
}

final class TodayPlanLoading extends TodayPlanState {
  const TodayPlanLoading();
}

final class TodayPlanLoaded extends TodayPlanState {
  const TodayPlanLoaded(this.plan);

  final TodayPlan plan;
}

final class TodayPlanFailure extends TodayPlanState {
  const TodayPlanFailure(this.message);

  final String message;
}
