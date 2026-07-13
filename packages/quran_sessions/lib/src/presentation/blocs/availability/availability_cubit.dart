import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/availability_override.dart';
import '../../../domain/entities/local_time.dart';
import '../../../domain/entities/slot_duration.dart';
import '../../../domain/entities/time_range.dart';
import '../../../domain/entities/weekday.dart';
import '../../../domain/entities/weekly_schedule.dart';
import '../../../domain/failures/quran_sessions_failure.dart';
import '../../../domain/services/vacation_override_validator.dart';
import '../../../domain/usecases/get_availability_overrides_usecase.dart';
import '../../../domain/usecases/get_weekly_schedule_usecase.dart';
import '../../../domain/usecases/remove_availability_override_usecase.dart';
import '../../../domain/usecases/save_availability_override_usecase.dart';
import '../../../domain/usecases/save_weekly_schedule_usecase.dart';
import 'availability_state.dart';

/// Drives the weekly availability editor. Edits mutate an in-memory [draft];
/// nothing persists until [save] (explicit-save model). Overrides are a
/// separate, immediately-persisted concern.
class AvailabilityCubit extends Cubit<AvailabilityState> {
  AvailabilityCubit({
    required this._getSchedule,
    required this._saveSchedule,
    required this._getOverrides,
    required this._saveOverride,
    required this._removeOverride,
    this._defaultTimezone = 'Africa/Cairo',
    this._vacationValidator = const VacationOverrideValidator(),
  }) : super(AvailabilityState.loading(''));

  final GetWeeklyScheduleUseCase _getSchedule;
  final SaveWeeklyScheduleUseCase _saveSchedule;
  final GetAvailabilityOverridesUseCase _getOverrides;
  final SaveAvailabilityOverrideUseCase _saveOverride;
  final RemoveAvailabilityOverrideUseCase _removeOverride;
  final String _defaultTimezone;
  final VacationOverrideValidator _vacationValidator;
  int _loadGeneration = 0;

  /// Default hours applied when a closed day is switched on.
  static const _defaultRange = TimeRange(
    start: LocalTime(9, 0),
    end: LocalTime(17, 0),
  );

  Future<void> load(String teacherId) async {
    final generation = ++_loadGeneration;
    emit(AvailabilityState.loading(teacherId));

    final scheduleResult = await _getSchedule(
      teacherId,
      defaultTimezone: _defaultTimezone,
    );
    final overridesResult = await _getOverrides(teacherId);

    if (generation != _loadGeneration) {
      return;
    }

    await scheduleResult.fold(
      (failure) async {
        if (generation != _loadGeneration) return;
        emit(
          state.copyWith(status: AvailabilityStatus.error, failure: failure),
        );
      },
      (baseline) async {
        if (generation != _loadGeneration) return;
        final overrides = overridesResult.fold(
          (_) => <AvailabilityOverride>[],
          (value) => value,
        );
        final persisted = baseline.detached();
        final ready = AvailabilityState(
          status: AvailabilityStatus.ready,
          teacherId: teacherId,
          baseline: persisted,
          draft: persisted.detached(),
          overrides: overrides,
          useSameHoursForAllDays: _looksUniform(persisted),
        );
        emit(ready);
      },
    );
  }

  // ── Day & range editing (mutate the draft) ─────────────────────────────────

  void toggleDay(Weekday day, bool enabled) {
    final next = enabled
        ? state.draft.withDay(day, _rangesForNewlyOpenDay())
        : state.draft.withDay(day, const []);
    _emitDraft(next);
  }

  void addRange(Weekday day, TimeRange range) {
    final updated = [...state.draft.rangesFor(day), range];
    _setDayRanges(day, updated);
  }

  void updateRange(Weekday day, int index, TimeRange range) {
    final ranges = [...state.draft.rangesFor(day)];
    if (index < 0 || index >= ranges.length) return;
    ranges[index] = range;
    _setDayRanges(day, ranges);
  }

  void removeRange(Weekday day, int index) {
    final ranges = [...state.draft.rangesFor(day)]..removeAt(index);
    _setDayRanges(day, ranges);
  }

  void setDuration(SlotDuration duration) {
    _emitDraft(state.draft.copyWith(slotDuration: duration));
  }

  void setTimezone(String timezone) {
    _emitDraft(state.draft.copyWith(timezone: timezone));
  }

  /// When enabled, every open day shares one set of hours; editing any day
  /// applies to all. When disabled, days are edited independently.
  void setUseSameHoursForAllDays(bool value) {
    if (value) {
      final unified = _unifiedRanges();
      var next = state.draft;
      for (final day in Weekday.values) {
        if (next.isOpenOn(day)) next = next.withDay(day, unified);
      }
      emit(state.copyWith(draft: next, useSameHoursForAllDays: true));
    } else {
      emit(state.copyWith(useSameHoursForAllDays: false));
    }
  }

  // ── Persistence ────────────────────────────────────────────────────────────

  Future<void> save() async {
    if (state.isSaving || !state.isDirty || !state.isDraftValid) return;
    emit(state.copyWith(isSaving: true, clearFailure: true));

    final normalizedDraft = state.draft.detached();
    final result = await _saveSchedule(
      draft: normalizedDraft,
      baseline: state.baseline,
    );

    result.fold(
      (failure) {
        emit(state.copyWith(isSaving: false, failure: failure));
      },
      (synced) {
        final persisted = synced.detached();
        final saved = state.copyWith(
          isSaving: false,
          baseline: persisted,
          draft: persisted.detached(),
          useSameHoursForAllDays: _looksUniform(persisted),
          saveTick: state.saveTick + 1,
          clearFailure: true,
        );
        emit(saved);
      },
    );
  }

  /// Discards unsaved edits, reverting the draft to the saved baseline.
  void discardChanges() {
    final reverted = state.copyWith(
      draft: state.baseline.detached(),
      useSameHoursForAllDays: _looksUniform(state.baseline),
    );
    emit(reverted);
  }

  // ── Overrides (persist immediately) ────────────────────────────────────────

  Future<void> addOverride(AvailabilityOverride override) async {
    await addOverrides([override]);
  }

  Future<void> addOverrides(List<AvailabilityOverride> overrides) async {
    if (overrides.isEmpty || state.isOverridesBusy) return;

    final vacationConflict = _findVacationConflict(overrides);
    if (vacationConflict != null) {
      emit(state.copyWith(failure: vacationConflict));
      return;
    }

    emit(state.copyWith(isAddingOverride: true, clearFailure: true));

    for (final override in overrides) {
      final result = await _saveOverride(state.teacherId, override);
      final failure = result.fold((f) => f, (_) => null);
      if (failure != null) {
        emit(state.copyWith(isAddingOverride: false, failure: failure));
        return;
      }
    }

    final byKey = {for (final o in state.overrides) o.dateKey: o};
    for (final override in overrides) {
      byKey[override.dateKey] = override;
    }
    final next = byKey.values.toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    emit(
      state.copyWith(
        overrides: next,
        isAddingOverride: false,
        overrideAddTick: state.overrideAddTick + 1,
        clearFailure: true,
      ),
    );
  }

  Future<void> removeOverride(String dateKey) async {
    await removeOverrides([dateKey]);
  }

  Future<void> removeOverrides(Iterable<String> dateKeys) async {
    final keys = dateKeys.toList();
    if (keys.isEmpty || state.isOverridesBusy) return;

    emit(
      state.copyWith(
        removingOverrideDateKeys: keys.toSet(),
        clearFailure: true,
      ),
    );

    for (final dateKey in keys) {
      final result = await _removeOverride(state.teacherId, dateKey);
      final failure = result.fold((f) => f, (_) => null);
      if (failure != null) {
        emit(
          state.copyWith(
            clearRemovingOverrideDateKeys: true,
            failure: failure,
          ),
        );
        return;
      }
    }

    emit(
      state.copyWith(
        overrides: state.overrides
            .where((o) => !keys.contains(o.dateKey))
            .toList(),
        clearRemovingOverrideDateKeys: true,
        overrideRemoveTick: state.overrideRemoveTick + 1,
        clearFailure: true,
      ),
    );
  }

  // ── Internals ──────────────────────────────────────────────────────────────

  ValidationFailure? _findVacationConflict(
    List<AvailabilityOverride> proposed,
  ) {
    final vacations = proposed
        .where((override) => override.type == OverrideType.unavailable)
        .toList();
    if (vacations.isEmpty) return null;

    final dates = vacations.map((override) => override.date).toList()..sort();
    final overlap = _vacationValidator.findFirstOverlappingVacationDay(
      startDate: dates.first,
      endDate: dates.last,
      existingOverrides: state.overrides,
    );
    if (overlap == null) return null;

    return const ValidationFailure(
      field: VacationOverrideValidator.field,
      code: VacationOverrideValidator.overlapsExistingCode,
    );
  }

  void _setDayRanges(Weekday day, List<TimeRange> ranges) {
    if (state.useSameHoursForAllDays) {
      var next = state.draft;
      for (final d in Weekday.values) {
        if (next.isOpenOn(d) || d == day) next = next.withDay(d, ranges);
      }
      _emitDraft(next);
    } else {
      _emitDraft(state.draft.withDay(day, ranges));
    }
  }

  void _emitDraft(WeeklySchedule next) {
    emit(state.copyWith(draft: next));
  }

  List<TimeRange> _rangesForNewlyOpenDay() =>
      state.useSameHoursForAllDays ? _unifiedRanges() : const [_defaultRange];

  /// The hours shared across days in "same hours" mode: the first open day's
  /// ranges, or the default when none are open yet.
  List<TimeRange> _unifiedRanges() {
    for (final day in Weekday.values) {
      final ranges = state.draft.rangesFor(day);
      if (ranges.isNotEmpty) return ranges;
    }
    return const [_defaultRange];
  }

  /// Heuristic: do all open days already share identical hours? Used to pick
  /// the initial "same hours" toggle on load.
  bool _looksUniform(WeeklySchedule schedule) {
    final openDays = schedule.openDays.toList();
    if (openDays.length < 2) return false;
    final first = schedule.rangesFor(openDays.first);
    return openDays.every(
      (d) => _rangesEqual(schedule.rangesFor(d), first),
    );
  }

  bool _rangesEqual(List<TimeRange> a, List<TimeRange> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
