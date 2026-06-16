import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tilawa_core/constants/analytics_constants.dart';
import 'package:tilawa_core/services/analytics_service.dart';

import '../../domain/entities/today_plan.dart';
import '../../domain/usecases/generate_today_plan_use_case.dart';
import '../../domain/usecases/set_today_plan_task_completed_use_case.dart';
import 'today_plan_event.dart';
import 'today_plan_state.dart';

final class TodayPlanBloc extends Bloc<TodayPlanEvent, TodayPlanState> {
  TodayPlanBloc(
    this._generatePlan,
    this._setTaskCompleted,
    this._analyticsService,
  ) : super(const TodayPlanInitial()) {
    on<TodayPlanStarted>(_onStarted);
    on<TodayPlanSourceChanged>(_onSourceChanged);
    on<TodayPlanTaskToggled>(_onTaskToggled);
    on<TodayPlanContinuePressed>(_onContinuePressed);
    on<TodayPlanSupportPressed>(_onSupportPressed);
  }

  final GenerateTodayPlanUseCase _generatePlan;
  final SetTodayPlanTaskCompletedUseCase _setTaskCompleted;
  final AnalyticsService _analyticsService;

  Future<void> _onStarted(
    TodayPlanStarted event,
    Emitter<TodayPlanState> emit,
  ) async {
    emit(const TodayPlanLoading());
    await _emitGeneratedPlan(emit, logViewed: true);
  }

  Future<void> _onSourceChanged(
    TodayPlanSourceChanged event,
    Emitter<TodayPlanState> emit,
  ) {
    return _emitGeneratedPlan(emit, logViewed: false);
  }

  Future<void> _emitGeneratedPlan(
    Emitter<TodayPlanState> emit, {
    required bool logViewed,
  }) async {
    final result = await _generatePlan();
    result.fold(
      (failure) =>
          emit(TodayPlanFailure(failure.message ?? 'Plan unavailable')),
      (plan) {
        emit(TodayPlanLoaded(plan));
        if (logViewed) {
          _logEvent(AnalyticsEvents.todayPlanViewed, plan: plan);
        }
      },
    );
  }

  Future<void> _onTaskToggled(
    TodayPlanTaskToggled event,
    Emitter<TodayPlanState> emit,
  ) async {
    final TodayPlanState current = state;
    if (current is! TodayPlanLoaded) {
      return;
    }
    final TodayPlanTask task = event.task;
    final bool completed = !task.isCompleted;
    final result = await _setTaskCompleted(
      dateKey: current.plan.dateKey,
      taskId: task.id,
      completed: completed,
    );
    result.fold(
      (failure) =>
          emit(TodayPlanFailure(failure.message ?? 'Plan unavailable')),
      (_) {
        final updatedTask = task.copyWith(
          status: completed
              ? TodayPlanTaskStatus.completed
              : TodayPlanTaskStatus.pending,
        );
        final updatedPlan = current.plan.copyWithTask(updatedTask);
        emit(TodayPlanLoaded(updatedPlan));
        _logEvent(
          AnalyticsEvents.todayPlanTaskCompleted,
          plan: updatedPlan,
          task: updatedTask,
        );
        if (updatedPlan.isCompleted) {
          _logEvent(AnalyticsEvents.todayPlanCompleted, plan: updatedPlan);
        }
      },
    );
  }

  Future<void> _onContinuePressed(
    TodayPlanContinuePressed event,
    Emitter<TodayPlanState> emit,
  ) async {
    final TodayPlanState current = state;
    if (current is! TodayPlanLoaded) {
      return;
    }
    final TodayPlanTask? task = current.plan.nextTask;
    _logEvent(AnalyticsEvents.todayPlanStarted, plan: current.plan, task: task);
    if (task?.kind == TodayPlanTaskKind.listening) {
      _logEvent(
        AnalyticsEvents.todayPlanContinueListening,
        plan: current.plan,
        task: task,
      );
    } else {
      _logEvent(
        AnalyticsEvents.todayPlanContinueReading,
        plan: current.plan,
        task: task,
      );
    }
  }

  Future<void> _onSupportPressed(
    TodayPlanSupportPressed event,
    Emitter<TodayPlanState> emit,
  ) async {
    final TodayPlanState current = state;
    if (current is TodayPlanLoaded) {
      _logEvent(AnalyticsEvents.todayPlanPremiumClicked, plan: current.plan);
    }
  }

  Future<void> _logEvent(
    String name, {
    TodayPlan? plan,
    TodayPlanTask? task,
  }) {
    return _analyticsService.logEvent(
      name,
      parameters: <String, Object>{
        if (plan != null) 'date_key': plan.dateKey,
        if (plan != null) 'completed_count': plan.completedCount,
        if (plan != null) 'task_count': plan.totalCount,
        if (plan != null) 'minutes_remaining': plan.minutesRemaining,
        if (plan != null) 'streak_days': plan.streakDays,
        if (plan != null) 'is_adaptive': plan.isAdaptive,
        if (task != null) 'task_id': task.id,
        if (task != null) 'task_kind': task.kind.name,
      },
    );
  }
}
