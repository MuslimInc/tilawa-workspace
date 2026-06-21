import 'package:flutter/material.dart';
import 'package:quran_sessions/core/l10n_extensions.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../domain/entities/local_time.dart';
import '../../domain/entities/time_range.dart';

/// Opens the Calendly-style time-range editor and returns the chosen
/// [TimeRange], or `null` if dismissed. [existing] ranges (excluding the one
/// being edited) are used to flag overlaps.
Future<TimeRange?> showTimeRangeEditorSheet(
  BuildContext context, {
  TimeRange? initial,
  List<TimeRange> existing = const [],
}) {
  final l10n = context.quranSessionsL10n;
  final initialStart = initial?.start ?? const LocalTime(9, 0);
  final initialEnd = initial?.end ?? const LocalTime(17, 0);

  return showTilawaDualCupertinoPickerSheet<LocalTime>(
    context: context,
    title: l10n.availabilityEditRange,
    start: TilawaPickerSegment(
      label: l10n.availabilityStartTime,
      value: initialStart,
    ),
    end: TilawaPickerSegment(
      label: l10n.availabilityEndTime,
      value: initialEnd,
    ),
    formatValue: _formatLocalTime,
    toDateTime: _localTimeToPickerDateTime,
    fromDateTime: _pickerDateTimeToLocalTime,
    primaryLabel: l10n.availabilityUseTheseTimes,
    canConfirm: (start, end) {
      final range = TimeRange(start: start, end: end);
      return range.isValid && !existing.any(range.overlaps);
    },
    errorText: (ctx, start, end) {
      final messages = ctx.quranSessionsL10n;
      final range = TimeRange(start: start, end: end);
      if (!range.isValid) return messages.availabilityRangeInvalid;
      if (existing.any(range.overlaps)) {
        return messages.availabilityRangeOverlap;
      }
      return null;
    },
    minuteInterval: 15,
  ).then(
    (result) =>
        result == null ? null : TimeRange(start: result.$1, end: result.$2),
  );
}

/// CupertinoDatePicker requires the initial minute to be a multiple of the
/// 15-minute interval — snap defensively.
DateTime _localTimeToPickerDateTime(LocalTime time) =>
    DateTime(2020, 1, 1, time.hour, (time.minute ~/ 15) * 15);

LocalTime _pickerDateTimeToLocalTime(DateTime value) =>
    LocalTime(value.hour, value.minute);

String _formatLocalTime(BuildContext context, LocalTime time) {
  final material = MaterialLocalizations.of(context);
  return material.formatTimeOfDay(
    TimeOfDay(hour: time.hour % 24, minute: time.minute),
    alwaysUse24HourFormat: MediaQuery.of(context).alwaysUse24HourFormat,
  );
}
