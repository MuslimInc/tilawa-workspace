import 'package:tilawa/features/athkar/domain/entities/tasbeeh_dhikr.dart';
import 'package:tilawa/features/athkar/domain/entities/tasbeeh_layout_mode.dart';
import 'package:tilawa/features/athkar/domain/repositories/tasbeeh_layout_preference_repository.dart';
import 'package:tilawa/features/athkar/domain/repositories/tasbeeh_repository.dart';
import 'package:tilawa/features/athkar/domain/services/tasbeeh_reminder_scheduler.dart';
import 'package:tilawa/features/athkar/domain/services/tasbeeh_target_feedback_service.dart';
import 'package:tilawa/features/athkar/domain/usecases/clear_all_saved_tasbeeh_use_case.dart';
import 'package:tilawa/features/athkar/domain/usecases/delete_tasbeeh_dhikr_use_case.dart';
import 'package:tilawa/features/athkar/domain/usecases/get_saved_tasbeeh_use_case.dart';
import 'package:tilawa/features/athkar/domain/usecases/get_tasbeeh_layout_mode_use_case.dart';
import 'package:tilawa/features/athkar/domain/usecases/increment_tasbeeh_count_use_case.dart';
import 'package:tilawa/features/athkar/domain/usecases/reset_tasbeeh_count_use_case.dart';
import 'package:tilawa/features/athkar/domain/usecases/save_custom_tasbeeh_use_case.dart';
import 'package:tilawa/features/athkar/domain/usecases/set_tasbeeh_layout_mode_use_case.dart';
import 'package:tilawa/features/athkar/domain/usecases/set_tasbeeh_reminder_use_case.dart';
import 'package:tilawa/features/athkar/domain/usecases/set_tasbeeh_target_count_use_case.dart';
import 'package:tilawa/features/athkar/presentation/cubit/tasbeeh_cubit.dart';

class FakeTasbeehLayoutPreferenceRepository
    implements TasbeehLayoutPreferenceRepository {
  TasbeehLayoutMode mode = TasbeehLayoutMode.list;

  @override
  Future<TasbeehLayoutMode> getLayoutMode() async => mode;

  @override
  Future<void> setLayoutMode(TasbeehLayoutMode mode) async {
    this.mode = mode;
  }
}

class NoOpTasbeehReminderScheduler implements TasbeehReminderScheduler {
  @override
  Future<void> cancelReminder(String dhikrId) async {}

  @override
  Future<void> cancelReminders(Iterable<String> dhikrIds) async {}

  @override
  Future<void> ensureAllScheduled(Iterable<TasbeehDhikr> dhikr) async {}

  @override
  Future<void> scheduleReminder(TasbeehDhikr dhikr) async {}
}

class SilentTasbeehTargetFeedbackService
    implements TasbeehTargetFeedbackService {
  @override
  Future<void> onTargetReached() async {}
}

TasbeehCubit buildTasbeehCubit(
  TasbeehRepository repository, {
  TasbeehLayoutPreferenceRepository? layoutRepository,
  TasbeehReminderScheduler? reminderScheduler,
  TasbeehTargetFeedbackService? feedbackService,
}) {
  final TasbeehLayoutPreferenceRepository layout =
      layoutRepository ?? FakeTasbeehLayoutPreferenceRepository();

  return TasbeehCubit(
    GetSavedTasbeehUseCase(repository),
    SaveCustomTasbeehUseCase(repository),
    IncrementTasbeehCountUseCase(repository),
    ResetTasbeehCountUseCase(repository),
    SetTasbeehTargetCountUseCase(repository),
    DeleteTasbeehDhikrUseCase(repository),
    ClearAllSavedTasbeehUseCase(repository),
    GetTasbeehLayoutModeUseCase(layout),
    SetTasbeehLayoutModeUseCase(layout),
    SetTasbeehReminderUseCase(repository),
    reminderScheduler ?? NoOpTasbeehReminderScheduler(),
    feedbackService ?? SilentTasbeehTargetFeedbackService(),
  );
}
