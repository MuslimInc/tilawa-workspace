import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/availability_override.dart';
import '../../../domain/entities/local_time.dart';
import '../../../domain/entities/slot_duration.dart';
import '../../../domain/entities/time_range.dart';
import '../../../domain/entities/weekday.dart';
import '../../../domain/entities/weekly_schedule.dart';
import '../../../domain/repositories/schedule_repository.dart';
import 'availability_state.dart';

/// Drives the weekly availability editor. Edits mutate an in-memory [draft];
/// nothing persists until [save] (explicit-save model). Overrides are a
/// separate, immediately-persisted concern.
class AvailabilityCubit extends Cubit<AvailabilityState> {
  AvailabilityCubit({
    required ScheduleRepository repository,
    this.defaultTimezone = 'Africa/Cairo',
  }) : _repo = repository,
       super(AvailabilityState.loading(''));

  final ScheduleRepository _repo;

  /// IANA zone used as the default when a teacher has no saved schedule yet.
  final String defaultTimezone;

  /// Default hours applied when a closed day is switched on.
  static const _defaultRange = TimeRange(
    start: LocalTime(9, 0),
    end: LocalTime(17, 0),
  );

  Future<void> load(String teacherId) async {
    emit(AvailabilityState.loading(teacherId));

    final scheduleResult = await _repo.getSchedule(teacherId);
    final overridesResult = await _repo.getOverrides(teacherId);

    await scheduleResult.fold(
      (failure) async => emit(
        state.copyWith(status: AvailabilityStatus.error, failure: failure),
      ),
      (schedule) async {
        final baseline =
            schedule ??
            WeeklySchedule.empty(
              teacherId: teacherId,
              timezone: defaultTimezone,
            );
        final overrides = overridesResult.fold(
          (_) => <AvailabilityOverride>[],
          (value) => value,
        );
        emit(
          AvailabilityState(
            status: AvailabilityStatus.ready,
            teacherId: teacherId,
            baseline: baseline,
            draft: baseline,
            overrides: overrides,
            useSameHoursForAllDays: _looksUniform(baseline),
          ),
        );
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
    if (state.isSaving) return;
    emit(state.copyWith(isSaving: true, clearFailure: true));

    final toSave = state.draft.copyWith(
      version: state.baseline.version + 1,
      updatedAt: DateTime.now(),
    );
    final result = await _repo.saveSchedule(toSave);

    result.fold(
      (failure) => emit(state.copyWith(isSaving: false, failure: failure)),
      (_) => emit(
        state.copyWith(
          isSaving: false,
          baseline: toSave,
          draft: toSave,
          saveTick: state.saveTick + 1,
          clearFailure: true,
        ),
      ),
    );
  }

  /// Discards unsaved edits, reverting the draft to the saved baseline.
  void discardChanges() {
    emit(
      state.copyWith(
        draft: state.baseline,
        useSameHoursForAllDays: _looksUniform(state.baseline),
      ),
    );
  }

  // ── Overrides (persist immediately) ────────────────────────────────────────

  Future<void> addOverride(AvailabilityOverride override) async {
    final result = await _repo.saveOverride(state.teacherId, override);
    result.fold(
      (failure) => emit(state.copyWith(failure: failure)),
      (_) {
        final next = [
          ...state.overrides.where((o) => o.dateKey != override.dateKey),
          override,
        ]..sort((a, b) => a.date.compareTo(b.date));
        emit(state.copyWith(overrides: next, clearFailure: true));
      },
    );
  }

  Future<void> removeOverride(String dateKey) async {
    final result = await _repo.removeOverride(state.teacherId, dateKey);
    result.fold(
      (failure) => emit(state.copyWith(failure: failure)),
      (_) => emit(
        state.copyWith(
          overrides: state.overrides
              .where((o) => o.dateKey != dateKey)
              .toList(),
          clearFailure: true,
        ),
      ),
    );
  }

  // ── Internals ──────────────────────────────────────────────────────────────

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

  void _emitDraft(WeeklySchedule next) => emit(state.copyWith(draft: next));

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
