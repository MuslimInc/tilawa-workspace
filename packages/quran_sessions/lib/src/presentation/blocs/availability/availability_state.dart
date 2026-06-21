import 'package:equatable/equatable.dart';

import '../../../domain/entities/availability_override.dart';
import '../../../domain/entities/weekly_schedule.dart';
import '../../../domain/failures/quran_sessions_failure.dart';

enum AvailabilityStatus { loading, ready, error }

/// State for the weekly availability editor.
///
/// [baseline] is the last-persisted schedule; [draft] is the working copy the
/// teacher edits. [isDirty] compares the two so the screen can surface unsaved
/// changes (explicit-save model — nothing persists until [AvailabilityCubit.save]).
class AvailabilityState extends Equatable {
  const AvailabilityState({
    required this.status,
    required this.teacherId,
    required this.baseline,
    required this.draft,
    this.overrides = const [],
    this.useSameHoursForAllDays = false,
    this.isSaving = false,
    this.failure,
    this.saveTick = 0,
  });

  factory AvailabilityState.loading(String teacherId) => AvailabilityState(
    status: AvailabilityStatus.loading,
    teacherId: teacherId,
    baseline: WeeklySchedule.empty(teacherId: teacherId, timezone: 'UTC'),
    draft: WeeklySchedule.empty(teacherId: teacherId, timezone: 'UTC'),
  );

  final AvailabilityStatus status;
  final String teacherId;
  final WeeklySchedule baseline;
  final WeeklySchedule draft;
  final List<AvailabilityOverride> overrides;
  final bool useSameHoursForAllDays;
  final bool isSaving;

  /// Set when a load or save fails; the screen shows it then it is cleared.
  final QuranSessionsFailure? failure;

  /// Increments on each successful save so the screen can fire a success toast.
  final int saveTick;

  /// True when [draft] differs from [baseline] — there are unsaved edits.
  bool get isDirty => draft != baseline;

  AvailabilityState copyWith({
    AvailabilityStatus? status,
    String? teacherId,
    WeeklySchedule? baseline,
    WeeklySchedule? draft,
    List<AvailabilityOverride>? overrides,
    bool? useSameHoursForAllDays,
    bool? isSaving,
    QuranSessionsFailure? failure,
    bool clearFailure = false,
    int? saveTick,
  }) => AvailabilityState(
    status: status ?? this.status,
    teacherId: teacherId ?? this.teacherId,
    baseline: baseline ?? this.baseline,
    draft: draft ?? this.draft,
    overrides: overrides ?? this.overrides,
    useSameHoursForAllDays:
        useSameHoursForAllDays ?? this.useSameHoursForAllDays,
    isSaving: isSaving ?? this.isSaving,
    failure: clearFailure ? null : (failure ?? this.failure),
    saveTick: saveTick ?? this.saveTick,
  );

  @override
  List<Object?> get props => [
    status,
    teacherId,
    baseline,
    draft,
    overrides,
    useSameHoursForAllDays,
    isSaving,
    failure,
    saveTick,
  ];
}
