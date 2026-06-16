import '../../domain/entities/today_plan.dart';

sealed class TodayPlanEvent {
  const TodayPlanEvent();
}

final class TodayPlanStarted extends TodayPlanEvent {
  const TodayPlanStarted();
}

final class TodayPlanSourceChanged extends TodayPlanEvent {
  const TodayPlanSourceChanged();
}

final class TodayPlanTaskToggled extends TodayPlanEvent {
  const TodayPlanTaskToggled(this.task);

  final TodayPlanTask task;
}

final class TodayPlanContinuePressed extends TodayPlanEvent {
  const TodayPlanContinuePressed();
}

final class TodayPlanSupportPressed extends TodayPlanEvent {
  const TodayPlanSupportPressed();
}
