import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:quran_sessions/core/l10n_extensions.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../domain/entities/local_time.dart';
import '../../domain/entities/time_range.dart';

enum _Editing { start, end }

/// Opens the Calendly-style time-range editor and returns the chosen
/// [TimeRange], or `null` if dismissed. [existing] ranges (excluding the one
/// being edited) are used to flag overlaps.
Future<TimeRange?> showTimeRangeEditorSheet(
  BuildContext context, {
  TimeRange? initial,
  List<TimeRange> existing = const [],
}) {
  return showTilawaModalBottomSheet<TimeRange>(
    context: context,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: TilawaBottomSheetScaffold.modalShape(context),
    builder: (_) =>
        _TimeRangeEditorSheet(initial: initial, existing: existing),
  );
}

class _TimeRangeEditorSheet extends StatefulWidget {
  const _TimeRangeEditorSheet({required this.initial, required this.existing});

  final TimeRange? initial;
  final List<TimeRange> existing;

  @override
  State<_TimeRangeEditorSheet> createState() => _TimeRangeEditorSheetState();
}

class _TimeRangeEditorSheetState extends State<_TimeRangeEditorSheet> {
  late LocalTime _start = widget.initial?.start ?? const LocalTime(9, 0);
  late LocalTime _end = widget.initial?.end ?? const LocalTime(17, 0);
  _Editing _editing = _Editing.start;

  TimeRange get _range => TimeRange(start: _start, end: _end);
  LocalTime get _active => _editing == _Editing.start ? _start : _end;

  String? _error(BuildContext context) {
    final l10n = context.quranSessionsL10n;
    if (!_range.isValid) return l10n.availabilityRangeInvalid;
    if (widget.existing.any(_range.overlaps)) {
      return l10n.availabilityRangeOverlap;
    }
    return null;
  }

  /// CupertinoDatePicker requires the initial minute to be a multiple of the
  /// 15-minute interval — snap defensively.
  DateTime _activeDateTime() =>
      DateTime(2020, 1, 1, _active.hour, (_active.minute ~/ 15) * 15);

  void _onChanged(DateTime value) {
    final time = LocalTime(value.hour, value.minute);
    setState(() {
      if (_editing == _Editing.start) {
        _start = time;
      } else {
        _end = time;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.quranSessionsL10n;
    final tokens = Theme.of(context).tokens;
    final scheme = Theme.of(context).colorScheme;
    final error = _error(context);
    final use24 = MediaQuery.of(context).alwaysUse24HourFormat;
    final bodyPadding = TilawaBottomSheetScaffold.resolvedBodyPadding(context);

    return TilawaBottomSheetScaffold(
      topBar: TilawaBottomSheetTitleRow(title: l10n.availabilityEditRange),
      footer: TilawaButton(
        text: l10n.availabilityUseTheseTimes,
        isFullWidth: true,
        onPressed: error == null
            ? () => Navigator.of(context).pop(_range)
            : null,
      ),
      children: [
        Padding(
          padding: bodyPadding,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: _TimeTab(
                      label: l10n.availabilityStartTime,
                      value: _formatLocalTime(context, _start),
                      selected: _editing == _Editing.start,
                      onTap: () => setState(() => _editing = _Editing.start),
                    ),
                  ),
                  SizedBox(width: tokens.spaceSmall),
                  Expanded(
                    child: _TimeTab(
                      label: l10n.availabilityEndTime,
                      value: _formatLocalTime(context, _end),
                      selected: _editing == _Editing.end,
                      onTap: () => setState(() => _editing = _Editing.end),
                    ),
                  ),
                ],
              ),
              if (error != null) ...[
                SizedBox(height: tokens.spaceSmall),
                Text(
                  error,
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: scheme.error),
                ),
              ],
            ],
          ),
        ),
        SizedBox(height: tokens.spaceSmall),
        SizedBox(
          height: 200,
          // Force LTR so the wheel reads hour : minute : ص/م regardless of the
          // app's RTL direction (the ص/م labels are still localized).
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: CupertinoDatePicker(
              key: ValueKey(_editing),
              mode: CupertinoDatePickerMode.time,
              use24hFormat: use24,
              minuteInterval: 15,
              backgroundColor: scheme.surface,
              initialDateTime: _activeDateTime(),
              onDateTimeChanged: _onChanged,
            ),
          ),
        ),
      ],
    );
  }
}

String _formatLocalTime(BuildContext context, LocalTime time) {
  final material = MaterialLocalizations.of(context);
  return material.formatTimeOfDay(
    TimeOfDay(hour: time.hour % 24, minute: time.minute),
    alwaysUse24HourFormat: MediaQuery.of(context).alwaysUse24HourFormat,
  );
}

/// A Start/End selector tab (Calendly-style): the active one is raised with a
/// primary outline; tapping it routes the wheel below to that time.
class _TimeTab extends StatelessWidget {
  const _TimeTab({
    required this.label,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String value;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).tokens;
    final scheme = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(tokens.radiusLarge);

    return InkWell(
      onTap: onTap,
      borderRadius: radius,
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: tokens.spaceMedium,
          horizontal: tokens.spaceMedium,
        ),
        decoration: BoxDecoration(
          color: selected ? scheme.surface : scheme.surfaceContainerHighest,
          borderRadius: radius,
          border: Border.all(
            color: selected ? scheme.primary : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
            SizedBox(height: tokens.spaceTiny),
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: selected ? scheme.primary : scheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
