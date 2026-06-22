import 'package:equatable/equatable.dart';

import '../../../domain/entities/availability_override.dart';
import '../../../domain/entities/time_range.dart';
import '../../../domain/entities/weekday.dart';
import '../../../domain/entities/weekly_schedule.dart';
import '../../../domain/failures/quran_sessions_failure.dart';
import '../../../domain/services/weekly_schedule_validator.dart';

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
    this.isOverridesBusy = false,
    this.failure,
    this.saveTick = 0,
    this.overrideAddTick = 0,
    this.overrideRemoveTick = 0,
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

  /// True while an override add/remove request is in flight.
  final bool isOverridesBusy;

  /// Set when a load or save fails; the screen shows it then it is cleared.
  final QuranSessionsFailure? failure;

  /// Increments on each successful save so the screen can fire a success toast.
  final int saveTick;

  /// Increments on each successful override add for a success toast.
  final int overrideAddTick;

  /// Increments on each successful override removal for a success toast.
  final int overrideRemoveTick;

  /// True when [draft] differs from [baseline] — there are unsaved edits.
  bool get isDirty => draft != baseline;

  /// Open weekdays derived from [draft] rules — single source of truth for chips.
  Set<Weekday> get selectedWeekdays => draft.openDays.toSet();

  /// Per-weekday intervals in [draft]; empty list means closed.
  Map<Weekday, List<TimeRange>> get availabilitySlots => {
    for (final day in Weekday.values) day: draft.rangesFor(day),
  };

  /// Whether [draft] passes domain validation and can be persisted.
  bool get isDraftValid =>
      const WeeklyScheduleValidator().validate(draft) == null;

  /// Whether the save action is enabled in the hours tab footer.
  bool get saveEnabled => !isSaving && isDirty && isDraftValid;

  AvailabilityState copyWith({
    AvailabilityStatus? status,
    String? teacherId,
    WeeklySchedule? baseline,
    WeeklySchedule? draft,
    List<AvailabilityOverride>? overrides,
    bool? useSameHoursForAllDays,
    bool? isSaving,
    bool? isOverridesBusy,
    QuranSessionsFailure? failure,
    bool clearFailure = false,
    int? saveTick,
    int? overrideAddTick,
    int? overrideRemoveTick,
  }) => AvailabilityState(
    status: status ?? this.status,
    teacherId: teacherId ?? this.teacherId,
    baseline: baseline ?? this.baseline,
    draft: draft ?? this.draft,
    overrides: overrides ?? this.overrides,
    useSameHoursForAllDays:
        useSameHoursForAllDays ?? this.useSameHoursForAllDays,
    isSaving: isSaving ?? this.isSaving,
    isOverridesBusy: isOverridesBusy ?? this.isOverridesBusy,
    failure: clearFailure ? null : (failure ?? this.failure),
    saveTick: saveTick ?? this.saveTick,
    overrideAddTick: overrideAddTick ?? this.overrideAddTick,
    overrideRemoveTick: overrideRemoveTick ?? this.overrideRemoveTick,
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
    isOverridesBusy,
    failure,
    saveTick,
    overrideAddTick,
    overrideRemoveTick,
  ];
}
